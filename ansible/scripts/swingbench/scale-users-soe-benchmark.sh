#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

echo "=========================================================="
echo "SwingBench SOE: Scaling User Count Benchmark"
echo "=========================================================="
echo "This script will run SOE benchmarks with user counts:"
echo "20, 40, 60, 80, and 100 users"
echo ""
echo "Each test includes:"
echo "- 1 minute ramp-up time (users connect and stabilize)"
echo "- $RUN_TIME minute(s) benchmark runtime"
echo "- 2 minute recovery period between tests"
echo ""
echo "Schema management:"
if [ "${DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK:-false}" = "true" ]; then
    echo "- Schema will be dropped and rebuilt (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true)"
    ESTIMATED_TIME=$(( (RUN_TIME + 3) * 5 + 5 ))  # (runtime + rampup + recovery) * 5 tests + schema build
else
    echo "- Using existing schema (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=false)"
    ESTIMATED_TIME=$(( (RUN_TIME + 3) * 5 ))  # (runtime + rampup + recovery) * 5 tests, no schema build
fi
echo ""
echo "Estimated total time: ~$ESTIMATED_TIME minutes"
echo "=========================================================="

# Define user count array
USER_COUNTS=(20 40 60 80 100)

# Store original values
ORIGINAL_USER_COUNT="$USER_COUNT"
ORIGINAL_BENCHMARK_NAME="scale-run-$BENCHMARK_NAME"

# Step 1: Conditionally build the schema
if [ "${DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK:-false}" = "true" ]; then
    echo "Step 1: Building SOE Schema (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true)..."
    ./build-soe-schema.sh
else
    echo "Step 1: Skipping SOE Schema build (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=false)..."
    echo "⚠️  Using existing SOE schema - ensure it exists and is properly configured"
    
    # Quick check if SOE user exists
    echo "Checking if SOE user exists..."
    echo "exit" | sqlplus -S "$SOE_USER/$SOE_PASSWORD@$ORACLE_SID" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Cannot connect as SOE user. Schema may not exist or credentials are wrong."
        echo "💡 Either create the SOE schema manually or set DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true"
        exit 1
    fi
    echo "✅ SOE user connection successful - proceeding with existing schema"
fi

echo ""
echo "Waiting 30 seconds before starting benchmark runs..."
sleep 30

# Step 2: Run benchmarks with different user counts
for user_count in "${USER_COUNTS[@]}"; do
    echo ""
    echo "=========================================================="
    echo "Running benchmark with $user_count users"
    echo "=========================================================="
    
    # Override environment variables for this run
    export USER_COUNT="$user_count"
    export BENCHMARK_NAME="scale_${user_count}users_$(date +%Y%m%d_%H%M%S)"
    
    echo "User Count: $USER_COUNT"
    echo "Run Time: $RUN_TIME minutes"
    echo "Scale Factor: $SCALE_FACTOR"
    echo "Benchmark Name: $BENCHMARK_NAME"
    echo "Expected Total Time: ~$((RUN_TIME + 1)) minutes (including ramp-up)"
    echo "=========================================================="
    
    # Run the benchmark
    ./run-soe-benchmark.sh
    
    echo ""
    echo "✅ Completed benchmark with $user_count users"
    echo "Waiting 2 minutes before next run (allow system recovery)..."
    sleep 120
done

# Restore original values
export USER_COUNT="$ORIGINAL_USER_COUNT"
export BENCHMARK_NAME="$ORIGINAL_BENCHMARK_NAME"

echo ""
echo "=========================================================="
echo "All scaling benchmarks completed!"
echo "=========================================================="
echo "Results are available in: $RESULTS_DIR"
echo ""
echo "Summary of runs:"
for user_count in "${USER_COUNTS[@]}"; do
    echo "- $user_count users: scale_${user_count}users_*.xml|csv|log"
done
echo "=========================================================="

# Display comprehensive summary if any result files exist
if ls "$RESULTS_DIR"/scale_*users_*.csv >/dev/null 2>&1; then
    echo ""
    echo "SCALING BENCHMARK RESULTS SUMMARY"
    echo "=========================================================="
    echo "Test Configuration:"
    echo "- Runtime per test: $RUN_TIME minutes"
    echo "- Ramp-up time: 1 minute per test" 
    echo "- Scale factor: $SCALE_FACTOR"
    echo "- Recovery time: 2 minutes between tests"
    echo "=========================================================="
    echo ""
    
    # Header for the table
    printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
           "Users" "TPS" "Avg Resp(ms)" "Errors" "Throughput" "Status"
    printf "%-10s-+-%-8s-+-%-12s-+-%-8s-+-%-10s-+-%-8s\n" \
           "----------" "--------" "------------" "--------" "----------" "--------"
    
    # Collect data for each user count
    declare -a results_summary=()
    for user_count in "${USER_COUNTS[@]}"; do
        latest_csv=$(ls -t "$RESULTS_DIR"/scale_${user_count}users_*.csv 2>/dev/null | head -1 || echo "")
        if [ -n "$latest_csv" ] && [ -f "$latest_csv" ]; then
            # Extract metrics from the last line of CSV (actual results)
            last_line=$(tail -1 "$latest_csv" 2>/dev/null)
            if [ -n "$last_line" ]; then
                # Parse CSV columns (adjust column numbers based on SwingBench CSV format)
                tps=$(echo "$last_line" | cut -d',' -f3 2>/dev/null | sed 's/[[:space:]]//g' || echo "N/A")
                avg_resp=$(echo "$last_line" | cut -d',' -f4 2>/dev/null | sed 's/[[:space:]]//g' || echo "N/A")
                errors=$(echo "$last_line" | cut -d',' -f5 2>/dev/null | sed 's/[[:space:]]//g' || echo "0")
                
                # Calculate throughput (approximate transactions per minute)
                if [[ "$tps" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                    # Try bc first, fall back to awk if bc not available
                    throughput=$(echo "$tps * 60" | bc 2>/dev/null || awk "BEGIN {printf \"%.0f\", $tps * 60}" 2>/dev/null || echo "${tps}×60")
                else
                    throughput="N/A"
                fi
                
                # Determine status based on errors
                if [[ "$errors" =~ ^[0-9]+$ ]] && [ "$errors" -eq 0 ]; then
                    status="✅ OK"
                elif [[ "$errors" =~ ^[0-9]+$ ]] && [ "$errors" -gt 0 ] && [ "$errors" -lt 10 ]; then
                    status="⚠️ WARN"
                else
                    status="❌ FAIL"
                fi
                
                printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                       "${user_count}" "$tps" "$avg_resp" "$errors" "$throughput" "$status"
                
                # Store for analysis
                results_summary+=("$user_count:$tps:$avg_resp:$errors")
            else
                printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                       "${user_count}" "N/A" "N/A" "N/A" "N/A" "❌ FAIL"
            fi
        else
            printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                   "${user_count}" "N/A" "N/A" "N/A" "N/A" "🔍 MISSING"
        fi
    done
    
    echo "=========================================================="
    echo ""
    
    # Performance Analysis
    echo "PERFORMANCE ANALYSIS"
    echo "=========================================================="
    
    # Find best performing configuration
    best_tps=0
    best_users=""
    total_tests=0
    successful_tests=0
    
    for result in "${results_summary[@]}"; do
        IFS=':' read -r users tps resp errors <<< "$result"
        total_tests=$((total_tests + 1))
        
        if [[ "$tps" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ "$errors" =~ ^[0-9]+$ ]]; then
            successful_tests=$((successful_tests + 1))
            # Compare TPS values (use awk if bc not available)
            is_better=$(echo "$tps > $best_tps" | bc -l 2>/dev/null || awk "BEGIN {print ($tps > $best_tps) ? 1 : 0}" 2>/dev/null || echo 0)
            if [ "$is_better" = "1" ]; then
                best_tps="$tps"
                best_users="$users"
            fi
        fi
    done
    
    echo "✅ Tests completed: $successful_tests/$total_tests"
    if [ -n "$best_users" ] && [ "$best_tps" != "0" ]; then
        echo "🏆 Best performance: $best_tps TPS with $best_users users"
    fi
    
    echo ""
    echo "DETAILED RESULTS LOCATION"
    echo "=========================================================="
    echo "📁 All results saved to: $RESULTS_DIR"
    echo ""
    echo "📊 CSV files:"
    for user_count in "${USER_COUNTS[@]}"; do
        latest_csv=$(ls -t "$RESULTS_DIR"/scale_${user_count}users_*.csv 2>/dev/null | head -1 || echo "")
        if [ -n "$latest_csv" ]; then
            echo "   ${user_count} users: $(basename "$latest_csv")"
        fi
    done
    
    echo ""
    echo "📈 For detailed analysis, examine individual CSV/XML files"
    echo "🔍 Use: tail -5 \$RESULTS_DIR/scale_*users_*.csv"
    echo "=========================================================="
    
    # Generate shareable summary report
    REPORT_FILE="$RESULTS_DIR/scaling_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    echo ""
    echo "📋 GENERATING SHAREABLE REPORT"
    echo "=========================================================="
    
    {
        echo "SwingBench SOE Scaling Benchmark Results"
        echo "========================================"
        echo "Generated: $(date)"
        echo "Test Configuration:"
        echo "- Runtime per test: $RUN_TIME minutes"
        echo "- Ramp-up time: 1 minute per test"
        echo "- Scale factor: $SCALE_FACTOR"
        echo "- Recovery time: 2 minutes between tests"
        echo ""
        
        echo "Results Summary:"
        printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
               "Users" "TPS" "Avg Resp(ms)" "Errors" "TPM" "Status"
        printf "%-10s-+-%-8s-+-%-12s-+-%-8s-+-%-10s-+-%-8s\n" \
               "----------" "--------" "------------" "--------" "----------" "--------"
        
        for user_count in "${USER_COUNTS[@]}"; do
            latest_csv=$(ls -t "$RESULTS_DIR"/scale_${user_count}users_*.csv 2>/dev/null | head -1 || echo "")
            if [ -n "$latest_csv" ] && [ -f "$latest_csv" ]; then
                last_line=$(tail -1 "$latest_csv" 2>/dev/null)
                if [ -n "$last_line" ]; then
                    tps=$(echo "$last_line" | cut -d',' -f3 2>/dev/null | sed 's/[[:space:]]//g' || echo "N/A")
                    avg_resp=$(echo "$last_line" | cut -d',' -f4 2>/dev/null | sed 's/[[:space:]]//g' || echo "N/A")
                    errors=$(echo "$last_line" | cut -d',' -f5 2>/dev/null | sed 's/[[:space:]]//g' || echo "0")
                    
                    if [[ "$tps" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                        throughput=$(echo "$tps * 60" | bc 2>/dev/null || awk "BEGIN {printf \"%.0f\", $tps * 60}" 2>/dev/null || echo "${tps}×60")
                    else
                        throughput="N/A"
                    fi
                    
                    if [[ "$errors" =~ ^[0-9]+$ ]] && [ "$errors" -eq 0 ]; then
                        status="OK"
                    elif [[ "$errors" =~ ^[0-9]+$ ]] && [ "$errors" -gt 0 ] && [ "$errors" -lt 10 ]; then
                        status="WARN"
                    else
                        status="FAIL"
                    fi
                    
                    printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                           "${user_count}" "$tps" "$avg_resp" "$errors" "$throughput" "$status"
                else
                    printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                           "${user_count}" "N/A" "N/A" "N/A" "N/A" "FAIL"
                fi
            else
                printf "%-10s | %-8s | %-12s | %-8s | %-10s | %-8s\n" \
                       "${user_count}" "N/A" "N/A" "N/A" "N/A" "MISSING"
            fi
        done
        
        echo ""
        echo "Analysis:"
        echo "- Tests completed: $successful_tests/$total_tests"
        if [ -n "$best_users" ] && [ "$best_tps" != "0" ]; then
            echo "- Best performance: $best_tps TPS with $best_users users"
        fi
        echo ""
        echo "Results Location: $RESULTS_DIR"
        echo "Report Generated: $(date)"
        
    } > "$REPORT_FILE"
    
    echo "📝 Shareable report saved to: $REPORT_FILE"
    echo "💾 Copy and paste the following for sharing:"
    echo ""
    echo "--- COPY FROM HERE ---"
    cat "$REPORT_FILE"
    echo "--- COPY TO HERE ---"
    echo ""
    
else
    echo ""
    echo "⚠️  No CSV result files found in $RESULTS_DIR"
    echo "📁 Check individual log files for detailed information"
    echo "=========================================================="
fi 