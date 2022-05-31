# fix_auto_increment_for_mysql5.7
fix_auto_increment_for_mysql5.7

### summary
```
before DB reboot,
  - disable DB permission
  - get schema information including auto_increment value

after DB reboot,
  - check auto_increment difference
  - fix auto_increment values
  - enable DB permission 
```

### help
```
sh sync.sh -help|help

```

### execute
#### before DB reboot
```
sh sync.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} bf
```
#### after DB reboot
```
sh sync.sh -h ${HOST} -u ${USER} -p ${PASSWORD} -P 3306 -d ${DB_NAME} af
```
