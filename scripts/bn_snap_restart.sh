#!/bin/bash


source ~/Документы/scr/source/bash_source_color.cfg
source ~/Документы/scr/source/data.cfg

#Скрипт для переодического обновления камер на БКЕ, пока не исправили багу


  mysql_connect_to_database="mysql $sql_bn_connect -A"  
  connect_to_server_ssh="sshpass -p $pass_bn_serv ssh -o StrictHostKeyChecking=no $host_bn_serv"
  request="select ww.health_address from WITS_WELL ww inner join WITS_WELLBORE wb on (ww.id=wb.well_id) inner join WITS_SOURCE ws on (ws.id=ww.source_id) inner join WITS_WELL_PROP wp on (wb.well_id=wp.well_id and wp.status_id=3 and wb.status_id=3) ;"
#для ребута по порту
  ports=$($mysql_connect_to_database -e "$request" 2>/dev/null |grep -o -E :[0-9]{4} | tr -d  ':' ) 
# Для ребута царичан.
  health_address=$($mysql_connect_to_database -e "$request"	2>/dev/null	| grep 172.28 | sed 's/http:\/\///' )
  $connect_to_server_ssh 'for f in '$ports' ; do curl http://127.0.0.1:${f}/axis?snapshots=on > /dev/null 2>&1 && echo  "$f - OK" || echo "$f - FAIL" ; done & for health in  '$health_address' ; do  curl http://${health}/axis?snapshots=on > /dev/null 2>&1 && echo  "$health - OK" || echo "$health - FAIL" ; done &'

# Для ребута царичан.

  #$connect_to_server_ssh 'for health in  '$health_address' ; do  curl http://${health}/axis?snapshots=on > /dev/null 2>&1 && echo  "$health - OK" || echo "$health - FAIL" ; done'