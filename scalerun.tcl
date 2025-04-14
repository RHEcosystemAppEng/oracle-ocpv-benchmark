puts "Starting Oracle TPCC scale-up benchmark run"

set env(TNS_ADMIN) "[file normalize ../oracle-net]"
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

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

dbset db ora
loadscript

set profile_id [expr {[info exists ::env(HDB_PROFILE_ID)] ? $::env(HDB_PROFILE_ID) : 0}]
profileset $profile_id
puts "Using HammerDB internal profile ID: $profile_id"

diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "oralab"}]

diset tpcc ora_driver       timed
diset tpcc ora_count_ware   [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 1000}]
diset tpcc ora_rampup       [expr {[info exists ::env(ORA_RAMPUP)] ? $::env(ORA_RAMPUP) : 5}]
diset tpcc ora_duration     [expr {[info exists ::env(ORA_DURATION)] ? $::env(ORA_DURATION) : 20}]
diset tpcc ora_allwarehouse [expr {[info exists ::env(ORA_ALLWAREHOUSE)] ? $::env(ORA_ALLWAREHOUSE) : "true"}]
diset tpcc ora_timeprofile  true
diset tpcc ora_raiseerror   true
diset tpcc ora_user         [expr {[info exists ::env(ORA_TPCC_USER)] ? $::env(ORA_TPCC_USER) : "tpcc"}]
diset tpcc ora_pass         [expr {[info exists ::env(ORA_TPCC_PASS)] ? $::env(ORA_TPCC_PASS) : "tpcc"}]
diset tpcc userexists       true

if {[info exists ::env(VU_LIST)]} {
    set vu_list $::env(VU_LIST)
} else {
    set vu_list {10 20 40 80 100}
}

foreach vu $vu_list {
    puts "\nRunning with $vu virtual users"

    diset tpcc ora_num_vu $vu
    loadscript

    vuset vu $vu
    vuset unique 1
    vuset timestamps 1
    vuset showoutput 0
    vuset delay 20
    vuset repeat 1

    vurun
    wait_to_complete

    set result [tcresult nopm]
    puts "$vu VU → $result NOPM"
}

puts "\nAll VU test runs complete"
exit
