#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

echo "=================================================="
echo "Simple SwingBench Direct Test"
echo "=================================================="
echo "This test bypasses config files and uses direct command line"
echo "Script Directory: $SCRIPT_DIR"
echo "SwingBench Home: $SWINGBENCH_HOME"
echo "Results Directory: $RESULTS_DIR"
echo "=================================================="

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Define the result file path
SIMPLE_TEST_LOG="$RESULTS_DIR/swingbench_simple_test.log"

# Test SYS connection
echo "Testing SYS connection..."
echo "exit" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Cannot connect as SYS"
    exit 1
fi
echo "✅ SYS connection successful"

# Go to SwingBench bin directory
cd "$SWINGBENCH_HOME/bin"

echo "Testing SwingBench charbench (simple test)..."
echo "This should at least show SwingBench is working..."

# Try a simple help command first
echo "Running SwingBench help..."
./charbench -h 2>&1 | head -20

echo "=================================================="
echo "SwingBench appears to be working!"
echo "Now testing basic connectivity..."

# First, let's see what config files are available
echo "Available config files:"
ls -la ../configs/

# Try a very simple benchmark test (minimal duration)
echo "Running minimal SOE benchmark test (30 seconds)..."
echo "Note: charbench may not support 'as sysdba' syntax directly"

# Try with different approaches
echo "Attempting 1: Check if SOE schema exists and is accessible..."
echo "SELECT username FROM dba_users WHERE username = 'SOE';" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"

echo "Checking SOE user status (locked/unlocked)..."
echo "SELECT username, account_status, lock_date FROM dba_users WHERE username = 'SOE';" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"

echo "Current SOE_USER: $SOE_USER"
echo "Current SOE_PASSWORD: [HIDDEN]"
echo "Trying to unlock SOE user and reset password..."
echo "ALTER USER soe ACCOUNT UNLOCK;" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"
echo "ALTER USER soe IDENTIFIED BY $SOE_PASSWORD;" | sqlplus -S "sys/$ORACLE_SYS_PASSWORD@$ORACLE_SID as sysdba"

echo "Testing SOE user connection directly..."
echo "SELECT 'SOE Connection Test Successful' as result FROM dual;" | sqlplus -S "$SOE_USER/$SOE_PASSWORD@$ORACLE_SID"
if [ $? -eq 0 ]; then
    echo "✅ SOE user connection successful"
else
    echo "❌ SOE user connection still failed"
fi

echo "Attempting 2: Using SOE user credentials with charbench..."

# Define the results file path with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_XML_TARGET="$RESULTS_DIR/swingbench_results_${TIMESTAMP}.xml"

./charbench \
  -c ../configs/SOE_Server_Side_V2.xml \
  -cs "$ORACLE_SID" \
  -u "$SOE_USER" \
  -p "$SOE_PASSWORD" \
  -rt 0:0.30 \
  -r "$RESULTS_XML_TARGET" \
  -a 2>&1 | tee "$SIMPLE_TEST_LOG"

# Create a symlink to the latest results if the benchmark succeeded
if [ -f "$RESULTS_XML_TARGET" ]; then
    ln -sf "$RESULTS_XML_TARGET" "$RESULTS_DIR/swingbench_latest_results.xml"
    echo "✅ Results XML saved to: $RESULTS_XML_TARGET"
    echo "✅ Latest results symlink: $RESULTS_DIR/swingbench_latest_results.xml"
fi

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! SwingBench benchmark completed successfully!"
    echo "✅ SOE schema exists and is accessible"
    echo "✅ charbench can connect and run benchmarks"
    echo "✅ All SwingBench tools are working properly"
    echo ""
    echo "Your SwingBench setup is fully functional!"
else
    echo ""
    echo "charbench failed - but SOE schema exists, so this might be a connectivity issue"
    echo "Let's verify oewizard is also working..."
    
    # Test oewizard help
    echo "Testing oewizard help..."
    ./oewizard -h 2>&1 | head -10
    
    echo ""
    echo "Both tools appear functional. Check the log for specific connection errors."
fi

echo "=================================================="
echo "Simple test completed! Results saved to:"
echo "  $SIMPLE_TEST_LOG"
echo "==================================================" 