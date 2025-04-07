#!/bin/bash
set -euo pipefail

# Oracle Instant Client version
VER="19.26.0.0.0-1.el8"

# RPM filenames
BASIC_RPM="oracle-instantclient19.26-basic-${VER}.x86_64.rpm"
SQLPLUS_RPM="oracle-instantclient19.26-sqlplus-${VER}.x86_64.rpm"

# Download directory
TMP_DIR="/tmp"

echo "Downloading Oracle Instant Client RPMs..."
curl -L "https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/$BASIC_RPM" -o "$TMP_DIR/$BASIC_RPM"
curl -L "https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/$SQLPLUS_RPM" -o "$TMP_DIR/$SQLPLUS_RPM"

echo "Installing RPMs..."
sudo dnf install -y "$TMP_DIR/$BASIC_RPM"
sudo dnf install -y "$TMP_DIR/$SQLPLUS_RPM"

echo "Done installing Oracle Instant Client."

# Show environment setup instructions
cat <<EOF

──────────────────────────────
Instant Client installed.

update this in your build.tcl or run.tcl if required before using HammerDB:

ORACLE_HOME=/usr/lib/oracle/19.26/client64
LD_LIBRARY_PATH=\$ORACLE_HOME/lib

──────────────────────────────
EOF
