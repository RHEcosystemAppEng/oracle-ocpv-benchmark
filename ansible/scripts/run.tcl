puts "Starting Oracle TPCC benchmark run..."

# Oracle environment variables
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

# Wait for all Virtual Users to finish
global complete
proc wait_to_complete {} {
    global complete
    set complete [vucomplete]
    if {!$complete} {
        after 5000 wait_to_complete
    } else {
        exit
    }
}

# Set database type
dbset db ora

set profile_id [expr {[info exists ::env(HDB_PROFILE_ID)] ? $::env(HDB_PROFILE_ID) : 0}]
jobs profileid $profile_id
puts "Using HammerDB internal profile ID: $profile_id"

# Load TPCC driver
loadscript

# Connection settings
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "ORALAB"}]

diset tpcc ora_driver       timed
diset tpcc count_ware       [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 1000}]
diset tpcc rampup           [expr {[info exists ::env(ORA_RAMPUP)] ? $::env(ORA_RAMPUP) : 5}]
diset tpcc duration         [expr {[info exists ::env(ORA_DURATION)] ? $::env(ORA_DURATION) : 20}]
diset tpcc allwarehouse     [expr {[info exists ::env(ORA_ALLWAREHOUSE)] ? $::env(ORA_ALLWAREHOUSE) : "true"}]
diset tpcc ora_timeprofile  true
diset tpcc checkpoint       false

diset tpcc tpcc_user        [expr {[info exists ::env(ORA_TPCC_USER)] ? $::env(ORA_TPCC_USER) : "tpcc"}]
diset tpcc tpcc_pass        [expr {[info exists ::env(ORA_TPCC_PASS)] ? $::env(ORA_TPCC_PASS) : "tpcc"}]
diset tpcc userexists       true

# puts "Configuration:"
# print dict

# Virtual User settings
vuset vu $::env(ORA_NUM_VU)
vuset logtotemp 1
vuset unique 1
vuset timestamps 1
vuset showoutput 0
vuset delay 20

puts "Launching Virtual Users..."
vucreate
tcstart
vurun
tcstop
vudestroy
wait_to_complete
