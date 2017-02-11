#!/bin/bash

PIDS=`ps -ef | grep kodi | grep -v 'grep' | grep -v 'kill' | awk '{print $2}' | tr  '\n' ' '`

kill -9 $PIDS
if [ $? -eq 0 ]; then
	zenity --width 100 --info --title "Killing Kodi" --text "Kodi Killed"
else
	zenity --width 100 --error --title "Killing Kodi" --text "Kodi not Killed"
fi
