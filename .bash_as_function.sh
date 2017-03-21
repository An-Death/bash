
#Подключение цветов
source ~/Документы/scr/source/bash_source_color.cfg
source ~/Документы/scr/source/data.cfg

readonly SETCOLOR_SUCCESS="echo -en $BGreen"
readonly SETCOLOR_FAILURE="echo -en $BRed"
readonly SETCOLOR_NORMAL="echo -en $Color_Off"
readonly SETCOLOR_BLUE="echo -en $BBlue"
readonly SETCOLOR_CYAN="echo -en $BCyan"
readonly SETCOLOR_RED="echo -en $Red"


#Скрипт определения времени
now () {
variable_check $*
case $1 in

  esac
local i=$(date)
local d=$(date -d $1)
 echo $i $d
 if [[ $i < $d ]]
  then
  echo "true"
else 
  echo "false"
fi
}

#Выводит ОК Fail
color_check () {

  if [ $? -eq 0 ]; then
    $SETCOLOR_SUCCESS
    echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
    $SETCOLOR_NORMAL
    echo
  else
    $SETCOLOR_FAILURE
    echo -n "$(tput hpa $(tput cols))$(tput cub 6)[fail]"
    $SETCOLOR_NORMAL
    echo
  fi
}
variable_check () {

  if [ -z "$1" ]
   then
     echo "-Аргумент #1 не был передан функции."
     return 1;
   fi
}
variable_check_digit () {

  if ! echo "${1}" | grep -q -E '^[[:digit:]]+$'
    then
      echo "Необходимо ввести целочисленное значение!"
      return 1
  else 
    return 0    
  fi
}

#Синк  на бокс
function rsync_b  () {
 
#переменные функции

    local path=gbox-$1:$3
    local f=$(basename "$2")
#
#проверка наличия необходимых переменных функции
   if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ]
    then 
     echo "Usage: 
#1 - номер бокса, #2 - фаил, #3 - куда на боксе"
     return 1
   fi
   if ! [ -f "$2" ] || [ -d "$2" ]
    then
      ${SETCOLOR_FAILURE}
      echo "$2 такого файла или каталога не существует!"
      ${SETCOLOR_NORMAL}
      return 1
    fi
#
${SETCOLOR_CYAN}
  echo "
Copy file $f to $path
"
${SETCOLOR_NORMAL}


  pass_g $1 >/dev/null
    
  rsync -azuvP "$2" --rsh="sshpass -p "$pass_for_g" ssh -l ts " $path/

  color_check
}
#функция для подключения к боксам
func_connect_to () {
   
  case $_func_name in 
    g)  case $connection in 
        box)  get_server_use_gbox_conf  $gnum $vpn_selector
              echo -e "$ssh_descript" && sshpass -p $pass_for_g ssh -l ts -o StrictHostKeyChecking=no -t $box_adr $ssh_command ;;
        #if [ -z $vpn_selector ] #|| [ $vpn_selector -eq 1 ]
        #  then 
        #    echo -e "$ssh_descript" && sshpass -p $pass_for_g ssh -l ts -o StrictHostKeyChecking=no -t $box_adr $ssh_command
        #else
        #  get_server_use_gbox_conf  $gnum $vpn_selector || return 2
        #  #"$GBOX_VPN" не возвращается, надо думать как вернуть.  
        #  echo -e "Заходим на gbox-$gnum\nСкважина $(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\nЗаходим по ip $GBOX_VPN" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no "${GBOX_VPN}" $ssh_command
        #fi
        g100) sshpass -p ${GATE_PASS} ssh support@192.168.0.100 $ssh_command ;;
        esac ;;
    gping) echo -e "$BWhite""Подключаемся к удалённому серверу...""$Color_Off" && pass_g $gbox_num && sshpass -p $pass_for_g ssh -l ts gbox-$gbox_num $do_command ;;
  esac


}



# копия Макса с лобавленной возможностью ввода 3й переменной для отправки команды на бокс по ssh
# для отправки команды всегда необходимо указывать 3и переменных, где 1 - номер бокса, 2 - номер коннекта, 3 - комманда в ковычках.
function g () {

_func_name="g"
local gnum=
local box_adr=
#проверка наличия переменных
  variable_check $*

#проверка первой переменной на digit или ip или gbox для g
func_check_digit () {

  if `echo $1 | grep  -m 1 -qE "[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"`
  then
    gnum=`nmblookup -A $1| grep -m 1 -oE "GBOX-[[:digit:]]{2,4}" | grep -oE "[[:digit:]]{2,4}"` ||  (echo "По указанному ip находится не GBOX" 1>&2 ; return 1 )
    box_adr="$1"
  else
    if [[ "${#1}" -lt 2 ]]
      then
        gnum="0${1}"
      else 
        gnum="$1"
    fi
    box_adr="gbox-$gnum"
  fi
  pass_g $gnum;
}

func_ping () {
  while true ; do 
  ping -c 1 gbox-$gnum >/dev/null 2>&1 && break 
  done
  notify-send "GBOX-$gnum OK" "gbox-$gnum доступен. \n PING OFF" && return 0 
}


  func_check_cases () {
    #обнуление переменных
    path_g100_boxer=""

    case $1 in
    #connect restart
    cr) _command="restart"; cn="$2" ;;
    #connect_stop
    cstop) _command="stop" ; case $2 in
      --all|-a|a|all|"") cn="" ;;
      ^[1-9]{1}$) cn="$2" ;;
      *) cn="" ;;
      esac ;; 
    #connect_start
    cstart) _command="start" ; case $2 in
      --all|-a|a|all ) cn="all";;
      ^[1-9]{1}$) cn="$2" ;;
      esac ;;  
    #connect count
    cc) _command="count" ;; 
    #send to server ip & port
    cs) _command="server_ip"; cn="$2" ;; 
    #connect info
    ci) _command="info"; cn="$2" ;; 
    #connect logs
    cl) _command="log"; cn="$2"; what_log="$3" ;;  
    #send command
    sc|send|--send) _command="exec" ; command_is=(`echo -n "$2"`) ;;  
    #check list
    ckl) _command="check_list" ;; 
    #copy from gbox
    gc) _command="copy"; cn="$2" ;;
    #copy from boxer
    bc) _command="copy_boxer" ; cn="$2" ;;
    #gbox back config + restart connect
    gb) _command="box_back" ; cn="$2" ;;
    #open any configs
    oc) _command="subl" ; config="$2" ;;
    #head version admin & connect
    ver|v|version)  if [[ "$2" = "box" ]] ; then _command="version_box" ; else _command="version" && path_g100_boxer="/home/support/bin/boxer/gbox-$gnum/home/ts/" ; fi ;;
    #updater
    update) _command="update" ;;
    #admin open
    admin) _command="admin_open" ;;
    #подключение к боксу по тунелю
    tun) _command="tun";;
    #проверка базы сборщика, или подключение к локальной базе
    mys) case $2 in 
          sbor) _command="mys_sbor" ;echo -n "Введите номер коннекта:" && read cn
                if [ $cn -eq 1 ] ; then cn= ; fi ;;
          local) _command="mys_local" ;;
        esac
    ;;
    ping) _command="ping" ;;
    h|-h|--h|help|-help|--help) _command="101" ;;
    #отправка непосредственно комманды
    *) _command="exec" ; command_is="$1";;
esac
}

#  if [ -z "$3" ] 
#    then 
#      if [ -z "$2" ] 
#        then
#          echo -e "Заходим на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no -t "${box_adr}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${box_adr}" " >> "/home/ts/backup/tools/logins.log" ; cat /etc/motd; bash -l;"
#        else
#          get_server_use_gbox_conf  $gnum $2|| return 2
#          echo -e "Заходим на gbox-$gnum\nСкважина $(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\nЗаходим по ip $GBOX_VPN" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no "${GBOX_VPN}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${GBOX_VPN}" " >> "/home/ts/backup/tools/logins.log" ; cat /etc/motd; bash -l;"
#      fi
#    else 
#      if [ "$2" -eq "1" ]
#        then
#          echo -e "Отправляем команду - ${COLOR_RED}"$3"${COLOR_NORMAL} на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no -t "${box_adr}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${box_adr}" executed : "$3" " >> "/home/ts/backup/tools/logins.log" && "${3}""
#        else
#          get_server_use_gbox_conf  $gnum $2|| return 2
#          echo -e "Отправляем команду - ${COLOR_RED}"$3"${COLOR_NORMAL} на gbox-$gnum\nСкважина $(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\nЗаходим по ip ${GBOX_VPN}" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no "${GBOX_VPN}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${GBOX_VPN}" executed : "$3" " >> "/home/ts/backup/tools/logins.log" && "${3}""
#      fi
#  fi

if [[ $1 = 'h' || $1 = '-h' || $1 = 'help' || $1 = '--help' ]]
  then
  _command="101"
else
  func_check_digit $1 >/dev/null #returned $gnum $box_adr
fi
if [ -z $2 ]
  then
  _command="ssh"
elif ( [[ "$2" -eq 1 ]] )
  then
  _command="ssh"
elif ( [[ "$2" =~ ^[2-9]{1}$ ]] )
  then
    _command="ssh"
    vpn_selector=(`echo -n "$2"`)
    cn=$2
else
  func_check_cases "$2" "$3" $4 $5
fi


ssh_descript="Заходим на ${COLOR_BLUE}gbox-$gnum\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS:\n$(nslookup gbox-$gnum) \n" 
ssh_command_default="[ -d /home/ts/backup/tools ] && echo `date` `whoami` from `hostname` and use $box_adr  >> /home/ts/backup/tools/logins.log ; cat /etc/motd; cd connect$cn/ ; bash -l;"
ssh_command_row=""
#отправка команды на прямую
ssh_descript_exec="Отправляем команду - ${COLOR_RED}$command_is${COLOR_NORMAL} на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})"
ssh_command_exec="[ -d /home/ts/backup/tools ] && echo `date` `whoami` from `hostname` and use $box_adr executed : $command_is >> /home/ts/backup/tools/logins.log && $command_is"
#чек версий админки и коннекта из боксера
ssh_command_version="echo -e '${BBlue}Admin VERSION:${Color_Off} \n' ; head -1 ${path_g100_boxer}admin/version ; echo -e '\n${BBlue}Connect VERSION:${Color_Off}\n' ; head -3 ${path_g100_boxer}connect/version ; echo"
#подключение к боксу через тунель
ssh_command_tun="echo -e 'Подключаемся к gbox-$gnum' && sshpass -p $pass_for_g ssh ts@localhost -p 22$gnum " # Не возврщает нормом bash

case $_command in
  check_list|info|count|update|tun|version) connection="g100" ;;
  *) connection="box" ;;
esac

case $_command in
ssh) ssh_command=$ssh_command_default ;;
restart) ;;
stop) ;;
start) ;;
count) ;;
server_ip) ;;
info) ;;
log) ;;
send_command) ;;
check_list) ;;
copy) ;;
box_back) ;;
subl) ;;
update) ;;
admin_open) google-chrome "http://gbox-$gnum/" && return 1 ;;
tun) ssh_command=$ssh_command_tun ;;
interfaces) ;; 
mys_sbor) ;;
mus_local) ;;
version) ssh_command=$ssh_command_version ;;
version_box) ssh_command=$ssh_command_version ;; #head версий с бокса
exec) ssh_descript=$ssh_descript_exec ; ssh_command=$ssh_command_exec ;;
101) func_help $_func_name ;;
ping) func_ping $gnum & return 1 ;;
esac  

func_connect_to $ssh_command

  local error_num="$?"
  case "$error_num" in
    0) notify-send "GBOX-$gnum OK" "Соединение с gbox-$gnum завершено";;
    5) notify-send "GBOX-$gnum ERROR"  "Неправильный логин/пароль gbox-$gnum";;
    128|130) notify-send "GBOX-$gnum" "Соединение с gbox-$gnum прервано. \n EXIT" ;;
    255) notify-send "GBOX-$gnum ERROR" "Ошибка при копировании настроек с gbox-$gnum connect$connect_num";;
    1) return 0 ;;
    *) echo "New error $error_num" ;;
  esac


}

## пинг бокса, пинг сборщика,пинг камер.

function gping () {
  # переменные
  _func_name="gping"
  gbox_num=$1
  local choose=
  local cn=
  local cam_num=
  local grep_cam=
  local stay=
  
  func_do_command_unterpritator () {

  #Переменная для определения имени скв из connect.conf
    local well_name="grep '^well=' ~/connect'"$cn"'/connect.conf | sed 's/wel.*=//;s/\ /_/g'"  
  #добавление ip moxa в connect.conf
    local add_moxa_ip="if ( grep -o -E '.*moxa_ip.*([0-9]{1,3}[\.]){3}[0-9]{1,3}.*' connect'"$cn"'/connect.conf ) ; then echo 'moxa_ip already exist' ; else sed '0,/.*bind_port.*/{s/.*bind_port.*/&\n\nmoxa_ip=$ipMOXA/}' -i connect'"$cn"'/connect.conf ; fi"
  #переменные для составления запроса
    local sborshik_ping='echo -e "\e[0;1m""Определяем плагин и IP сборщика...""\e[0m"; readlink connect'"$cn"'/plugin/Proxy.jar |basename `cat ` |grep -i `sed "s/Proxy.jar//"` connect'"$cn"'/connect.conf|nc -vv `grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` 445 '
    local cameras_ping='echo -e "\e[34;1m"connect'"$cn"'/ "\e[0m""\n"; grep -E -o "^camera.*stream.*([0-9]{1,3}[\.]){3}[0-9]{1,3}" ~/connect'"$cn"'/connect.conf $grep_cam | for f in `grep -vE "recorder"`; do echo -e "\e[32;1m"$f "\e[0m" && echo $f | ping -c 3 `grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` ; done; echo "done"' 
    local moxa_ping='echo -e $BWhilte connect'"$cn"'/ $Color_Off "\n" ; if ( grep -m 1 moxa_ip ~/connect'"$cn"'/connect.conf | grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}" >/dev/null ); then echo "MOXA: " ; ping -c 7 `grep -m 1 moxa_ip connect'"$cn"'/connect.conf | grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` ; else echo `'"$well_name"'` ; moxa_log_file=$(ls -t connect'"$cn"'/log/ | grep `'"$well_name"'` | head -1) ; if [ -z $moxa_log_file ] ; then echo -e "Ошибка программы!""\n""Вероятно файла с логами MOXA не существует." ; else  ipMOXA=$(grep -a Connection connect'"$cn"'/log/$moxa_log_file  | tail -2 |grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"); '"$add_moxa_ip"' ; echo "MOXA: "; ping $ipMOXA ; fi; fi '
    local do_command=
    
#вызывается функция для подключения к боксам в неё передаётся имя скрипта и команда.
    case $choose in
      row) gping_row $gbox_num ;;
      sborshik) do_command=$sborshik_ping ; func_connect_to $do_command  ;;
      camera) do_command=$cameras_ping ; func_connect_to $do_command  ;;
      moxa) do_command=$moxa_ping ; func_connect_to $do_command  ;;
      101) func_help $_func_name ;;
    esac


  }

  # проверка ввода

    while [ 1 ]
      do
        if [ -z $1 ]
          then
            echo "-Аргумент #1 не был передан функции."
            return 1;
        elif [ $1 = "h" ] || [ $1 = "help" ] || [ $1 = "-h" ] || [ $1 = "--help" ] || [[ $gbox_num =~ ^[^0-9]{1,3}$ ]]
          then
            choose=101
            break
        elif [ -z $2 ] 
          then
          choose=row
          break
        else
          case "$2" in
              sbor|s) choose=sborshik
                      if [ -z $3 ]
                        then 
                        cn=  
                      elif [ $3 = "-c" ] || [ $3 = 'cn' ]
                        then
                          if [ -z $4 ]
                            then
                              echo "Введите номер коннекта" ; read cn
                            else
                              cn=$4
                          fi
                      elif [[ $3 =~ ^[0-9]{1}$ ]]
                        then
                        cn=$3
                      fi
                      break ;;   
              cam|c) choose=camera
                      if [ -z $3 ]
                        then
                          cn=
                      elif [ $3 = "-c" ] || [ $3 = 'cn' ]
                        then
                          if [ -z $4 ]
                            then
                              echo "Введите номер коннекта" ; read cn
                            else
                              cn=$4
                          fi    
                      elif [[ $3 =~ ^[0-9]{1}$ ]]
                        then
                        cn=$3
                      fi
                      break ;; 
              moxa|mox|m) choose=moxa
                      if [ -z $3 ]
                        then
                          cn=
                      elif [ $3 = "-c" ] || [ $3 = 'cn' ]
                        then
                          if [ -z $4 ]
                            then
                              echo "Введите номер коннекта" ; read cn
                            else
                              cn=$4
                          fi    
                      else
                        cn=$3
                      fi
                      break ;;                       
              *) choose=101
                      break ;;
            esac
        fi             
      done
  # проверка на спец комманды/ не актуально
  #for input_var in $@
  #do
  # if [ $input_var = '--stay' ]
  #    then
  #      stay=' bash -l '
  #  else
  #    stay=
  #  fi
  #done
  #Здесь должно быть определение камер, но пока нет)

  func_do_command_unterpritator $choose
}
  gping_row () {

    g100_tun $1

    g_ips=$(nslookup gbox-$1 | grep Address |sed '/127.0.1.1/d'| sed 's/Address:\ //g') 

    for ip_g in `echo "$g_ips"`; do
      echo "Пингуем $ip_g"
      ping "$ip_g" &
    done

    gping_stop_flag=false;

    trap ctrl_c INT

    function ctrl_c() {
            gping_stop_flag=true
    } 

    while ( ! read ) | [ "$gping_stop_flag" = true ]
    do
      sleep 1
    done

    pkill -f ping
  }




 #get_stat () {
#  variable_check $*
#  #переменная для функции help
#  local _func_name="get_stat"
#
#  case $1 in 
#    start) cycle=true ; echo "Цикл запущен" ;;
#    stop) cycle=false ; echo "Цикл остановлен" ;;
#    *) func_help $_func_name ;;
#  esac
#    while $cycle
#  do
#    sleep 1
#    until [[ $(date) != $(date -d 8:00:00) ]] && [[ $(date -d mon) && $(date -d tue) && $(date -d wed) && $(date -d thu) && $(date -d fri) ]]
#    do
#      cd ~/Документы/scr/script/ && ./get_stats.sh 
#    done
#  done
#}

#перезапуск видео на БКЕ
bn_snap_restat () {

 
  mysql_connect_to_database="mysql $sql_bn_connect -A"  
  connect_to_server_ssh="sshpass -p $pass_bn_serv ssh -o StrictHostKeyChecking=no $host_bn_serv"
  request="select ws.health_address from WITS_WELL ww inner join WITS_WELLBORE wb on (ww.id=wb.well_id) inner join WITS_SOURCE ws on (ws.id=ww.source_id) inner join WITS_WELL_PROP wp on (wb.well_id=wp.well_id and wp.status_id=3 and wb.status_id=3) ;"
#для ребута по порту
  ports=$($mysql_connect_to_database -e "$request" 2>/dev/null |grep -o -E :[0-9]{4} | tr -d  ':' ) 
# Для ребута царичан.
  health_address=$($mysql_connect_to_database -e "$request" 2>/dev/null  | grep 172.28 | sed 's/http:\/\///' )
  $connect_to_server_ssh 'for f in '$ports' ; do curl http://127.0.0.1:${f}/axis?snapshots=on > /dev/null 2>&1 && echo  "$f - OK" || echo "$f - FAIL" ; done & for health in  '$health_address' ; do  curl http://${health}/axis?snapshots=on > /dev/null 2>&1 && echo  "$health - OK" || echo "$health - FAIL" ; done &'

# Для ребута царичан.

  #$connect_to_server_ssh 'for health in  '$health_address' ; do  curl http://${health}/axis?snapshots=on > /dev/null 2>&1 && echo  "$health - OK" || echo "$health - FAIL" ; done'
}

#Конвертер
conv () {

  local _func_name="conv"
  local convert=

  variable_check $*

    if [ $1 = 'help' ] || [ $1 = 'h' ] || [ $1 = '--help' ] || [ $1 = '-h' ] 
      then
      func_help $_func_name ; return 1
    elif [ -f $1 ]
      then
        original_file="$1"
    elif ! [ -f $1 ]
      then
        echo "Фаил $1 отсутствует!"
        return 1
    fi

    if [ $3 = 'w' ] || [ $3 = 'u' ]
    then 
    convert=$3
    elif [ -z $3 ]
    then    
      if [ $2 = 'u' ] || [ $2 = 'w' ]
        then 
        output_file="$1.out"
        convert=$2
        else
        output_file="$2"
        convert=
      fi
    fi


  case "$convert" in 
    # из UTF-8 -> Win-1251
    u) iconv -f UTF-8 -t WINDOWS-1251 -o "$output_file" "$original_file";;
    #из Win-1251 -> UTF-8
    w) iconv -f WINDOWS-1251 -t UTF-8 -o "$output_file" "$original_file";;
    *) iconv -f WINDOWS-1251 -t UTF-8 -o "$output_file" "$original_file";;
   esac
  echo "Convert completed!"
  color_check
}



#Ситуационный, надо доделать.
con_kill () {

  while ! `sshpass -p  ${DEFAULT_GBOX_PASS} ssh ts@gbox-230 "pkill -f connect"` 
    do 
      sleep 45
    done

}

nice_file () {
  local files=`echo $*`
  for file in $files
    do
      file_name=$file
      cat $file_name | tr -s "\t" '|' | column -t -s "|" > ${file_name}_nice
      cat "${file_name}_nice" > $file_name
      rm ${file_name}_nice
    done
}

mys_select () {

  reference=`mysql -h 192.168.0.135 -ugtionline -ptetraroot WMLS -e  "select * from WITS_ACTIVITY_TYPE order by id"`
  reference=(`echo $reference`)
  ndata=
  echo -e ${reference[]}
}

#открывает выполняемые таски в отдельных окнах.
mywork () {

tasks_id=$($MantisMYSQLBaseConnect -e "select mbt.id as 'ID' from mantis_bug_table mbt INNER JOIN mantis_category_table mct ON (mbt.category_id=mct.id) LEFT OUTER JOIN mantis_user_table mut ON (mbt.handler_id=mut.id) where mbt.status=40 and mut.username in ('a.simuskov') order by last_updated desc;")
    for tasks in $tasks_id 
      do
        if [[ $tasks =~ [0-9]{6} ]]
          then  
            echo "$(date)  $tasks" >> /tmp/mantis_comf_tasks.log
            google-chrome --app="http://office.tetra-soft.ru/mantis/view.php?id=$tasks"
          fi
      done
}


alarms_control () {

  #переменные функции
  local gbox
  local mnem
  local field
  local repit=true
  local input_rec="Ожидаемый ввод: 
    1 - Данные ГТИ с привязкой ко времени.
    2 - Данные ГТИ с привязкой к метрам.
    11 - Состояние емкостей.
    12 - Данные Хромотографа с прявязкой ко времени.
    13 - Данные Хромотографа с привязкой к метрам.
    8  - ЗТС с привязкой к метрам.
    59 - ЗТС с привязкой к времени."

  echo -n "Введите номер бокса (q for exit/h for help) :"
  read gbox

  while ! get_server_use_gbox_conf $gbox 2> /dev/null
    do
      echo -n "Введите номер бокса (q for exit/h for help) :"
      read gbox
    done

  case "$gbox" in
    q) echo "Выход" && return 1;;
    *) get_server_use_gbox_conf $gbox ;;
    h) echo "Пример: 
1. 10
2. 10 2
3. 10 2 boxer
Где первое число - немер бокса, второе - номер коннекта, указание boxer - используется архивный конфиг";;
  esac
            
  while "$repit"
    do
      echo -n "
      Введите номер рекорда:" 
      read rec
        variable_check_digit "$rec"
            case "$rec" in
              1) echo "Выбран первый рекорд 'Данные ГТИ с привязкой ко времени'" && repit=false;;
              2) echo "Выбран второй рекорд 'Данные ГТИ с привязкой к метрам'" && repit=false;;
              11) echo "Выбран одинадцатый рекорд 'Состояние емкостей'" && repit=false;;
              12) echo "Выбран двенадцатый рекорд 'Хромотограф с привязкой к времени'" && repit=false;;
              13) echo "Выбран тренадцатый рекорд 'Хромотограф с привязкой к метрам'" && repit=false;;
              8) echo "Выбран восьмой рекорд 'ЗТС с привязкой к метрам'" && repit=false;;
              59) echo "Выбран пятьдесят девятый рекорд 'ЗТС с привязкой к времени'" && repit=false;;
              *)  echo "Некорректно! ${input_rec}"  
            esac
  done

  local repit=true

 #Выбираем скважину
  echo 

  echo -n "Введите мнемоник для отслеживания:"
  read mnem
  echo "Выбран Mnemonic: $mnem"

  echo  -n "Отслеживаем по?
    1.Time
    2.Depth
Выбор:"

  read field
  field=`echo "${field}"| cut -c 1`

  case "$field" in
    t|T|1) field="date" && echo "Введите дату и время:" && read value
           echo "Отслеживаем параметр $mnem по $field вплоть до $value .";;
    D|d|2) field="depth" && echo "Введите глубину в метрах:" && read value
           echo "Отслеживаем параметр $mnem по $field вплоть до $value м.";;
    *) echo "По умолчанию Depth" && field="depth" && echo "Введите глубину в метрах:" && read value
       echo "Отслеживаем параметр $mnem по $field вплоть до $value м.";;
  esac

  

  alarms_function $box $rec $mnem $field $value

}



alarms_function () {

#На входе должна принимать:
# 1.  первой переменной номер бокса
# 2. второй рекорд по которому отслеживает
# 3. мнемоник
# 4. Определяющую переменную - time/depth 
# 5. значение для отслеживания.

  # проверка вводных
  if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ] | [ -z "$4" ] | [ -z "$5" ]
   then
     echo "-Неверное кол-во аргументов проверьте вводные данные."
     return 1;
   fi

  #get_base_path $1
  #mysql -A -h $SQL_PATH_TO_BASE -e ""
  #while ! [[  ]]; do
  #  mysql -A -h $SQL_PATH_TO_BASE -e "
  #  "
  #done

}

# g_off в периоде
g_off_p () {

  local default="igs bn gn ssk e 4 sggf"
  local cycle_counter=1
  if [ -z $1 ]
    then
    local period=$default
  else
    local period=$*
  fi

  while true
    do 
      echo "Цикл #$cycle_counter"
      echo -e "$BGreen====================================="`date`"=======================================$Color_Off" 
      for f in ${period}
        do
        echo -e "\n" && g_off $f
      done
      echo -e "$BGreen====================================="`date`"=======================================$Color_Off" ; let 'cycle_counter=cycle_counter+1' && sleep 600
  done

}

#боксы проекта
get_boxes () {

  variable_check $*

  cdwork && g_off $1 | awk '{ print $6 }'| cut -c 6-8 |sed 's/-//' | grep [[:digit:]] > box.src
  
  if [ -z $2 ]
    then
    return 0
  elif [ $2 = "-s" ]
    then
      _box
  else
    return 0
  fi

  _box () {
    cdwork && cat box.src
  }

}


func_kye_check () {
#test проверка ключей
# код не мой, юзается для тестирования и примера.
    # Usage info
    show_help_gping() {
    echo "
    Usage: ${0##*/} [-hv] [-f OUTFILE] [FILE]...
    Do stuff with FILE and write the result to standard output. With no FILE
    or when FILE is -, read standard input.
    
       -h          display this help and exit
       -f OUTFILE  write the result to OUTFILE instead of standard output.
       -v          verbose mode. Can be used multiple times for increased
                   verbosity.
    "
   }
   
   # Initialize our own variables:
  output_file=""
  verbose=0
  OPTIND=1
  # Resetting OPTIND is necessary if getopts was used previously in the script.
  # It is a good idea to make OPTIND local if you process options in a function.
 
 while getopts hvf: opt; do
     case $opt in
        h) show_help_gping
            exit 0
             ;;
        v)  verbose=$((verbose+1));;
        f)  output_file=$OPTARG ;;
        *) show_help_gping >&2
             exit 1
             ;;
     esac
 done
 shift "$((OPTIND-1))" # Shift off the options and optional --.
 
 # Everything that's left in "$@" is a non-option.  In our case, a FILE to process.
 printf 'verbose=<%d>\noutput_file=<%s>\nLeftovers:\n' "$verbose" "$output_file"
 printf '<%s>\n' "$@"
 
 # End of file
} 

colors() {
        local fgc bgc vals seq0

        printf "Color escapes are %s\n" '\e[${value};...;${value}m'
        printf "Values 30..37 are \e[33mforeground colors\e[m\n"
        printf "Values 40..47 are \e[43mbackground colors\e[m\n"
        printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

        # foreground colors
        for fgc in {30..37}; do
                # background colors
                for bgc in {40..47}; do
                        fgc=${fgc#37} # white
                        bgc=${bgc#40} # black

                        vals="${fgc:+$fgc;}${bgc}"
                        vals=${vals%%;}

                        seq0="${vals:+\e[${vals}m}"
                        printf "  %-9s" "${seq0:-(default)}"
                        printf " ${seq0}TEXT\e[m"
                        printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
                done
                echo; echo
        done
}

test_opt () {
              aflag=
              bflag=
              while getopts ab: name
              do
                  case $name in
                  a)    aflag=1;;
                  b)    bflag=1
                        bval="$OPTARG";;
                  ?)   printf "Usage: %s: [-a] [-b value] args\n" $0
                        exit 2;;
                  esac
              done
              if [ ! -z "$aflag" ]; then
                  printf "Option -a specified\n"
              fi
              if [ ! -z "$bflag" ]; then
                  printf 'Option -b "%s" specified\n' "$bval"
              fi
              shift $(($OPTIND - 1))
              printf "Remaining arguments are: %s\n" "$*"
}