puts "Starting Oracle TPCC scale-up benchmark run..."

# Oracle environment setup
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

# Completion handler
global complete
proc wait_to_complete {} {
    global complete
    set complete [vucomplete]
    if {!$complete} {
        after 5000 wait_to_complete
    } else {
        return
    }
}

# Database type
dbset db ora


set profile_id [expr {[info exists ::env(HDB_PROFILE_ID)] ? $::env(HDB_PROFILE_ID) : 0}]
jobs profileid $profile_id
puts "Using HammerDB profile ID: $profile_id"

# Load driver
loadscript

# Oracle DB connection
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "oralab"}]


diset tpcc ora_driver       timed
diset tpcc count_ware       [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 1000}]
diset tpcc rampup           [expr {[info exists ::env(ORA_RAMPUP)] ? $::env(ORA_RAMPUP) : 5}]
diset tpcc duration         [expr {[info exists ::env(ORA_DURATION)] ? $::env(ORA_DURATION) : 20}]
diset tpcc allwarehouse     [expr {[info exists ::env(ORA_ALLWAREHOUSE)] ? $::env(ORA_ALLWAREHOUSE) : "true"}]
diset tpcc ora_timeprofile  true
diset tpcc ora_raiseerror   true
diset tpcc tpcc_user        [expr {[info exists ::env(ORA_TPCC_USER)] ? $::env(ORA_TPCC_USER) : "tpcc"}]
diset tpcc tpcc_pass        [expr {[info exists ::env(ORA_TPCC_PASS)] ? $::env(ORA_TPCC_PASS) : "tpcc"}]
diset tpcc userexists       true

# Virtual User list
if {[info exists ::env(VU_LIST)]} {
    set vu_list [split $::env(VU_LIST)]
} else {
    set vu_list {10 20 40 80 100}
}

# Optional system metrics
# metstart
puts "\nTEST STARTED"

foreach vu $vu_list {
    puts "\n️Running with $vu virtual users..."

    diset tpcc num_vu $vu
    loadscript

    vuset vu $vu
    vuset logtotemp 1
    vuset unique 1
    vuset timestamps 1
    vuset showoutput 0
    vuset delay 20
    vuset repeat 1

    vucreate
    tcstart
    tcstatus
    vurun
    tcstop
    vudestroy
    wait_to_complete
}

# metstop

puts "Scale-up test complete."

