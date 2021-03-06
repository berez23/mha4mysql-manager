. ./init.sh

# Can't recover S3 due to lacking relay logs

mysql $S1 -e "set global max_binlog_size=8192"
mysql $S2 -e "set global max_binlog_size=8192"
mysql $S3 -e "set global max_binlog_size=8192"
mysql $S4 -e "set global max_binlog_size=8192"

perl insert.pl $MP $MYSQL_USER $MYSQL_PWD 2 1000 0

mysql $S3 test -e "stop slave io_thread"

perl insert.pl $MP $MYSQL_USER $MYSQL_PWD 1001 3000 0

./run_bg.sh --conf=$CONF_IGNORE
wait_until_manager_start $0 --conf=$CONF_IGNORE
sleep 30
./kill_m.sh
sleep 100

mysql $S1 test -e "insert into t1 values(10000003, 300, 'bbbaaaaaaa');"

is_gtid_supported
if test $? = 1
then
  ./check $0 3001 "h=127.0.0.1,P=$S1P  h=127.0.0.1,P=$S2P h=127.0.0.1,P=$S3P h=127.0.0.1,P=$S4P"
else
  check_master $0 $S3P $MP
  ./check $0 3001 "h=127.0.0.1,P=$S1P  h=127.0.0.1,P=$S2P h=127.0.0.1,P=$S4P"
fi


