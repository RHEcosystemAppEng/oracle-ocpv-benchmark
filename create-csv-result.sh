#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Make sure we have at least one run log
if ! compgen -G "results/hammerdb_run_*.log" > /dev/null; then
  echo "No run logs found yet" >&2
  exit 1
fi

# Output into csv file
OUTPUT="results/summary.csv"
echo "timestamp,minutes_build,nopm" | tee "$OUTPUT"

# read all logs
for run_file in results/hammerdb_run_*.log; do
  NAME=${run_file#results/hammerdb_run_}
  NAME=${NAME%.log}

  MINUTESBUILD_FILE="results/hammerdb_minutesbuild_$NAME.log"
  NOPM_FILE="results/hammerdb_nopm_$NAME.log"

  # getting values
  if [[ -f "$MINUTESBUILD_FILE" ]]; then
    MINUTESBUILD=$(< "$MINUTESBUILD_FILE" tr -d '\n')
  else
    MINUTESBUILD=""
  fi

  if [[ -f "$NOPM_FILE" ]]; then
    NOPM=$(< "$NOPM_FILE" tr -d '\n')
  else
    echo "Skipping $NAME — NOPM file missing" >&2
    continue
  fi

  # putting into csv
  echo "$NAME,$MINUTESBUILD,$NOPM" | tee -a "$OUTPUT"
done

echo "check the results into  $OUTPUT"
