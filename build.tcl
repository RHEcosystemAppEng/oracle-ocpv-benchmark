# Set DB type to Oracle
dbset db ora

# Oracle environment
set env(TNS_ADMIN) "[file normalize ../oracle-net]"
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

# System user connection
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance oralab

# TPCC schema settings
diset tpcc ora_user tpcc
diset tpcc ora_pass tpcc
diset tpcc ora_tablespace USERS
diset tpcc ora_storage "DEFAULT"
diset tpcc ora_count_ware 10
diset tpcc ora_num_vu 10
diset tpcc ora_durability nologging

# Build the TPCC schema
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
