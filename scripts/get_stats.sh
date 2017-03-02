#!/bin/bash

#	Скрипт для утренней проверки 

#Загрузка сурсов с пасами и ip
source ~/Документы/scr/source/data.cfg
source ~/Документы/scr/source/bash_source_color.cfg
today_dir="/home/as/var/log/mylog/morning_test/$(date +%F)/"
work_time=43200

if ! test -d $today_dir
	then 
	mkdir -p $today_dir
fi


# Ручные проверки.
echo -e $BGreen
${CBMYSQLBaseConnect} -e "select f435 as project,f8360 as date , cb_users.fio as Ответственность \
from cb_data42 projects inner join cb_users ON (projects.f8650=cb_users.id) \
where f8650 not in (0,31) and f8360 > DATE_SUB(now(),interval 90 day) order by f8360;" ##>> $today_dir/check_check.log
echo -e $Color_Off


for user_id in 87 91 93 95 96

do

	case $user_id in
		87) echo -e $BRed"n.bersan"$Color_Off ;; #>> $today_dir/check_check.log ;;
		91) echo -e $BRed"a.pavlova"$Color_Off ;; #>> $today_dir/check_check.log ;;
		93)	echo -e $BRed"t.garaev"$Color_Off ;; #>> $today_dir/check_check.log ;;
		95) echo -e $BRed"n.pikhovkin"$Color_Off ;; #>> $today_dir/check_check.log ;;
		96)	echo -e $BRed"r.leontyev"$Color_Off ;; #>> $today_dir/check_check.log ;;
	esac
	# проверка действий
	rq_1="select bht.bug_id, bht.field_name, bht.old_value,bht.new_value, FROM_UNIXTIME(bht.date_modified), mct.name as 'Category',mbt.status,mbt.summary as time \
	from mantis_bug_history_table bht INNER JOIN mantis_bug_table mbt ON (bht.bug_id=mbt.id) INNER JOIN mantis_category_table mct ON (mbt.category_id=mct.id) \
	where bht.user_id=${user_id} and bht.field_name<>'' and bht.date_modified > UNIX_TIMESTAMP()-${work_time} order by bht.date_modified desc  limit 100;"
# Проверка комментов
	rq_2="select bht.bug_id, FROM_UNIXTIME(bht.date_modified) as 'Date', mct.name as 'Category',mbt.status,mbt.summary as 'Name', mbtt.note as 'Comment' from \
mantis_bug_history_table bht INNER JOIN mantis_bug_table mbt ON (bht.bug_id=mbt.id) INNER JOIN mantis_category_table mct ON (mbt.category_id=mct.id) INNER JOIN mantis_bugnote_text_table mbtt ON (bht.old_value=mbtt.id) \
where bht.user_id='${user_id}' and bht.type=2 and bht.date_modified > UNIX_TIMESTAMP()-${work_time} order by bht.date_modified desc  limit 100;"

#echo $rq_1 
#echo $rq_2
	# проверка действий
	${MantisMYSQLBaseConnect} -e "$rq_1" 2>/dev/null | awk '{print $1}' | sort -u | echo -e "Всего действий с тасками: "$UWhite""$BWhite"`grep -E [[:digit:]]{6} -c`"$Color_Off" " #>> $today_dir/check_check.log 
	# Проверка комментов
	${MantisMYSQLBaseConnect} -e "$rq_2"  2>/dev/null #>> $today_dir/check_check.log 
done
#cat $today_dir/check_check.log

exit 0 