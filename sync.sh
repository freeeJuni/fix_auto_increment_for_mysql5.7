#!/bin/bash

#############
# usage
#############

if [ "$1" = "" -o "$1" = "help" -o  "$1" = "-help" ]; then
  echo " "
  echo "it is the fixing script for auto_increment number after rebooting with MySQL 5.7 !!"
  echo " "
  echo "usage: sh sync.sh -h HOSTNAME -u USER -p PASSWORD -P 3306 -d DB_NAME bf(or af)"
  echo " "
  echo " [option]"
  echo " : bf   = before reboot"
  echo " : af   = after reboot"
  echo " : sync = diff & syncing auto_increment"
  echo " "
  exit 9
fi

#############
# set args 
#############

ARGS=$#

set_opt()
{	
  if [ "$1" = "-h" ]; then
    HOST="$2"
  elif [ "$1" = "-u" ]; then
    USER="$2"
  elif [ "$1" = "-p" ]; then
    PASSWORD="$2"
  elif [ "$1" = "-P" ]; then
    PORT="$2"
  elif [ "$1" = "-d" ]; then
    DB="$2"
  else
    echo "[ERROR] Option error!"
    exit 9
  fi
}

set_opt "$1" "$2"
set_opt "$3" "$4"
set_opt "$5" "$6"
set_opt "$7" "$8"
set_opt "$9" "$10"

if [ "$11" = "bf" ]; then
  OPT=$11
elif [ "$11" = "af" ]; then
  OPT=$11
elif [ "$11" = "sync" ]; then
  OPT=$11
fi


######################
# set MySQL command
######################
MYSQL_CMD="mysql -N ${DB} -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"
MYSQL_CMD_VERBOSE="mysql -vvv ${DB} -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"

############
# check schema
############

chk_schema()
{
  if [ -e ${LOG_PREFIX}_auto_inc.log ]; then
    \rm -if ${LOG_PREFIX}_auto_inc.log
  fi	
  CREATE_TABLE_LIST=`echo "show tables;" | ${MYSQL_CMD} | sort > table.list`
  while read LINE
  do
    AUTO_INC_CNT=`echo "show create table ${LINE} \G" | ${MYSQL_CMD} | grep "ENGINE=" | awk '{print $3}' | cut -d "=" -f 2`
    echo "${LINE} ${AUTO_INC_CNT}" >> ${LOG_PREFIX}_auto_inc.log
  done < table.list
}


##########################
# sync auto_increment 
##########################

sync_auto_inc()
{
  while read TABLE_NAME
  do
     echo "--------" | tee -a operation.log
     echo "--------" | tee -a operation.log
     echo "--------" | tee -a operation.log
     bf_cnt=`grep "${TABLE_NAME}" before_auto_inc.log | awk '{print $2}'`
     af_cnt=`grep "${TABLE_NAME}" after_auto_inc.log | awk '{print $2}'`
     echo ${TABLE_NAME} | tee -a operation.log
     echo "before : ${bf_cnt}" | tee -a operation.log
     echo "after  : ${af_cnt}" | tee -a operation.log
      
     if [ ${bf_cnt} -gt ${af_cnt} ]; then 
       echo "-> Before is greater than After : ${bf_cnt}"  | tee -a operation.log
       #echo "ALTER TABLE ${TABLE_NAME} AUTO_INCREMENT = ${bf_cnt} ;" 
       echo "ALTER TABLE ${TABLE_NAME} AUTO_INCREMENT = ${bf_cnt} ;" | ${MYSQL_CMD_VERBOSE} | tee -a operation.log
     elif [ ${bf_cnt} -lt ${af_cnt} ]; then  
       echo "-> Skipped ALTER operation because After is greater than Before : ${af_cnt}"  | tee -a operation.log
     elif [ ${bf_cnt} -eq ${af_cnt} ]; then  
       echo "-> Skipped because of the Same number!" | tee -a operation.log
     fi
  done < table.list
}


############
# main
############
case ${OPT} in
  'bf')
        LOG_PREFIX="before"
        if [ -e table.list ]; then
          \rm -if table.list
        fi
        chk_schema
        ;;
  'af')
        LOG_PREFIX="after"
        if [ -e operation.log ]; then
          \rm -if operation.log
        fi
        chk_schema
        sync_auto_inc
        ;;
esac

exit 0
