#!/bin/sh

val_command="validate backupset "
export ORACLE_SID=rgb1p094
old_path=$PATH
ORAENV_ASK=NO

log_path=/u05/$ORACLE_SID/logs
log_file=`ls $log_path | tail -1`

#Function to extract values using sqlplus
connect_to_sql () {
SQL_OUTPUT=$( $ORACLE_HOME/bin/sqlplus -s / as sysdba<< OCI
set heading off
set feedback off
$1
exit
OCI
)
echo "$SQL_OUTPUT"| grep -v \^$
}

#MAIN
export ORACLE_SID
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/12.1.0/dbhome_1
. oraenv 

INST_NAME=$(connect_to_sql "select name from v\$database;")
RECID=$(connect_to_sql "select recid from v\$backup_set where incremental_level=1 and completion_time > sysdate-1;")
echo "Validation of INC backupsets will run on DB: $INST_NAME"
echo "Validate starting at `date` "
echo "The backupsets will be validated:"
echo "$RECID"

for i in `echo "$RECID"`
do
 val_command="$val_command $i,"
done

val_command=`echo "${val_command%?}"`
val_command="$val_command;"

echo "$val_command" > /home/oracle/rman/validate.rcv

export NLS_DATE_FORMAT="dd-month-yyyy hh:mi:ss am"
$ORACLE_HOME/bin/rman target / cmdfile=/home/oracle/rman/validate.rcv log=$log_path/$log_file append > /dev/null 2>&1

echo "Validate completed at `date` "
