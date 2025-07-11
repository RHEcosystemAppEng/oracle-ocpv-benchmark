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

# making sure virtual user destroyed before running another run
proc safe_vudestroy {} {
    puts "Destroying virtual users..."
    vudestroy
    # Wait and verify destruction
    set max_attempts 10
    set attempt 0
    while {$attempt < $max_attempts} {
        after 2000  ; # Wait 2 seconds
        # Check if virtual users still exist using vustatus
        if {[catch {vustatus} vu_status] == 0} {
            # If vustatus returns without error and shows no active VUs
            if {![string match "*Virtual Users*" $vu_status] || [string match "*0 Virtual Users*" $vu_status]} {
                puts "Virtual users successfully destroyed"
                return 1
            }
        } else {
            # If vustatus fails, likely no VUs exist
            puts "Virtual users successfully destroyed"
            return 1
        }
        incr attempt
        puts "Waiting for virtual users to be destroyed... (attempt $attempt/$max_attempts)"
    }
    puts "WARNING: Virtual users may not have been fully destroyed"
    return 0
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
diset connection instance [expr {[info exists ::env(ORACLE_SID)] ? $::env(ORACLE_SID) : "oralab"}]

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

    # Reset completion flag
    set complete 0

    # Configure for this VU count
    diset tpcc num_vu $vu
    loadscript

    # Virtual user settings
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

    # Wait for completion
    puts "Waiting for test completion..."
    wait_to_complete

    # Stop test
    tcstop

    # Safely destroy virtual users
    safe_vudestroy

    puts "Waiting before next iteration..."
    after 3000
}

# metstop
puts "Scale-up test complete."