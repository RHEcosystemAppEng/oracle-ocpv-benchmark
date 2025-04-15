#!/bin/bash
set -euo pipefail

# Load environment variables from .env if it exists
if [[ -f ".env" ]]; then
  set -a
  source .env
  set +a
fi

# Check required variables
: "${ORACLE_SYSTEM_PASSWORD:?Need to set ORACLE_SYSTEM_PASSWORD}"
: "${ORACLE_INSTANCE:?Need to set ORACLE_INSTANCE}"

# Connect to SQL*Plus and execute the drop statement
sqlplus -s "system/${ORACLE_SYSTEM_PASSWORD}@${ORACLE_INSTANCE}" <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DROP USER tpcc CASCADE;
EXIT;
EOF
