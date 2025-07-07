#!/bin/bash
set -euo pipefail

# Source environment variables
source .env

echo "=================================================="
echo "SwingBench SOE Benchmark Starting"
echo "=================================================="
echo "User Count: $USER_COUNT"
echo "Run Time: $RUN_TIME minutes"
echo "Scale Factor: $SCALE_FACTOR"
echo "=================================================="

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Log and result files for this run
RUN_LOG="$RESULTS_DIR/soe_benchmark_run_${BENCHMARK_NAME}.log"
RESULT_XML="$RESULTS_DIR/soe_results_${BENCHMARK_NAME}.xml"
RESULT_CSV="$RESULTS_DIR/soe_results_${BENCHMARK_NAME}.csv"

echo "Run log: $RUN_LOG"
echo "Results XML: $RESULT_XML"
echo "Results CSV: $RESULT_CSV"
echo "Starting SOE benchmark at $(date)" | tee "$RUN_LOG"

cd "$SWINGBENCH_HOME/bin"

# Test database connection first
echo "Testing database connection..." | tee -a "$RUN_LOG"
echo "exit" | sqlplus -S "$SOE_USER/$SOE_PASSWORD@$ORACLE_SID" 2>&1 | tee -a "$RUN_LOG"
if [ $? -ne 0 ]; then
    echo "❌ Database connection failed. Check your credentials and TNS configuration." | tee -a "$RUN_LOG"
    exit 1
fi

# Run the SOE benchmark using charbench
echo "Running SOE benchmark..." | tee -a "$RUN_LOG"
echo "Command: ./charbench -c $SWINGBENCH_HOME/configs/SOE_Server_Side_V2.xml -u $SOE_USER -p *** -cs $ORACLE_SID -uc $USER_COUNT -rt ${RUN_TIME}:00.00 -v trans,tpm,tps,users,resp -r $RESULT_XML -csv $RESULT_CSV -a" | tee -a "$RUN_LOG"

./charbench \
  -c "$SWINGBENCH_HOME/configs/SOE_Server_Side_V2.xml" \
  -u "$SOE_USER" \
  -p "$SOE_PASSWORD" \
  -cs "$ORACLE_SID" \
  -uc "$USER_COUNT" \
  -rt "${RUN_TIME}:00.00" \
  -v trans,tpm,tps,users,resp \
  -r "$RESULT_XML" \
  -csv "$RESULT_CSV" \
  -a 2>&1 | tee -a "$RUN_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ SOE benchmark completed successfully at $(date)" | tee -a "$RUN_LOG"
    
    # Display summary from CSV if available
    if [ -f "$RESULT_CSV" ]; then
        echo "=================================================="
        echo "Benchmark Summary:"
        echo "=================================================="
        tail -n 5 "$RESULT_CSV" | column -t -s ','
    fi
else
    echo "❌ SOE benchmark failed at $(date)" | tee -a "$RUN_LOG"
    exit 1
fi

echo "=================================================="
echo "Benchmark completed. Results available at:"
echo "- Log: $RUN_LOG"
echo "- XML: $RESULT_XML"
echo "- CSV: $RESULT_CSV"
echo "==================================================" 