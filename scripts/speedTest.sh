#!/bin/bash

	if  ! [ -d /tmp/speedTest/ ]
		then 
		mkdir -v /tmp/speedTest/
	fi
	if ! [ -f ~/tools/speedTest.jar ] || [ -f ./speedTest.jar ] || [ -f /tmp/speedTest.jar ]
	then 
		echo " Отсутствует speedTest.jar. Хотите загрузить? (д/н): " && read _choose 
		 case $_choose in
			Y|y|д|Д) location=$(whoami) 
				if [ $location = "gtionline" ] || [ $location = "tetrasoft" ]
					then
						echo "Вы не в локальной сети ТетраСофт. Выходим." exit 1
					else
						echo "Введи пасс от support" && rsync -azvP support@192.169.0.100:bin/support_stash//speedTest.jar ./
					fi;;
			n|N|Н|н) "Выходим." exit 1 ;;
		esac
	fi
		

gbox_select () {

	select $listen in gbox-123 gbox-33 gbox-176 gbox-174 gbox-136 gbox-50 gbox-143 gbox-29
	do
	gbox-123) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-123 
	gbox-33) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-33
	gbox-176) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-176
	gbox-136)  timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-136
	gbox-50) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-50
	gbox-143) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-143
	gbox-29) timeout 180 java -jar speedTest.jar > /tmp/speedTest/gbox-29
	done
			
	}
	
listen () {
	  i=0
    until ! [ -z $h_name ] ; do
      timeout 30 nc -l -p 3333 > /tmp/gbox-03 & 
    sshpass -p $pass_for_g ssh ts@gbox-$1 'sleep 5 && echo `hostname` | nc 192.168.0.135 3333' || sleep 7 && let 'i=i+1'
    h_name=$(cat /tmp/gbox-03)
    if [ $i -eq 15 ]
    then 
     break
    fi
  done
}

connect_to_box_from_home () {
	if sshpass -p "$GATE_PASS" ssh -l support 192.168.0.100 'nc -z localhost 22'$1''
		then sshpass -p "$GATE_PASS" ssh -l support 192.168.0.100 'nc -z localhost 22'$1' ""'
}
connect_to_box_from_server () {
	i=0
	while ! nc -l -k -p 3333 
	do sshpass -p $pass_for_g ssh ts@$1 'echo `hostname` | nc 192.168.0.5 3333' && sleep 15 && let 'i=i+1'
		if [ $i -eq 15 ]
		then 
		 echo "stop"
		 break
		fi
	done
}

while true
do




	}

	gbox_select $listen 
done


	func_select_test () {

  PS3='Выберите ваш любимый овощ: '

echo

choice_of()
{
select vegetable
# список выбора [in list] отсутствует, поэтому 'select' использует входные аргументы функции.
do
  echo
  echo "Вы предпочитаете $vegetable."
  echo ";-))"
  echo
  break
done
}

choice_of бобы рис морковь редис томат шпинат
#         $1   $2  $3      $4    $5    $6
#         передача списка выбора в функцию choice_of()