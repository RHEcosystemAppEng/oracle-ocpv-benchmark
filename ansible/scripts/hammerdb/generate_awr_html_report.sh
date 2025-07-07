#!/bin/bash

# === USAGE ===
# ./generate_awr_html_report.sh /path/to/hammerdb.log

# === CHECK ARGUMENT ===
#if [ -z "$1" ]; then
#  echo "❌ Usage: $0 /path/to/hammerdb.log"
#  exit 1
#fi

# Load environment variables only once from .env if it exists
source ./load-env.sh

LOG_FILE="hammerdb_run_2025-05-08T15:26:43.log"

# === CONFIGURATION ===
DB_USER="sys"
#DB_PASS=""
#DB_HOST="your_host"
#DB_PORT="1521"
#SERVICE_NAME="your_service_name"
OUTPUT_DIR="./awr_reports"
REPORT_NAME="awr_report_$(date +%Y%m%d%H%M%S).html"
PDB_NAME="PDB1"

# === EXTRACT SNAPSHOT IDS (works on both RHEL and macOS) ===
begin_snap=$(awk '/SNAPID/ {print $(NF-2)}' "$LOG_FILE" | head -n 1)
end_snap=$(awk '/SNAPID/ {print $NF}' "$LOG_FILE" | head -n 1)

if [[ -z "$begin_snap" || -z "$end_snap" ]]; then
  echo "❌ Failed to extract SNAPIDs from $LOG_FILE"
  exit 1
fi

echo "✅ Parsed snapshot range: $begin_snap to $end_snap"

mkdir -p "$OUTPUT_DIR"
# --- GET DBID AND CON_DBID ---
# --- GET DBID AND CON_DBID ---
dbid_conid=$(sqlplus -s "$DB_USER/${ORACLE_SYSTEM_PASSWORD}@${ORACLE_SID} as sysdba" <<EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET TRIMSPOOL ON
SELECT d.dbid || ' ' || p.con_id FROM v\\$database d JOIN v\\$pdbs p ON 1=1 WHERE p.name = UPPER('$PDB_NAME');
EXIT;
EOF
)

read -r dbid con_dbid <<< "$dbid_conid"

if [[ -z "$dbid" || -z "$con_dbid" ]]; then
  echo "❌ Failed to fetch DBID or CON_DBID for $PDB_NAME"
  exit 1
fi

echo "Using DBID: $dbid, CON_DBID: $con_dbid"

# --- GET INSTANCE NUMBERS ---
instance_list=$(sqlplus -s "$DB_USER/${ORACLE_SYSTEM_PASSWORD}@${ORACLE_SID} as sysdba" <<EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET TRIMSPOOL ON
SELECT DISTINCT instance_number FROM gv\\$active_instances ORDER BY 1;
EXIT;
EOF
)

# --- GENERATE REPORTS PER INSTANCE ---
for inst in $instance_list; do
  report_file="$OUTPUT_DIR/awr_${PDB_NAME,,}_inst${inst}_${begin_snap}_${end_snap}.html"
  echo "Generating AWR report for instance $inst -> $report_file"

  sqlplus -s "$DB_USER/${ORACLE_SYSTEM_PASSWORD}@${ORACLE_SID} as sysdba" <<EOF
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMOUT ON
SET TRIMSPOOL ON
SET ECHO OFF
SPOOL $report_file
SELECT output FROM TABLE(
  DBMS_WORKLOAD_REPOSITORY.AWR_PDB_REPORT_HTML(
    l_dbid     => $dbid,
    l_inst_num => $inst,
    l_bid      => $begin_snap,
    l_eid      => $end_snap,
    l_con_dbid => $con_dbid
  )
);
SPOOL OFF
EOF

done

echo "✅ All AWR PDB reports generated in $OUTPUT_DIR"

