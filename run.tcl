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

# Load TPCC driver
loadscript

# Connection settings
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
diset connection instance oralab

# TPCC user
diset tpcc ora_user tpcc
diset tpcc ora_pass tpcc
diset tpcc userexists true

# Workload config
diset tpcc ora_storedprocs true
diset tpcc ora_timeprofile true
diset tpcc ora_raiseerror true
diset tpcc ora_allwarehouse false
diset tpcc ora_driver timed
diset tpcc ora_rampup 2
diset tpcc ora_duration 5
diset tpcc ora_num_vu 10

# Reload config
loadscript

puts "Configuration:"
print dict

# VU settings
vuset vu 10
vuset unique 1
vuset timestamps 1
vuset showoutput 0
vuset delay 20
vuset repeat 1

puts "Launching Virtual Users..."
vurun

wait_to_complete
vwait forever
