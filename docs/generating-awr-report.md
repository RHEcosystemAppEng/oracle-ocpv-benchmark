- [Understanding Oracle Snapshots and Generating AWR Reports in a RAC CDB/PDB Environment](#understanding-oracle-snapshots-and-generating-awr-reports-in-a-rac-cdb-pdb-environment)
    * [Snapshot Level in RAC](#snapshot-level-in-rac)
    * [Understanding DBA_HIST_SNAPSHOT and DBA_HIST_DATABASE_INSTANCE in Oracle Multitenant](#understanding-dba-hist-snapshot-and-dba-hist-database-instance-in-oracle-multitenant)
        + [DBA_HIST_SNAPSHOT in CDB and PDB](#dba-hist-snapshot-in-cdb-and-pdb)
        + [DBA_HIST_DATABASE_INSTANCE and its CDB-Centric Nature](#dba-hist-database-instance-and-its-cdb-centric-nature)
    * [Understanding `CON_ID` (Container ID)](#understanding--con-id---container-id-)
    * [Relationship Between Manual PDB and CDB Snapshots in Oracle Multitenant](#relationship-between-manual-pdb-and-cdb-snapshots-in-oracle-multitenant)
    * [Generating AWR Reports for a Specific PDB (`con_id`)](#generating-awr-reports-for-a-specific-pdb---con-id--)


# Understanding Oracle Snapshots and Generating AWR Reports in a RAC CDB/PDB Environment

This article summarizes key concepts related to Oracle snapshots and generate AWR reports within a Real Application Clusters (RAC) environment that includes a Container Database (CDB) and a Pluggable Database (PDB).

## Snapshot Level in RAC

In an Oracle RAC environment with a CDB and PDBs, snapshot operations occur at the **database level**. 

This will return most recent snapshot per container.
```sql
SELECT max(snap_id), con_id FROM dba_hist_snapshot GROUP BY con_id;
```

below query returns all the containers
```sql
select * from DBA_HIST_DATABASE_INSTANCE
```


Below query is pulled out from the hammerdb source code. It is helpful to find hammerdb specific snapshots.
```sql
SELECT
    INSTANCE_NUMBER,
    INSTANCE_NAME,
    DB_NAME,
    DBID,
    SNAP_ID,
    TO_CHAR(END_INTERVAL_TIME, 'DD MON YYYY HH24:MI')
FROM
    (
        SELECT
            DI.INSTANCE_NUMBER,
            DI.INSTANCE_NAME,
            DI.DB_NAME,
            DI.DBID,
            DS.SNAP_ID,
            DS.END_INTERVAL_TIME
        FROM
            DBA_HIST_SNAPSHOT DS,
            DBA_HIST_DATABASE_INSTANCE DI
        WHERE
            DS.DBID = DI.DBID
          AND DS.INSTANCE_NUMBER = DI.INSTANCE_NUMBER
          AND DS.STARTUP_TIME = DI.STARTUP_TIME
        ORDER BY
            DS.END_INTERVAL_TIME DESC)
WHERE
    ROWNUM = 1;
```

## Understanding DBA_HIST_SNAPSHOT and DBA_HIST_DATABASE_INSTANCE in Oracle Multitenant

This Section explains the presence and purpose of `DBA_HIST_SNAPSHOT` and `DBA_HIST_DATABASE_INSTANCE` views in an Oracle Multitenant architecture (CDB and PDBs).

### DBA_HIST_SNAPSHOT in CDB and PDB

The `DBA_HIST_SNAPSHOT` view, which tracks Automatic Workload Repository (AWR) snapshots, exists at both the Container Database (CDB) level and within each Pluggable Database (PDB).

* **CDB Level (`CON_ID = 0`):** When queried from the CDB root, `DBA_HIST_SNAPSHOT` provides information about snapshots taken for the entire CDB. This includes the snapshot ID, start and end times, snapshot level, and encompasses all PDBs within the CDB.

* **PDB Level (`CON_ID > 0`):** When queried from within a specific PDB, `DBA_HIST_SNAPSHOT` shows records relevant to that PDB (where `CON_ID` matches the PDB's `CON_ID`). These entries track the snapshot intervals during which performance data was collected specifically for that PDB.

**Reasons for `DBA_HIST_SNAPSHOT` at the PDB Level:**

1.  **PDB-Specific AWR Data:** Oracle allows for the collection and retention of AWR data tailored to individual PDBs. The `DBA_HIST_SNAPSHOT` table within a PDB is essential for tracking the snapshots containing this PDB-specific performance information.

2.  **Independent Management:** PDBs can have their own AWR configurations (though often inheriting from the CDB). Having `DBA_HIST_SNAPSHOT` locally allows for easier management and querying of the snapshot history specific to that PDB.

3.  **Simplified PDB Administration:** Administrators working within a PDB can directly query the local `DBA_HIST_SNAPSHOT` to understand the historical performance data available for that PDB, without needing to filter through the CDB's entire snapshot history.

4.  **Consistent Interface:** Oracle aims for a consistent set of data dictionary views across different database components. The presence of `DBA_HIST_SNAPSHOT` at the PDB level provides a familiar interface for AWR management within the context of a PDB.

### DBA_HIST_DATABASE_INSTANCE and its CDB-Centric Nature

The `DBA_HIST_DATABASE_INSTANCE` view primarily captures historical information about the Oracle database *instances* themselves. This includes details like startup times, database versions, instance names, and host names.

**Reasons why `DBA_HIST_DATABASE_INSTANCE` appears more CDB-centric:**

1.  **Instance-Specific Attributes:** The core attributes tracked by `DBA_HIST_DATABASE_INSTANCE` are largely tied to the database instances that make up the CDB (especially in a RAC environment). These instances serve all the PDBs that are open within the CDB.

2.  **PDB Lifecycle Independence:** PDBs can be plugged into and unplugged from a CDB, having a lifecycle somewhat independent of the underlying database instances. The fundamental characteristics of a database instance (its unique ID, when it started) are properties of the overall database environment managed at the CDB level.

3.  **Resource Allocation Context:** While PDBs have their own resource management capabilities, the underlying database instances and their configurations provide the foundational context for resource allocation within the CDB. `DBA_HIST_DATABASE_INSTANCE` reflects these instance-level details.

**Conclusion:**

The design where `DBA_HIST_SNAPSHOT` exists at both CDB and PDB levels, while `DBA_HIST_DATABASE_INSTANCE` is more CDB-focused, provides a balance between managing the entire multitenant environment and allowing for granular monitoring and administration of individual PDBs. This structure ensures that performance data and instance-level information are tracked appropriately for effective management of Oracle Multitenant databases.


## Understanding `CON_ID` (Container ID)

In Oracle Multitenant architecture, the `CON_ID` (Container ID) is a crucial identifier that distinguishes data and metadata belonging to different containers within a CDB.

* **`CON_ID = 0`**: This value specifically refers to the **CDB root**. The root container (`CDB$ROOT`) is the central administrative container in a multitenant database. It stores common metadata and administrative tasks that are shared or can be performed across the entire CDB.

* **`CON_ID > 0`**: These values identify specific **Pluggable Databases (PDBs)**. Each PDB within a CDB has a unique `CON_ID`. PDBs are self-contained databases that can be plugged into and unplugged from a CDB. They operate as independent databases from an application perspective. In your case, based on the provided data, `CON_ID = 3` likely corresponds to your portable database `pdb01`.

The `CON_ID` is present in many data dictionary views and performance statistics tables, including `dba_hist_snapshot` and `DBA_HIST_DATABASE_INSTANCE`, allowing you to filter and analyze data specific to a particular container (either the CDB root or a specific PDB).


## Relationship Between Manual PDB and CDB Snapshots in Oracle Multitenant
This Section explains whether manually taking a snapshot at the Pluggable Database (PDB) level also triggers a manual snapshot at the Container Database (CDB) level in Oracle Multitenant architecture.

**Key Points:**

* **Independent Manual Invocation:** Manually triggering a snapshot at the PDB level is an independent action from manually triggering a snapshot at the CDB level. Initiating a manual snapshot within a PDB does **not** automatically cause a separate manual snapshot to be taken at the CDB level at the same time, and vice versa.

* **Scope of Manual PDB Snapshot:** When you manually take a snapshot while connected to a PDB, the operation primarily focuses on capturing the data relevant to that specific PDB at that point in time.

* **Scope of Manual CDB Snapshot:** When you manually take a snapshot while connected to the CDB root, the operation captures the overall state of the entire multitenant container database, encompassing all its PDBs at that point in time.

* **No Automatic Cross-Triggering for Manual Snapshots:** There is no built-in mechanism that automatically triggers a CDB-level manual snapshot simply because a PDB-level manual snapshot was initiated, or the other way around. These are distinct administrative tasks.

**Conclusion:**

Manually taking a snapshot at the PDB level and manually taking a snapshot at the CDB level are independent operations. One does not automatically trigger the other. To capture a specific point-in-time for both the CDB and a PDB simultaneously, you would need to manually initiate a snapshot operation while connected to the CDB and then separately initiate a manual snapshot while connected to the PDB (or vice versa).

To review the snapshot history for manually triggered snapshots:

* Connect to the CDB root to see CDB-level snapshots (where `CON_ID = 0`).
* Connect to a specific PDB to see snapshots relevant to that PDB (where `CON_ID` matches the PDB's container ID).

You might choose to initiate manual snapshots at both levels around the same time for coordinated analysis, but this would be a deliberate administrative action, not an automatic consequence of triggering a snapshot at one level.

## Generating AWR Reports for a Specific PDB (`con_id`)
To generate Automatic Workload Repository (AWR) reports specifically for a Pluggable Database (PDB), you need to connect to that PDB and then execute the `awrrpt.sql` script. This ensures that the generated report focuses on the performance statistics relevant to that specific container.

AWR generation scripts are available only on the database server so you have to perform below steps on the database server. Also for the oracle rac node ORACLE_HOME is not available but installed at the path `cd /u01/app/oracle/product/19.0.0.0/dbhome_1/`

**Steps:**

export TNS_ADMIN=<path to TNS admin directory>

1.  **Connect to the PDB:**
    Establish an SQL session within the target PDB (e.g., `pdb01`).

    ```sql
    -- Using a service name (replace pdb01_service with your PDB's service name)
    sqlplus system/password@pdb01_service

    -- Alternatively, if connected to the CDB root:
    sqlplus system/password@cdb_service
    SQL> ALTER SESSION SET CONTAINER=pdb1;
    ```

2.  **Run the AWR Report Script:**
    The scripts exist in the `$ORACLE_HOME/rdbms/admin` directory.
    Below script will generate the report for only current instance.
    ```sql
    SQL> @?/rdbms/admin/awrrpt.sql
    ```
    Below script will generate the report for all the instances.
    ```sql
    SQL> @?/rdbms/admin/awrgrpt.sql
    ```

Note: If you are generating the report for portable database then you have to select the location as AWR_PDB. AWR_ROOT will generate the report for the CDB database.

3.  **Specify Report Parameters:**
    If the script will prompt you for:
    * **Instance Number:** Choose `ALL` for a combined report across RAC nodes for the PDB, or a specific instance number.
    * **Number of Days:** Specify the range of AWR data to consider.
    * **Beginning and Ending Snapshot IDs:** **Crucially, select the `SNAP_ID` values that correspond to the activity within your target PDB (identified by its `CON_ID`).** You can filter `dba_hist_snapshot` by `CON_ID` to find the relevant snapshot IDs for your PDB.
    * **Report Name:** Provide a name for the generated AWR report.