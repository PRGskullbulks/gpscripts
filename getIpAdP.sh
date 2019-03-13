#! /bin/sh

LOGFILE=/var/log/kamailio.log
MODE=kamailio
AGENTDIR='/etc/zabbix/zabbix_agentd.conf.d'
USRPAMFILE='PingtoKamExtIp'
TMPFILE="/tmp/sort"$$
mkdir -p $AGENTDIR
echo "generating ip address in"$AGENTDIR/$USRPAMFILE
tac $LOGFILE | awk '/REGISTER request/ {gsub(/@.*/,"",$16); print $16 " " $13}' |sort -u | awk '!seen[$1]++ { print "UserParameter=PingExt_"$1 ",/usr/bin/pingto "$2}' > $AGENTDIR/$USRPAMFILE
cat $AGENTDIR/$USRPAMFILE

exit 0
