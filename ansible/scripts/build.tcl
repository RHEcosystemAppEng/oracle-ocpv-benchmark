# Set DB type to Oracle
dbset db ORALAB

# Oracle environment
set env(TNS_ADMIN) "[file normalize ../oracle-net]"
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

# System user connection
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance [expr {[info exists ::env(ORACLE_INSTANCE)] ? $::env(ORACLE_INSTANCE) : "oralab"}]

diset tpcc ora_user        [expr {[info exists ::env(ORA_TPCC_USER)] ? $::env(ORA_TPCC_USER) : "tpcc"}]
diset tpcc ora_pass        [expr {[info exists ::env(ORA_TPCC_PASS)] ? $::env(ORA_TPCC_PASS) : "tpcc"}]
diset tpcc ora_tablespace  [expr {[info exists ::env(ORA_TABLESPACE)] ? $::env(ORA_TABLESPACE) : "USERS"}]
diset tpcc ora_storage     [expr {[info exists ::env(ORA_STORAGE)] ? $::env(ORA_STORAGE) : "DEFAULT"}]
diset tpcc ora_count_ware  [expr {[info exists ::env(ORA_COUNT_WARE)] ? $::env(ORA_COUNT_WARE) : 10}]
diset tpcc ora_num_vu      [expr {[info exists ::env(ORA_NUM_VU)] ? $::env(ORA_NUM_VU) : 10}]
diset tpcc ora_durability  [expr {[info exists ::env(ORA_DURABILITY)] ? $::env(ORA_DURABILITY) : "nologging"}]

puts "\nBuild configuration:"
print dict

puts "Launching schema build..."
buildschema

# Wait for schema build to finish
proc wait_to_complete {} {
    global complete
    set complete [vucomplete]
    if {!$complete} {
        after 5000 wait_to_complete
    } else {
        exit
    }
}

wait_to_complete
vwait forever
