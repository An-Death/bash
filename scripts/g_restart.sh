#!/bin/bash

#Скрипт для рестарта бокса, если недоступен сервер и офис

if [ -f /tmp/True ]; then
	if ( ! ping -c 5 `grep send_to_address /home/ts/connect/connect.conf | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}"` > /dev/null ) | ( ! ping -c 5 77.72.127.230 > /dev/null ) ; then
			reboot
		else
			rm /tmp/True && exit
		fi
else
	if ( ! ping -c 5 `grep send_to_address /home/ts/connect/connect.conf| grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}"` > /dev/null ) | ( ! ping -c 5 77.72.127.230 > /dev/null ) ; then
			touch /tmp/True
		else
			exit
		fi
fi
