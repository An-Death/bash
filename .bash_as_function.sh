
source ~/Документы/scr/.bash_source_color.cfg

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
  if [ -f "$1" ]
    then 
      mass=1
    else
      mass=0
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



# копия Макса с лобавленной возможностью ввода 3й переменной для отправки команды на бокс по ssh
# для отправки команды всегда необходимо указывать 3и переменных, где 1 - номер бокса, 2 - номер коннекта, 3 - комманда в ковычках.
function g () {

  variable_check $*

  if `echo $1 | grep  -m 1 -qE "[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"`
  then
    local gnum=`nmblookup -A $1| grep -m 1 -oE "GBOX-[[:digit:]]{2,4}" | grep -oE "[[:digit:]]{2,4}"` ||  (echo "По указанному ip находится не GBOX" 1>&2 ; return 1 )
    local box_adr="${1}"
  else
    if [[ "${#1}" -lt 2 ]] ; then  gnum="0${1}" ; else gnum="${1}" ; fi
    local box_adr="gbox-${gnum}"
  fi
  pass_g $gnum;

  if [ -z "$3" ] 
    then 
      if [ -z "$2" ] 
        then
          echo -e "Заходим на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no -t "${box_adr}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${box_adr}" " >> "/home/ts/backup/tools/logins.log" ; cat /etc/motd; bash -l;"
        else
          get_server_use_gbox_conf  $gnum $2|| return 2
          echo -e "Заходим на gbox-$gnum\nСкважина $(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\nЗаходим по ip $GBOX_VPN" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no "${GBOX_VPN}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${GBOX_VPN}" " >> "/home/ts/backup/tools/logins.log" ; cat /etc/motd; bash -l;"
      fi
    else 
      if [ "$2" -eq "1" ]
        then
          echo -e "Отправляем команду - ${COLOR_RED}"$3"${COLOR_NORMAL} на ${COLOR_BLUE}gbox-${gnum}\n${COLOR_NORMAL}Скважина ${COLOR_BLUE}$(grep well= $PATH_FOR_GBOX_CONF/${gnum}/connect.conf|sed s/well=//)\n${COLOR_NORMAL}Данные DNS\n$(nslookup gbox-${gnum})" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no -t "${box_adr}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${box_adr}" executed : "$3" " >> "/home/ts/backup/tools/logins.log" && "${3}""
        else
          get_server_use_gbox_conf  $gnum $2|| return 2
          echo -e "Отправляем команду - ${COLOR_RED}"$3"${COLOR_NORMAL} на gbox-$gnum\nСкважина $(grep well= $PATH_FOR_GBOX_CONF/$gnum/connect.conf|sed s/well=//)\nЗаходим по ip ${GBOX_VPN}" && sshpass -p "$pass_for_g" ssh -l ts -o StrictHostKeyChecking=no "${GBOX_VPN}" "[ -d "/home/ts/backup/tools" ] && echo "`date` "`whoami`" from "`hostname`" and use "${GBOX_VPN}" executed : "$3" " >> "/home/ts/backup/tools/logins.log" && "${3}""
      fi
  fi
  
    local error_num="$?"
    case "$error_num" in
      0) notify-send "GBOX-$gnum OK" "Соединение с gbox-$gnum завершено";;
      5)notify-send "GBOX-$gnum ERROR"  "Неправильный логин/пароль gbox-$gnum";;
      255) notify-send "GBOX-$gnum ERROR" "Ошибка при копировании настроек с gbox-$gnum connect$connect_num";;
      *) echo "New error $error_num" ;;
    esac

    
}

## пинг бокса, пинг сборщика,пинг камер.

function gping () {
  # переменные
  local _help_name="gping"
  local connect=
  local choose=
  local camera=
  local camera_check=
  local cn=
  local _help_gping=
  # проверка ввода
  variable_check $*

      while ! input_chek=true
      do
        if [[ $2 =~ ^[0-9]$ ]]
          then
            case $2 in
              0|1) connect= 
                func_itr 1 ;;
              2|3|4|5|6|7|8|9) connect=$2
                func_itr 1 ;;
              *) func_help $_help_name
              ;;  
            esac
          else
            case $2 in
              sbor|s|-s) choose=$2 
                func_itr 1 ;;
              cam|camera|c|-c|-cam) choose=$2 
                func_itr 1 ;;
              h|-h|help|--help) func_help $_help_name
                ;;
            esac
        fi
      done

  if [ $1 = "h" ] || [ $1 = "help" ] || [ $1 = "-h" ] || [ $1 = "--help" ]
    then
      func_help $_help_name && return 1  
  #если нет второй переменной пингуется бокс
  elif [ -z $2 ] 
  then
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
  #Иначе определяется вторая переменная ввода   
  else

    #Работа с переменной    
    case "$2" in
      sbor|s) func_ping_sbor $1 $2 
      color_check ;;
      cam|c)  if [ -z $3 ]
                then 
                # echo "Введите номер коннекта: " ; read cn
                cn=1
                func_ping_camera $1 $2
              elif [ $3 = "-c" ] || [ $3 = 'cn' ]
                then
                cn=$4
                func_ping_camera $1 $2  
              else
                cn=$3
                func_ping_camera $1 $2
              fi
        ;; 
      *) echo -e "help"
        ;;
    esac


  fi
  func_ping_sbor () {
    echo -e "\e[0;1m""Подключаемся к удалённому серверу...""\e[0m" && pass_g $1 && sshpass -p $pass_for_g ssh -l ts gbox-$1 'echo -e "\e[0;1m""Определяем плагин и IP сборщика...""\e[0m"; readlink connect/plugin/Proxy.jar |basename `cat ` |grep -i `sed "s/Proxy.jar//"` connect/connect.conf|nc -vv `grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` 445 ' 
  }

  func_ping_camera () {
    echo -e "\e[0;1m""Подключаемся к удалённому серверу...""\e[0m" && pass_g $1 && sshpass -p $pass_for_g ssh -l ts gbox-$1 'echo -e "\e[0;1m""Опеределяем IP камер:""\e[0m""\n" ; case '"$cn"' in 
                  1) echo -e "\e[34;1m""connect/" "\e[0m""\n" ; grep -E -o "^camera.*stream.*([0-9]{1,3}[\.]){3}[0-9]{1,3}" ~/connect/connect.conf | for f in `grep -vE "recorder"` ; do echo -e "\e[32;1m"$f "\e[0m" && echo $f | ping -c 3 `grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` ; done ; echo "done" ;;  
                  2|3|4|5|6|7|8|9) echo -e "\e[34;1m"connect'"$cn"'/ "\e[0m""\n"; grep -E -o "^camera.*stream.*([0-9]{1,3}[\.]){3}[0-9]{1,3}" ~/connect'"$cn"'/connect.conf | for f in `grep -vE "recorder"`; do echo -e "\e[32;1m"$f "\e[0m" && echo $f | ping -c 3 `grep -E -o -m 1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` ; done; echo "done" ;; 
                  esac'
  }

  func_itr () { #остановка цикла определения
    if [ $1 -eq 1 ]
      then
        input_chek=true
      else
        input_chek=false
    fi
  }
}


#test_func () {
#  echo "Подключаемся к удалённому серверу..." && pass_g $1 && sshpass -p $pass_for_g ssh -l ts gbox-$1 ' echo param'"$2"' && echo param'"$3"''
#}


#Конвертер
conv () {

  variable_check $*

  original_file="$1"
  if [ -z $2 ]
    then 
    output_file="$1"".out"
  else
    output_file="$2"
  fi

  case "$3" in 
    
    u) iconv -f WINDOWS-1251 -t UTF-8 -o "$output_file" "$original_file";;
     # из UTF-8 -> Win-1251
    w) iconv -f UTF-8 -t WINDOWS-1251 -o "$output_file" "$original_file";;
      #из Win-1251 -> UTF-8
    *) iconv -f WINDOWS-1251 -t UTF-8 -o "$output_file" "$original_file";;
  esac
  color_check
}


#Ситуационный, надо доделать.
con_kill () {

  while ! `sshpass -p  ${DEFAULT_GBOX_PASS} ssh ts@gbox-230 "pkill -f connect"` 
    do 
      sleep 45
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

#боксы проекта
#g_off sggf | awk '{ print $6 }'| cut -c 6-8 |sed 's/-//' | grep [[:digit:]] > box


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