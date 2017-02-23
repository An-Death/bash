#!/bin/bash
# Скрипт добавляет/удаляет текущего юзера в группу nopassswdlogn
source /home/as/Документы/scr/.bash_source_color.cfg


if ( id as | grep -o nopasswdlogin > /dev/null ) || [[ $(date) > $(date -d 18:40) ]] 
	then
		if [[ $(date) > $(date -d 18:44) ]]
			then
				echo -e "$BBlue"`date`"$Color_Off" "$BRed"`/usr/sbin/deluser as nopasswdlogin`"$Color_Off" 
			else
				echo -e "$BRed""[FAIL] Ошибка выполнения скрипта. Запуск контроля не должен происходить ранее 18:45!""$Color_Off" && exit 1
		fi
	else
		if [[ $(date) > $(date -d 07:44) ]]
			then
				echo -e "$BBlue"`date`"$Color_Off" "$BGreen"`/usr/sbin/adduser as nopasswdlogin`"$Color_Off"  
			else
				echo -e "$BGreen""[FAIL] Ошибка выполнения скрипта. Отмена контроля не должна происходить ранее 07:45!""$Color_Off" && exit 1
			fi
fi 
