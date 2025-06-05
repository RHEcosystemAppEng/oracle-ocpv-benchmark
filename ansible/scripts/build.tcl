#!/bin/tclsh

puts "Starting Oracle TPCC schema build..."

# Set the database type to Oracle
dbset db ora

# Set Oracle environment variables
set env(ORACLE_HOME)      "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH)  "$env(ORACLE_HOME)/lib"

# Set connection parameters
diset connection system_user     [expr {[info exists ::env(ORACLE_SYSTEM_USER)] ? $::env(ORACLE_SYSTEM_USER) : "system"}]
diset connection system_password [expr {[info exists ::env(ORACLE_SYSTEM_PASSWORD)] ? $::env(ORACLE_SYSTEM_PASSWORD) : "password"}]
diset connection instance        [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "oralab"}]

# Set TPCC parameters
set count_ware [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 10}]

diset tpcc tpcc_user       [expr {[info exists ::env(ORA_TPCC_USER)] ? $::env(ORA_TPCC_USER) : "tpcc"}]
diset tpcc tpcc_pass       [expr {[info exists ::env(ORA_TPCC_PASS)] ? $::env(ORA_TPCC_PASS) : "tpcc"}]
diset tpcc tpcc_def_tab    [expr {[info exists ::env(ORA_TABLESPACE)] ? $::env(ORA_TABLESPACE) : "USERS"}]
diset tpcc tpcc_ol_tab     [expr {[info exists ::env(ORA_TABLESPACE)] ? $::env(ORA_TABLESPACE) : "USERS"}]
diset tpcc count_ware      $count_ware
diset tpcc num_vu          [expr {[info exists ::env(ORA_NUM_VU)] ? $::env(ORA_NUM_VU) : 10}]

if {[expr $count_ware >= 200]} {
    diset tpcc partition true
    diset tpcc hash_clusters true
    diset tpcc tpcc_ol_tab USERS
} else {
    diset tpcc partition false
    diset tpcc hash_clusters false
}

# Load the script with the updated configuration
loadscript

# Print the current configuration
# puts "\nBuild configuration:"
# print dict

# Start schema build
puts "Launching schema build..."
buildschema

# Wait for schema build to finish
proc wait_to_complete {} {
    if {![vucomplete]} {
        after 5000 wait_to_complete
    } else {
        puts "Schema build completed."
        exit
    }
}

wait_to_complete
