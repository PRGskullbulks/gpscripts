#!/bin/bash


NAME="Default"

if test "$1" != ""
then 
	NAME=$1
fi

#Username of the ftp account 
FTPUSER="foo"

#Password of the ftp account
FTPPASSWORD="bar"

#Host of the ftp account
FTPHOST="ftp.com"


#General vars
DATE_DAY=`date +%Y%m%d`
DATE_TIME=`date +%H%M`
HOSTNAME=`hostname`
HOSTIP=``
LOGFOLDER="$CLIENTNAME-$HOSTNAME-$HOSTIP-$DATE_DAY-$DATE_TIME"

ALL_LOG_FILES="*"$HOSTNAME"-"$HOSTIP"*"

rm -rf  $ALL_LOG_FILES

rm -rf $LOGFOLDER
cd /root

mkdir $LOGFOLDER

cd $LOGFOLDER

cp /usr/local/etc/openser/openser.cfg .

# Copy of configuration files
cp -ra /etc/asterisk/ .

echo "copying verbose file"
cp /var/log/asterisk/verbose .

echo "copying debug file"
cp /var/log/asterisk/debug .

echo "copying verbose file"
cp /var/log/asterisk/notice .

echo "copying warning file"
cp /var/log/asterisk/warning .

echo "copying error file"
cp /var/log/asterisk/error .

echo "copying messages file"
cp /var/log/asterisk/messages .

cd /root

zip -r $LOGFOLDER".zip" $LOGFOLDER

lftp -u $FTPUSER,$FTPPASSWORD -e "bin;put $LOGFOLDER.zip;quit" $FTPHOST

rm -rf $LOGFOLDER



