#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

echo "=================================================="
echo "SwingBench SOE Schema Build Starting"
echo "=================================================="
echo "Scale Factor: $SCALE_FACTOR"
echo "TNS Admin: $TNS_ADMIN"
echo "Oracle SID: $ORACLE_SID"
echo "SOE User: $SOE_USER"
echo "SwingBench Home: $SWINGBENCH_HOME"
echo "Script Directory: $SCRIPT_DIR"
echo "=================================================="

# Verify critical environment variables
if [ -z "$ORACLE_SYS_PASSWORD" ]; then
    echo "❌ ERROR: ORACLE_SYS_PASSWORD is not set!"
    exit 1
fi

if [ -z "$SOE_USER" ]; then
    echo "❌ ERROR: SOE_USER is not set!"
    exit 1
fi

if [ -z "$SOE_PASSWORD" ]; then
    echo "❌ ERROR: SOE_PASSWORD is not set!"
    exit 1
fi

# Test SYS connection before proceeding (same as working script)
echo "Testing SYS connection..."
echo "exit" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Cannot connect as SYS. Please check ORACLE_SYS_PASSWORD and TNS configuration."
    exit 1
fi
echo "✅ SYS connection successful"

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Log file for this build
BUILD_LOG="$RESULTS_DIR/soe_schema_build_${BENCHMARK_NAME}.log"

# Define the test results file path
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_RESULTS_XML="$RESULTS_DIR/soe_schema_test_${TIMESTAMP}.xml"

echo "Build log: $BUILD_LOG"
echo "Starting SOE schema build at $(date)" | tee "$BUILD_LOG"

# Go to SwingBench bin directory (same as working script)
cd "$SWINGBENCH_HOME/bin"

echo "Building SOE schema using the same approach as working simple test..." | tee -a "$BUILD_LOG"

# Step 1: Check if SOE user already exists (same as working script)
echo "Checking if SOE user already exists..." | tee -a "$BUILD_LOG"
echo "SELECT username FROM dba_users WHERE username = 'SOE';" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"

# Step 2: Check SOE user status (same as working script)
echo "Checking SOE user status (locked/unlocked)..." | tee -a "$BUILD_LOG"
echo "SELECT username, account_status, lock_date FROM dba_users WHERE username = 'SOE';" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"

# Step 3: Drop existing SOE schema if it exists (clean slate)
echo "Dropping existing SOE schema if it exists..." | tee -a "$BUILD_LOG"
echo "DROP USER soe CASCADE;" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba" 2>/dev/null || echo "SOE user did not exist or could not be dropped"

# Step 4: Run oewizard with command line parameters only (no config file)
echo "Running oewizard with command line parameters only..." | tee -a "$BUILD_LOG"
echo "Using command line parameters (following working script pattern):" | tee -a "$BUILD_LOG"
echo "  DBA: sys as sysdba" | tee -a "$BUILD_LOG"
echo "  Connection: $ORACLE_SID" | tee -a "$BUILD_LOG"
echo "  Target User: $SOE_USER" | tee -a "$BUILD_LOG"
echo "  Scale Factor: $SCALE_FACTOR" | tee -a "$BUILD_LOG"

# Run oewizard with command line parameters only
echo "Running oewizard (no config file)..." | tee -a "$BUILD_LOG"
echo "Full oewizard command:" | tee -a "$BUILD_LOG"
echo "./oewizard -dba \"sys as sysdba\" -dbap \"***\" -u \"soe\" -p \"soe\" -cs \"$ORACLE_SID\" -dt thin -create -scale \"$SCALE_FACTOR\" -cl" | tee -a "$BUILD_LOG"

./oewizard \
  -dba "sys as sysdba" \
  -dbap "$ORACLE_SYS_PASSWORD" \
  -u "soe" \
  -p "soe" \
  -cs "$ORACLE_SID" \
  -dt thin \
  -create \
  -scale "$SCALE_FACTOR" \
  -cl 2>&1 | tee -a "$BUILD_LOG"

OEWIZARD_EXIT_CODE=${PIPESTATUS[0]}

if [ $OEWIZARD_EXIT_CODE -eq 0 ]; then
    echo "✅ SOE schema build completed successfully at $(date)" | tee -a "$BUILD_LOG"
    
    # Test the newly created schema (same as working script)
    echo "Testing new SOE schema..." | tee -a "$BUILD_LOG"
    echo "Trying to unlock SOE user and reset password..." | tee -a "$BUILD_LOG"
    echo "ALTER USER soe ACCOUNT UNLOCK;" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba" | tee -a "$BUILD_LOG"
    echo "ALTER USER soe IDENTIFIED BY $SOE_PASSWORD;" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba" | tee -a "$BUILD_LOG"
    
    echo "Testing SOE user connection directly..." | tee -a "$BUILD_LOG"
    echo "SELECT 'SOE Schema Test Successful' as result FROM dual;" | sqlplus -S "$SOE_USER/$SOE_PASSWORD@$ORACLE_SID" | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ SOE schema is accessible and working!" | tee -a "$BUILD_LOG"
        echo "Schema: $SOE_USER/$SOE_PASSWORD" | tee -a "$BUILD_LOG"
        echo "Scale Factor: $SCALE_FACTOR" | tee -a "$BUILD_LOG"
        
        # Try a quick test run (same as working script)
        echo "Running quick test to verify schema works with charbench..." | tee -a "$BUILD_LOG"
        
        ./charbench \
          -c ../configs/SOE_Server_Side_V2.xml \
          -cs "$ORACLE_SID" \
          -u "$SOE_USER" \
          -p "$SOE_PASSWORD" \
          -rt 0:0.10 \
          -r "$TEST_RESULTS_XML" \
          -a 2>&1 | tee -a "$BUILD_LOG"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "🎉 SUCCESS! SOE schema is fully functional for benchmarking!" | tee -a "$BUILD_LOG"
            echo "✅ Schema test results saved to: $TEST_RESULTS_XML" | tee -a "$BUILD_LOG"
        else
            echo "⚠️  SOE schema created but benchmark test failed" | tee -a "$BUILD_LOG"
        fi
    else
        echo "⚠️  SOE schema was created but may not be fully accessible" | tee -a "$BUILD_LOG"
    fi
else
    echo "❌ SOE schema build failed at $(date)" | tee -a "$BUILD_LOG"
    echo "Exit code: $OEWIZARD_EXIT_CODE" | tee -a "$BUILD_LOG"
    echo "This might be due to oewizard config file issues, but the simple test already works" | tee -a "$BUILD_LOG"
    exit 1
fi

echo "=================================================="
echo "Build completed. Files created:"
echo "- Build log: $BUILD_LOG"
if [ -f "$TEST_RESULTS_XML" ]; then
    echo "- Schema test results: $TEST_RESULTS_XML"
fi
echo "==================================================" 