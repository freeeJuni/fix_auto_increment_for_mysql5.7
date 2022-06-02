# fix_auto_increment_for_mysql5.7
it is the fixing script for auto_increment number after rebooting with MySQL 5.7 !!  
and conducting permission disable / enable as well

### summary
```
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
```

### help
```
sh sync.sh -help|help

```

### execute
#### before DB reboot
```
./for_mysql57_reboot.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} bf
```
#### after DB reboot
```
./for_mysql57_reboot.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} af
```
#### permission disable
```
./for_mysql57_reboot.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} disable
```
#### permission enable
```
./for_mysql57_reboot.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} enable
```
