#! /bin/bash -x

TOMORROW=$(date -d '+1 day' +'%Y%m%d')
TODAY=$(date  +'%Y%m%d')
MYSQL='/usr/bin/mysql -uroot -p'

$MYSQL homer_data -e "CREATE TABLE IF NOT EXISTS isup_capture_all_$TOMORROW like isup_capture_all_$TODAY"
$MYSQL homer_data -e "CREATE TABLE IF NOT EXISTS sip_capture_call_$TOMORROW like sip_capture_call_$TODAY"
$MYSQL homer_data -e "CREATE TABLE IF NOT EXISTS sip_capture_registration_$TOMORROW like sip_capture_registration_$TODAY"
$MYSQL homer_data -e "CREATE TABLE IF NOT EXISTS sip_capture_rest_$TOMORROW like sip_capture_rest_$TODAY"
$MYSQL homer_data -e "CREATE TABLE IF NOT EXISTS webrtc_webrtc_capture_all_$TOMORROW like webrtc_webrtc_capture_all_$TODAY"

exit $?
