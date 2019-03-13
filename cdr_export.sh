#!/bin/bash

# Usage:
# cdr_export.sh <months_per_table>
#      months_per_table      number of months to store in each history table
#
# Can be used with crontab to schedule an automatic monthly export, example add the following to root crontab:
# 0 0 1 1,4,7,10 * /path/to/cdr_export.sh
#
# This script creates a new database to store historical CDR registers. Inside this new database 
# the CDR history will be stored in new tables with name cdr_YYYY_mm_MM (where mm is the start month,
# MM is the end month of the range, YYYY is the year of the first registry stored)
# By default each table will contain 3 months of CDR records, check usage to specify another value.
# Last historic period will not be exported, will remain on the original asterisk database.

MONTHSTEP=3
HISTORYDBNAME="cdrhistory"

if [ $# -eq 1 ]; then
  MONTHSTEP=$1
fi
if [ $# -gt 1 ]; then
  echo "Usage: "`basename $0`" <months_per_table>"
  exit 1;
fi  


#create history database if not exists
mysql -ppresence240 -uroot -bse "CREATE DATABASE IF NOT EXISTS $HISTORYDBNAME"

#clean previous temp files
if ls /tmp/cdrexport.*.sql &>/dev/null; then
  rm /tmp/cdrexport.*.sql 
fi
#select by monthstep and dump to files
#start_month=`mysql -ppresence240 -uroot asterisk -bse "SELECT SUBSTRING(crdpk,1,6) from pogpcdr limit 1;" | cut -c5-6`
start_month=1
start_year=`mysql -ppresence240 -uroot asterisk -bse "SELECT SUBSTRING(crdpk,1,6) from pogpcdr limit 1;" | cut -c1-4`
end_month=`date +%m`
end_year=`date +%Y`
for (( year=$start_year; year<=$end_year; year++ )); do
  for (( month=$start_month; month<=12; month=$month+$MONTHSTEP )); do
    if [[ "$year" == "$end_year" ]]; then
      if [ $(($month+$MONTHSTEP-1)) -ge $end_month ]; then
        break;
      fi
    fi
    querySTR=""
    for (( m=$month; m<=$(($month+$MONTHSTEP-1)); m++ )); do
      ymstr=`printf "%04d%02d" $year $m` 
      if [[ "$querySTR" == "" ]]; then        
        querySTR="$querySTR crdpk LIKE '$ymstr%'"
      else
        querySTR="$querySTR OR crdpk LIKE '$ymstr%'"
      fi
    done
    #export    
    ymstr=`printf "%04d.%02d.%02d" $year $month $(($month+$MONTHSTEP))` 
    ymstr_short=`printf "%04d_%02d_%02d" $year $month $(($month+$MONTHSTEP))`
    if [ `mysql -ppresence240 -uroot asterisk -bse "SELECT COUNT(*) FROM pogpcdr WHERE $querySTR"` -ne 0 ]; then
      echo "Exporting CDR from $year/$month to $year/"$(($month+$MONTHSTEP-1))" into file /tmp/cdrexport.$ymstr.sql"
      mysqldump --password=presence240 -uroot asterisk pogpcdr --skip-add-drop-table --where="$querySTR" | sed -e "s/\`pogpcdr\`/cdr$ymstr_short/g" > /tmp/cdrexport.$ymstr.sql
    fi
  done
done
#import dump to the history db
if ls /tmp/cdrexport.*.sql &>/dev/null; then
  for cdrfile in `ls /tmp/cdrexport.*.sql`; do
    echo "Import to $HISTORYDBNAME database $cdrfile"
    monthstart=`echo $cdrfile | cut -d. -f 3`
    monthend=`echo $cdrfile | cut -d. -f 4`; 
    year=`echo $cdrfile | cut -d. -f 2`
    if mysql -ppresence240 -uroot $HISTORYDBNAME < $cdrfile; then      
      #if ok delete from original DB
      echo "CDR from $year/$monthstart to $year/$monthend correctly imported, removing from asterisk DB"
      querySTR=""
      for (( m=${monthstart#0}; m<=(${monthend#0}-1); m++ )); do
        ymstr=`printf "%04d%02d" $year $m` 
        if [[ "$querySTR" == "" ]]; then        
          querySTR="$querySTR crdpk LIKE '$ymstr%'"
        else
          querySTR="$querySTR OR crdpk LIKE '$ymstr%'"
        fi
      done
      echo "--Executing : DELETE FROM pogpcdr WHERE $querySTR"
      mysql -ppresence240 asterisk -e "DELETE FROM pogpcdr WHERE $querySTR"
      rm $cdrfile
    else
      echo "Error importing $cdrfile"
    fi
  done
  mysql -ppresence240 asterisk -e "optimize table pogpcdr"
fi

