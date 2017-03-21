#!/bin/bash

# Запуск всего(чего попало) при старте.



#Запуск скрипта проверки закомфермленных тасков

#Вин ХП
while ! virtualbox --startvm "Windows XP SP3" &
do 
	sleep 60
done
#Вин 7
while ! virtualbox --startvm "Win7" &
do
	sleep 60
done
#Вин 10
while ! virtualbox --startvm "MSEdge - Win10_preview" &
do
	sleep 60
done


