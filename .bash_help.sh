
source ~/Документы/scr/.bash_source_color.cfg

func_help () {
	case $1 in
		gping) func_help_gping ;;
		conv) func_help_conv ;;
		*) ;;
	esac
}

func_help_gping () {
	echo -e "
Usage gping:
	gping [g№] [s|c|m] {-c|cn} <digit>
	
	Где:

	g№ - Номер бокса.
	s - Сборщик
	c - Камеры
	m - moxa
	-c or cn - Номер коннекта

	gping 03 c -c 2 - выполнит пинг камер второго коннекта на gbox-03
	gping 165 s - выполнит nc -vv сборщика 445.

Описание:
	gping без указания дополнительных ключей по умолчанию пингует бокс по всем доступным каналам и проверяет доступность тунеля с g100.
	s , с , m - второй переменной - подключается к боксу по ssh и выполняет пинг сборщика, камер или моксы соответственно.
	s|sbor|sborshik - неткат 445 порта сборщика.
	c|cam|camera|cameras - пинг камер.
	m|mox|moxa - пинг моксы 
	ключ 
	-с|cn|--connect-namber - определяет номер коннекта. По умолчанию всегда первый коннект
	"
	return 1

}

func_help_conv () {
	echo -e "

Usage conv:
	conv {-h} [input_File] [outpot_File] [u|w]
	Где:
	-h | h | help | --help - выведет help 
	input_File - Фаил для перевода.
	outpot_File - Имя нового файла с выводом.
	u - Конвертация из UTF-8 -> Win-1251
	w - Конвертация из Win-1251 -> UTF-8

Описание:
	Перекодирует из UTF в Win и обратно. Без указания всега перекодирует из Win в UTF.

Примеры:

	conv input input.out w - Переведёт содержимое файла input из Win в UTF, результат запишет в input.out

	Может использоваться без указания файла вывода, тогда автоматически создастся фаил с расширением .out
	
	conv input u - Переведёт содержимое файла input из UTF в Win и запишет результат в input.out

	conv input - Может использоваться по умолчанию. Переведёт содержимое файла из Win в UTF и сохранить в фаил input.out
	"

return 1

}
