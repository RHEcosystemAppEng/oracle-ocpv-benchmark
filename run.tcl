puts "Starting Oracle TPCC benchmark run..."

# Oracle environment variables
set env(TNS_ADMIN) "[file normalize ../oracle-net]"
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
profileset $profile_id
puts "Using HammerDB internal profile ID: $profile_id"

# Load TPCC driver
loadscript

# Connection settings
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "oralab"}]

diset tpcc ora_driver       timed
diset tpcc ora_num_vu       [expr {[info exists ::env(ORA_NUM_VU)] ? $::env(ORA_NUM_VU) : 10}]
diset tpcc ora_count_ware   [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 10}]
diset tpcc ora_rampup       [expr {[info exists ::env(ORA_RAMPUP)] ? $::env(ORA_RAMPUP) : 2}]
diset tpcc ora_duration     [expr {[info exists ::env(ORA_DURATION)] ? $::env(ORA_DURATION) : 5}]
diset tpcc ora_allwarehouse [expr {[info exists ::env(ORA_ALLWAREHOUSE)] ? $::env(ORA_ALLWAREHOUSE) : "false"}]
diset tpcc ora_timeprofile  true
diset tpcc ora_raiseerror   true

puts "Configuration:"
print dict

vuset vu $::env(ORA_NUM_VU)
vuset unique 1
vuset timestamps 1
vuset showoutput 0
vuset delay 20
vuset repeat 1

puts "Launching Virtual Users..."
vurun

wait_to_complete
vwait forever
