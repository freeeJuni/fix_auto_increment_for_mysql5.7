#!/bin/sh

#############
# usage
#############

if [ "$1" = "" -o "$1" = "help" -o  "$1" = "-help" ]; then
  cat <<EOF

it is the fixing script for auto_increment number after rebooting with MySQL 5.7 !!

usage: ./for_mysql57_reboot.sh -h HOSTNAME -u USER -p PASSWORD -P 3306 -d DB_NAME bf(or af)

[option]
 : bf       = execution before reboot
 : af       = execution after reboot
 : disable  = ONLY execution permission disable
 : enable   = ONLY execution permission enable

[summary]
# OPTION = bf
before DB reboot,
 - get schema information including auto_increment value
 - disable DB permission

# OPTION = af
after DB reboot,
 - check auto_increment difference
 - fix auto_increment values
 - enable DB permission

# OPTION = disable
before DB reboot,
 - ONLY disable DB permission

# OPTION = enable
after DB reboot,
 - ONLY enable DB permission

EOF
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
elif [ "$11" = "disable" ]; then
  OPT=$11
elif [ "$11" = "enable" ]; then
  OPT=$11
fi


######################
# set MySQL command
######################
MYSQL_CMD="mysql -N ${DB} -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"
MYSQL_CMD_INFORMATION_SCHEMA="mysql -N information_schema -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"
MYSQL_CMD_VERBOSE="mysql -vvv ${DB} -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"
MYSQL_CMD_VERBOSE2="mysql -vv ${DB} -h${HOST} -u${USER} -p${PASSWORD} -P${PORT}"

######################
# make log directory
######################
LOG_DIR="./LOG/${DB}_`date '+%Y%m%d'`"
mkdir -p ${LOG_DIR}


############
# check schema
############

chk_schema()
{
  if [ -e ${LOG_DIR}/${LOG_PREFIX}_auto_inc.log ]; then
    \rm -if ${LOG_DIR}/${LOG_PREFIX}_auto_inc.log
  fi
  if [ ${LOG_PREFIX} = "before" ]; then
    CREATE_TABLE_LIST=`echo "show tables;" | ${MYSQL_CMD} | sort > ${LOG_DIR}/table.list`
  fi
  echo "[Get Auto_increment values]"
  while read LINE
  do
    AUTO_INC_CNT=`echo "select AUTO_INCREMENT from TABLES where TABLE_NAME = '${LINE}';" | ${MYSQL_CMD_INFORMATION_SCHEMA} | grep -v "AUTO_INCREMENT"`
    #AUTO_INC_CNT=`echo "show create table ${LINE} \G" | ${MYSQL_CMD} | grep "ENGINE=" | awk '{print $3}' | cut -d "=" -f 2`
    echo "${LINE} ${AUTO_INC_CNT}" | tee -a ${LOG_DIR}/${LOG_PREFIX}_auto_inc.log
    sleep 0.1
  done < ${LOG_DIR}/table.list
  echo "############"
  echo "############"
  echo ""
}


##########################
# sync auto_increment
##########################

sync_auto_inc()
{
  echo "[Fix Auto_increment values]"
  while read TABLE_NAME
  do
     echo "-----" | tee -a ${LOG_DIR}/operation.log
     bf_cnt=`grep -w ${TABLE_NAME} ${LOG_DIR}/before_auto_inc.log | awk '{print $2}'`
     af_cnt=`grep -w ${TABLE_NAME} ${LOG_DIR}/after_auto_inc.log | awk '{print $2}'`
     echo ${TABLE_NAME} | tee -a ${LOG_DIR}/operation.log
     echo "before : ${bf_cnt}" | tee -a ${LOG_DIR}/operation.log
     echo "after  : ${af_cnt}" | tee -a ${LOG_DIR}/operation.log

     if [ ${bf_cnt} = "NULL" ]; then
       echo "-> Skipped because of NULL number" | tee -a ${LOG_DIR}/operation.log
     elif [ ${bf_cnt} -gt ${af_cnt} ]; then
       echo "-> Before is greater than After : ${bf_cnt}"  | tee -a ${LOG_DIR}/operation.log
       echo ""
       echo "ALTER TABLE ${TABLE_NAME} AUTO_INCREMENT = ${bf_cnt} ;" | ${MYSQL_CMD_VERBOSE} | tee -a ${LOG_DIR}/operation.log
       sleep 0.1
     elif [ ${bf_cnt} -lt ${af_cnt} ]; then
       echo "-> Skipped ALTER operation because After is greater than Before : ${af_cnt}"  | tee -a ${LOG_DIR}/operation.log
     elif [ ${bf_cnt} -eq ${af_cnt} ]; then
       echo "-> Skipped because of the Same number!" | tee -a ${LOG_DIR}/operation.log
     fi
     echo " " | tee -a ${LOG_DIR}/operation.log
  done < ${LOG_DIR}/table.list
  echo ""
  echo "############"
  echo "############"
  echo ""
}

###########################################################
# disable database permission to create the static point
###########################################################

disable_DB_permission()
{
  if [ -e ${LOG_DIR}/disable_permission.log ]; then
    \rm -if ${LOG_DIR}/disable_permission.log
  fi
  echo "[Permission Disable]"
  echo "update mysql.db set Db='tmp_${DB}' where Db='${DB}'; flush privileges;" | ${MYSQL_CMD_VERBOSE2} | tee -a ${LOG_DIR}/disable_permission.log
  echo " " | tee -a ${LOG_DIR}/disable_permission.log
  echo "############" | tee -a ${LOG_DIR}/disable_permission.log
  echo "############" | tee -a ${LOG_DIR}/disable_permission.log
  echo " " | tee -a ${LOG_DIR}/disable_permission.log
  echo "select Host,Db,User from mysql.db;" | ${MYSQL_CMD_VERBOSE} | tee -a ${LOG_DIR}/disable_permission.log
  echo ""
  echo ""
}

###########################################################
# Enable database permission to create the static point
###########################################################

enable_DB_permission()
{
  if [ -e ${LOG_DIR}/enable_permission.log ]; then
    \rm -if ${LOG_DIR}/enable_permission.log
  fi
  echo "[Permission Enable]"
  echo "update mysql.db set Db='${DB}' where Db='tmp_${DB}'; flush privileges;" | ${MYSQL_CMD_VERBOSE2} | tee -a ${LOG_DIR}/enable_permission.log
  echo " " | tee -a ${LOG_DIR}/enable_permission.log
  echo "############" | tee -a ${LOG_DIR}/enable_permission.log
  echo "############" | tee -a ${LOG_DIR}/enable_permission.log
  echo " " | tee -a ${LOG_DIR}/enable_permission.log
  echo "select Host,Db,User from mysql.db;" | ${MYSQL_CMD_VERBOSE} | tee -a ${LOG_DIR}/enable_permission.log
  echo ""
  echo ""
  echo "[diff]"
  diff -s ${LOG_DIR}/disable_permission.log ${LOG_DIR}/enable_permission.log | tee ${LOG_DIR}/diff.log
}




############
# main
############
case ${OPT} in
  'bf')
        LOG_PREFIX="before"
        if [ -e ${LOG_DIR}/table.list ]; then
          \rm -if ${LOG_DIR}/table.list
        fi
        disable_DB_permission
        chk_schema
        ;;
  'af')
        LOG_PREFIX="after"
        if [ -e ${LOG_DIR}/operation.log ]; then
          \rm -if ${LOG_DIR}/operation.log
        fi
        chk_schema
        sync_auto_inc
        enable_DB_permission
        ;;
  'disable')
        disable_DB_permission
        ;;
  'enable')
        enable_DB_permission
        ;;
esac

exit 0
