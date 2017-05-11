
#Подключение цветов
source ~/Документы/scr/source/bash_source_color.cfg
source ~/Документы/scr/source/data.cfg

readonly SETCOLOR_SUCCESS="echo -en $BGreen"
readonly SETCOLOR_FAILURE="echo -en $BRed"
readonly SETCOLOR_NORMAL="echo -en $Color_Off"
readonly SETCOLOR_BLUE="echo -en $BBlue"
readonly SETCOLOR_CYAN="echo -en $BCyan"
readonly SETCOLOR_RED="echo -en $Red"



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

  rsync_b_function () {
      #
    local path=gbox-$box_num:$destination
    local f=`basename   "$source_files"`

      ${SETCOLOR_CYAN}
      echo "
      Copy file $f to $path
      "
      ${SETCOLOR_NORMAL}


      pass_g $box_num >/dev/null

      rsync -azuvP "$source_files" --rsh="sshpass -p "$pass_for_g" ssh -l ts " $path/

      color_check
  }

  rsync_b_control_input () {
    if [ -z "$box_num" ] | [ -z "$source_files" ] | [ -z "$destination" ]
        then 
        echo -e "Usage:\n  #1 - номер бокса, #2 - куда на боксе #3 - файлы/папки для отправки"
         return 1
      fi
      if ! ([ -f "$source_files" ] || [ -d "$source_files" ])
      then
        ${SETCOLOR_FAILURE}
        echo "$source_files такого файла или каталога не существует!"
        ${SETCOLOR_NORMAL}
        return 1
      fi
      if ! ( `ping -c 2 gbox-$box_num > /dev/null` ); then
        echo -e $COLOR_RED"Сервер gbox-$box_num недоступен" $Color_Off
        return 1
      fi

   rsync_b_function   
  }

  rsync_b_interactive () {

    local rsync_b_design="no"

    while [[ $rsync_b_design == "no" ]]; do
      local box_num=
      local source_files=
      local destination=

      while ! [[ $box_num =~ [0-9]{2} ]]; do
        echo -en $BWhite"Введите номер бокса для отправки файлов: " $Color_Off &&  read box_num  
      done
      echo "Выбран gbox-$box_num"

      echo -en $BBlue"Что отправляем(фаил/дирректория): " $Color_Off &&  read source_files
      
      if [ -f $source_files ] ; then  
        echo "Отправляем фаил : $source_files"
      elif [ -d $source_files ]; then
        echo "Отправляем папку : $source_files"
      fi

      echo -en $BGreen"Дирректория на боксе $box_num: " $Color_Off && read destination

      echo "Итого отправляем $source_files на gbox-$box_num:$destination"
      echo -n "Хотите продолжить (yes/no): " && read rsync_b_design
    done

    rsync_b_control_input
    
    }

  rsync_b_cli () {

    local box_num=$1
    local source_files=$3
    local destination=$2

    rsync_b_control_input

  }
#Проверка что введено хоть что-то
variable_check $*
#Имя функции для хелпа
#local _func_name="rsync_b"

if [[ $1 == "h" ]] || [[ $1 == "-h" ]]
  then
  func_help $FUNCNAME
  return 1
elif [[ $1 == "-i" ]] || [[ $1 == "--interactive" ]]
  then
  rsync_b_interactive
else
  rsync_b_cli $1 $2 $3
fi

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

local gnum=
local box_adr=
local _return=0 #код ошибки по умолчанию

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
#Функция пингонатор. Пытается достучаться до бокса по впн, когда получается, выводит нотифай
  func_ping () { 
    while true ; do 
    ping -c 1 gbox-$gnum >/dev/null 2>&1 && break 
    done
    echo -e "${BGreen}gbox-$gnum IS AVEABLE NOW!$Color_Off "
    notify-send "GBOX-$gnum OK" "gbox-$gnum доступен. \n PING OFF" && return 0 
  }

  func_interfaces () {  # Возвращает содержимое interfaces, если последняя дата изменения файла менее 24ч # Иначе возвращет shh_command

    local local_interfaces_file=$(find ${PATH_FOR_GBOX_CONF}/$gnum/ -name interfaces -mtime -1 2>/dev/null)
    
    if [ -z $local_interfaces_file ]
    then
      ssh_command=$ssh_command_interfaces
    else
      cat $local_interfaces_file
      _return=1 
    fi
  }

  func_stop_start_restart () {
      
    g_connect_start_stoper () {
      #Запуск коннекта осуществляется на основе или из файла start_connect.sh
      local ssh_command_start='start_connect=$(find /home/ts/ -type f -name start_connect.sh -executable); if [ -z $start_connect ] ; then echo -e "\e[31;1;3;4m" "Фаил $start_connect отсутствует, или не исполняемый!\n Провертьте фаил!" -e "\e[0m" && ls -la'
      
      if [ -z $cn ] || [[ $cn == "1" ]] ; then
        cn=''
        ssh_command_start='$ssh_command_start ; else starter="grep connect$cn/ $start_connect" ; $starter echo -e "\e[32;1m" "PID процесса $!" "\e[0m"; fi'
      elif [[ $ch == "all" ]] ; then
        cn="все"
        ssh_command_start='$ssh_command_start ; else $start_connect echo -e "\e[32;1m" "PID процесса $!" "\e[0m"; fi'
      elif [[ $cn =~ [^[2-9]{1}$] ]] ; then
          ssh_command_start='$ssh_command_start ; else starter="grep connect$cn/ $start_connect" ; $starter echo -e "\e[32;1m" "PID процесса $!" "\e[0m"; fi'
      else
        echo -e $BRed"Не определён номер коннекта!" $Color_Off
      fi
      
      local ssh_descript_start="${BWhite}Запускаем$BRed ${cn}${BWhite}коннект на gbox-$gnum!$Color_Off ; "
      
      ssh_descript=$ssh_descript_start
      ssh_command=$ssh_command_start

    }

    g_connect_stop_restart() {

      case $_command in 
        "restart") _cut='cut -d " " -f4,3' ;;
        "stop") _cut='cut -d " " -f4,3';;
        *) echo "help";;
      esac
    _command=`echo "$_command $service $cn"`
    
    }

    g_box_start_stoper () {

        case $_command in 
          "restart") ssh_command='echo $pass_g | sudo reboot' ;;
          start|stop) echo -e "${BRed}Включение и выключение бокса по SSH не предусмотренно!$Color_Off" ; return 1 ;;
          *) echo -e "Возможные варианты:\n -[restart]" ;;
          esac   
          _command=`echo "$command gbox-$num"`
      }

      g_services_start_stoper () {
        case $service in 
          apache) service="apache2" ;;
          vpn) service="openvpn" ;;
          samba) service='smbd' ;;
          network|net|networking) service='networking';;
          *) service=$service ;;
          esac
          ssh_descript="Выполняем $_command $service на gbox-$gnum"
          ssh_command="echo $pass_g | sudo -S service $service $_command" 
          _command=`echo "$command $service"`
      }

    case $service in 
      connect) g_connect_start_stoper $_command ;; #Работает с коннектом
      gbox) g_box_start_stoper $_command ;; # работать будет только рестарт!!!  
      help) echo 'help'; _return=1 ;;
      *) g_services_start_stoper $_command ;; #Парсит остальный выбор. 
    esac

  }

  func_ssh_command_log () {
    if [[ $connection == "box" ]]; then
      if [[ $_command == 'ssh' ]]; then
        ssh_command_log=$ssh_command_default
      else 
        ssh_descript="Отправляем команду - ${COLOR_RED}'$_command'${COLOR_NORMAL} на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})"
        ssh_command_log="[ -d /home/ts/backup/tools ] && echo `date` `whoami` from `hostname` and use $box_adr executed : $_command >> /home/ts/backup/tools/logins.log && $ssh_command"
      fi
      ssh_command="$ssh_command_log"
    fi
    func_connect_to $ssh_command
  }


  func_check_cases () {

    case $1 in
    # #connect restart
    # cr|cres|crestart) _command="restart"; case $2 in
    #   --all|-a|a|all) cn="all" ;;
    #   -c|c|-cn|--cn|cn) if [ -z $3 ] ; then echo -n "Введите номер коннекта: " ; read cn ; else cn="$3" ; fi ;;
    #   ^[1-9]{1}$) cn="$2" ;;
    #   *) echo -n "Введите номер коннекта: " ; read cn ;;
    #   esac ;; 
    # #connect_stop
    # cstop) _command="stop" ; case $2 in
    #   --all|-a|a|all) cn="all" ;;
    #   -c|c|-cn|--cn|cn) if [ -z $3 ] ; then echo -n "Введите номер коннекта: " ; read cn ; else cn="$3" ; fi ;;
    #   ^[1-9]{1}$) cn="$2" ;;
    #   *) echo -n "Введите номер коннекта: " ; read cn ;;
    #   esac ;; 
    # #connect_start
    # cstart) _command="start" ; case $2 in
    #   --all|-a|a|all ) cn="all";;
    #   -c|c|-cn|--cn|cn) if [ -z $3 ] ; then echo -n "Введите номер коннекта: " ; read cn ; else cn="$3" ; fi ;;
    #   ^[1-9]{1}$) cn="$2" ;;
    #   *) echo -n "Введите номер коннекта: " ; read cn ;;
    #   esac ;;  
    # Функция дря работы с сервисами на боксе, включая коннект
    "restart"|"start"|"stop") _command="$1" 
      if [ -z $2 ]; then 
        service="help"
      else
        service='$2'
      fi
      if [ -z $3 ] ; then
        cn=''
      else
        cn=$3
      fi ;;
    #[0-9]) cn=$2 ;;   
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
    #open any configs
    oc|open|--open) _command="open" ; config="$2" ;;
    #head version admin & connect
    ver|v|--version)  if [ -z $2 ]; then g100_boxer="exist" ; _command="version"
      elif [[ "$2" = "box" ]] ; then
      _command="version_box" 
      g100_boxer=
      else
          echo -e "${BRed}Параметр $2 не определён!" $Color_Off; _command=101
      fi ;;
    #interfaces
    --interfaces|inter|int|interfaces) _command="interfaces" ;;
    #updater
    update) _command="update" ;;
    #check list
    --checker|check|chek|ck|checker) _command="check_list" ;;
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
  func_help $FUNCNAME ; return 1
elif [[ $1 = "update" ]] || [[ $1 = "updater" ]]
  then
  _command="update"
elif [[ $1 =~ ^[0-9]+$ ]]
  then
    func_check_digit $1 >/dev/null #return ${gnum} ${box_adr}
    if [ -z $2 ] || [[ $2 =~ ^[0-9]{1}$ ]]
       then
       _command="ssh"
       cn=$2 
     else
    func_check_cases "$2" "$3" $4 $5
  fi
else
  echo -e "${BRed}Ключ $1 отсутствует!$Color_Off"
  func_help $_func_name ; return 1
fi

#определяем путь до файлов на 100.
local path_g100_boxer="/home/support/bin/boxer/gbox-$gnum/home/ts/"
if [ -z $g100_boxer ] ; then
  g100_boxer=
  else 
  g100_boxer=$path_g100_boxer
fi
#
local ssh_command=""
local ssh_descript="Заходим на ${COLOR_BLUE}gbox-$gnum\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS:\n$(nslookup gbox-$gnum) \n" 
local ssh_command_default="[ -d /home/ts/backup/tools ] && echo `date` `whoami` from `hostname` and use $box_adr  >> /home/ts/backup/tools/logins.log ; cat /etc/motd; cd connect$cn/ ; bash -l;"

#отправка команды на прямую
local ssh_descript_exec="Отправляем команду - ${COLOR_RED}$command_is${COLOR_NORMAL} на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})"
local ssh_command_exec="[ -d /home/ts/backup/tools ] && echo `date` `whoami` from `hostname` and use $box_adr executed : $command_is >> /home/ts/backup/tools/logins.log && $command_is"
#чек версий админки и коннекта из боксера
local ssh_command_version="echo -e '${BBlue}Admin VERSION:${Color_Off} \n' ; head -1 ${g100_boxer}admin/version ; echo -e '\n${BBlue}Connect VERSION:${Color_Off}\n' ; head -3 ${g100_boxer}connect/version ; echo"
#подключение к боксу через тунель
local ssh_command_tun="-t echo -e Подключаемся к gbox-$gnum && sshpass -p $pass_for_g ssh -p 22$gnum ts@localhost"
#подключение к 100 и update
local ssh_command_update="-t /home/support/bin/updater/update_br9k.sh"
#подключаемся к 100 и выполняем черек $gnum
local ssh_command_check="bin/support_stash//eyeOdin/watchEyeOdin.sh $gnum"
#c 100 берём колличество коннектов и какой к какому серверу относится
local sed_plugin="-e 's/\.\.\/pluginB\//Плагин\ /g'"
local ssh_command_count='cd '${path_g100_boxer}'/; for connect in `ls -d connect*` ; do echo -en "\n\e[34;1m" $connect "\e[0m" ; echo -e "\e[0;92m" ; grep send_to $connect/connect.conf |  tr -s "=" " " ; grep well= $connect/connect.conf | tr -d "well=" ; plugin=`readlink $connect/plugin/Proxy.jar`; echo $plugin | sed '$sed_plugin'; echo ; echo $plugin | cut -d/ -f3| cut --delimiter=P -f1 | xargs -i grep -i {} $connect/connect.conf | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" ; echo -en "\e[0m" ; done ; echo'
local ssh_command_interfaces='cd '${path_g100_boxer}'/ ; cat ../../etc/network/interfaces '


case $_command in
  check_list|info|count|update|tun|version|interfaces) connection="g100" ;;
  *) connection="box" ;;
esac

case $_command in
#ssh) ssh_command=$ssh_command_default ;; # подключение по ссш
count) ssh_command=$ssh_command_count ;; #вывод количества коннектов и имена папок
info) ;; #Вывод грепа по конфигам
log) ;; #Вывод логов + multitail  
check_list) ssh_command=$ssh_command_check ;; #Вывод чеклиста бокса
open) ;; #Открывает в саблайме необходимые настройки
update) ssh_command=$ssh_command_update ;; #Запускает update на сотом
admin_open) google-chrome "http://gbox-$gnum/" && return 1 ;; #Открывает админку
tun) ssh_command=$ssh_command_tun ;; #Идёт на бокс через тунель.
interfaces) func_interfaces $gnum $ssh_command_interfaces ;; #Выводин интерфейсы с 100, если фаил в локальной папке обновлялся не текущим днём
mys_sbor) ;; #проверяет порты и базу MYSQL для welldata или MSSQL для AMТ
mus_local) ;; #Подключается к локальной базе бокса
version)  ssh_command=$ssh_command_version ;; # версия с боксера
version_box) ssh_command=$ssh_command_version ;; #head версий с бокса
exec) ssh_descript=$ssh_descript_exec ; ssh_command=$ssh_command_exec ;;  #выполняет переданную команду по ссш
stop|stop|restart) func_stop_start_restart $_command $service $gnum $cn ;; #  Возвращает ссш команду исходя из введённых условий.

101) func_help $_func_name ; return 1 ;; #выводит хелп
ping) func_ping $gnum & return 1 ;; # Запускает цикл с постоянной проверкой на пинг бокса. Если бокс пингуется выводит нотифай.
esac

  if [ $_return -eq 1 ]; then
    return 1;
  else
    func_ssh_command_log $ssh_command
  fi

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
            func_help $FUNCNAME
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

  #local _func_name="conv"
  local convert=

  variable_check $*

    if [ "$1" = 'help' ] || [ "$1" = 'h' ] || [ "$1" = '--help' ] || [ "$1" = '-h' ] 
      then
      func_help $FUNCNAME ; return 1
    elif [ -f "$1" ]
      then
        original_file="$1"
    elif ! [ -f "$1" ]
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
  echo "Convert complited!"
  color_check
}



#Ситуационный, надо доделать.
con_kill () {

  while ! `sshpass -p  ${DEFAULT_GBOX_PASS} ssh ts@gbox-230 "pkill -f connect"` 
    do 
      sleep 45
    done

}

pbc () { #Скрипт для создания классов в sqlalchemy
  variable_check $*
  local table=$1

    mysql -h $base_path -u $base_username -p${base_password} $base_name -e "desc $table" |  awk '{ print $1 " = " "Column(" $2 ")" $3 $4 }' | sed -e 's/bigint(20)/Integer/;s/varchar/String/;s/double/DOUBLE/;s/datetime/DateTime/;s/float/Float/'

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
g_off_r () {

  local default="n igs bn gn ssk e 4 sggf"
  local cycle_counter=1
  if [ -z $1 ]
    then
    local period=$default
  else
    local period=$*
  fi

  while true
    do 
      clear
      echo "Цикл #$cycle_counter"
      echo -e "$BGreen====================================="`date`"=======================================$Color_Off" 

      for f in ${period}
        do
        echo -e "\n" && g_off $f
      done
      echo -e "$BGreen====================================="`date`"=======================================$Color_Off" ; let 'cycle_counter=cycle_counter+1' && sleep 600
  done

}

get_boxes () {
#боксы проекта. Создаёт файлик со списком боксов, но не отработает со скважинами где нет ГТИ -_-
  variable_check $*

  cdwork && g_off $1 | awk '{ print $6 }'| cut -c 6-8 |sed 's/-//' | grep [[:digit:]] > box.src

    _box () {
    cdwork && cat box.src
  }
  
  if [ -z $2 ]
    then
    return 0
  elif [ $2 = "-s" ]
    then
      _box
  else
    return 0
  fi
}

connect_new_well() {
  #Подключаем удалённо новую скважину. Приминительно только для gbox-43, там очень плохая связь

  if [ -z $1 ] || [ -z "$2" ]; then
    echo -ne $BWhite"Введите номер бокса:  "$Color_Off 
    read gnum
    echo -ne $BBlue"Введите имя скважины:  "$Color_Off
    read well_name
  else
    gnum=$1
    well_name="$2"
  fi

  path_connect="${PATH_FOR_GBOX_CONF}/$gnum/connect.conf"
  old_well_name=`grep well= ${PATH_FOR_GBOX_CONF}/$gnum/connect.conf | sed 's/well=//'`
  last_updated=`find ${PATH_FOR_GBOX_CONF}/$gnum/ -name connect.conf -mtime -1 > /dev/null`
  plugin_list="ReportProxy.jar OpsLogProxy.jar MudlogProxy.jar"
  rm_var="/home/ts/backup/update_gbox.sh -b var ; rm -r /home/ts/connect/var/* ; for plugin in plugin_list ; do rm /home/ts/connect/plugin/$plugin ; done"
  complited=true
  ssh_pass=`pass_hack $gnum`
  copy=false

  while $complited; do
    ping -c 1 gbox-$gnum > /dev/null && #if [ -z $last_updated ]; then
     #gc $gnum
    #fi && 
    if [[ "$old_well_name" == "$well_name" ]] ; then
      echo "Имя скважины в конфиге то же, что и задано! Путь до файлов в конфиге не меняется!"; 
    else 
      echo "Обновляем имя скважины с $old_well_name на $well_name"
      sed "s/$old_well_name/$well_name/g" -i $path_connect 
    fi && 
    while true
    do 
      if ! $copy; then
        rsync -azuvP $path_connect --rsh="sshpass -p $ssh_pass ssh -l ts" gbox-$gnum:/home/ts/connect/ && copy=true
      elif $copy ; then
        sshpass -p $ssh_pass ssh ts@gbox-$gnum -t "if ! [ -z "'`ls /home/ts/connect/var/`'" ] ; then $rm_var ; fi && /home/ts/backup/update_gbox.sh -s stop ; /home/ts/start_connect.sh " && complited=false && break
      fi
    done
  done
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
