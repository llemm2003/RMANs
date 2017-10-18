#!/bin/sh

# Walk through DBNAMEs in oratab
for dbname in `egrep -v "^(\#|\+|\$|\*)" /etc/oratab | egrep -v "dummy|ORCL|test" | egrep "^\w{3,9}" | cut -d ':' -f1 | uniq`; do

# If DBNAME is not running, skip the DBNAME
  if [[ ! `/bin/ps -ef | /bin/grep -i ora_pmon_${dbname} | /bin/grep -v grep | /usr/bin/wc -l` -eq 1 ]] ; then
       continue
  fi

# Determine home for DBNAME
        strORACLE_HOME=`/bin/egrep -v "^(\#|\+|\$)" /etc/oratab | /bin/grep -i ${dbname} | /bin/cut -d ':' -f2`
        export ORACLE_HOME=$strORACLE_HOME
        export PATH=$ORACLE_HOME/bin:/home/oracle/rman:${strOriginalPATH}

# Determine SID to connect to by RMAN
#         sidConnection=`/bin/ps -ef | /bin/grep -i ora_pmon_${dbname} | /bin/grep -v grep | /bin/cut -d '_' -f3`
         sidConnection=`/bin/ps -ef | /bin/grep -i ora_pmon_${dbname} | /bin/grep -v grep | /bin/awk '{print $8}' | /bin/sed 's/ora_pmon_//' | /bin/egrep -v sed`
        export ORACLE_SID="${sidConnection}"

echo "oracle sid connection" $ORACLE_SID

# Determine SID to connect to by RMAN
# export ORACLE_SID="${sidConnection}"
# export ORACLE_HOME=$strORACLE_HOME
# export PATH=$ORACLE_HOME/bin:/home/oracle/rman:${strOriginalPATH}
# export ORACLE_SID="${dbname}"

pathRMANScript="/home/oracle/rman"

if [[ -f "$pathRMANScript/.encrypted_passwd" ]]; then
encryp_passwd=`/bin/cat $pathRMANScript/.encrypted_passwd`
echo "set encryption on identified by ${encryp_passwd} only; " > ${pathRMANScript}/rman_validate.rcv
echo "set decryption identified by ${encryp_passwd}; " >> ${pathRMANScript}/rman_validate.rcv
else
echo "# No encryption" > ${pathRMANScript}/rman_validate.rcv
fi

val_command="validate backupset "
old_path=$PATH
ORAENV_ASK=NO

log_path=${pathRMANScript}
log_file=`/bin/ls $log_path | /usr/bin/tail -1`

#Function to extract values using sqlplus
connect_to_sql () {
SQL_OUTPUT=$( $ORACLE_HOME/bin/sqlplus -s / as sysdba<< OCI
set heading off
set feedback off
$1
exit
OCI
)
echo "$SQL_OUTPUT"| /bin/grep -v \^$
}

#MAIN
#export ORACLE_SID
export ORACLE_BASE=/u01/app/oracle

INST_NAME=$(connect_to_sql "select name from v\$database;")
RECID=$(connect_to_sql "select recid from v\$backup_set where incremental_level=1 and completion_time > sysdate-1;")
echo "Validation of INC backupsets will run on DB: $INST_NAME"
echo "Validate starting at `/bin/date` "
echo "The backupsets will be validated:"
echo "$RECID"

for i in `echo "$RECID"`
do
val_command="$val_command $i,"
done

val_command=`echo "${val_command%?}"`
val_command="$val_command;"

echo "$val_command" >> ${pathRMANScript}/rman_validate.rcv

export NLS_DATE_FORMAT="dd-month-yyyy hh:mi:ss am"
$ORACLE_HOME/bin/rman target / cmdfile=/home/oracle/rman/rman_validate.rcv log=$log_path/$log_file > /dev/null 2>&1

echo "Validate completed at `/bin/date` "

done
[oracle@avvrollrdbu001a wget]$
