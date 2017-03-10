#!/bin/bash


source ~/Документы/scr/source/bash_source_color.cfg
source ~/Документы/scr/source/data.cfg

#Скрипт для переодического обновления камер на БКЕ, пока не исправили багу


  mysql_connect_to_database="mysql $sql_bn_connect -A"
  connect_to_server_ssh="sshpass -p $pass_bn_serv ssh -o StrictHostKeyChecking=no $host_bn_serv"
  request="select ww.name, wb.status_id, ws.product_key, ws.health_address from WITS_WELL ww inner join WITS_WELLBORE wb on (ww.id=wb.well_id) inner join WITS_SOURCE ws on (ws.id=ww.source_id) inner join WITS_WELL_PROP wp on (wb.well_id=wp.well_id and wp.status_id=3 and wb.status_id=3) ;"
  ports=$($mysql_connect_to_database -e "$request" |grep -o -E :[0-9]{4} | tr -d  ':')
  
  $connect_to_server_ssh 'for f in '$ports' ; do curl http://127.0.0.1:$f/axis?snapshots=on > /dev/null 2>&1 && echo  "$f - OK" || echo "$f - FAIL" ; done'