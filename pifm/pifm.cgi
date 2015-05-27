#!/bin/bash

PID=`ps -ef | grep playlist | grep -v "grep" | awk '{print $2}'`
if [ "$QUERY_STRING" != "" ]; then
	if [ "$QUERY_STRING" = "action=stop" ]; then
		if [ "$PID" != "" ]; then
			sudo killall playlist.sh 2>&1
			sudo killall pifm 2>&1
			sudo /home/pi/cleanup.py 2>&1
		fi
	elif [ "$QUERY_STRING" = "action=start" ]; then
		if [ "$PID" = "" ]; then
			nohup /home/pi/playlist.sh /mnt/music/playlist.m3u &> /dev/null 2>&1 &
		fi
	fi

	echo -e "Location: pifm.cgi\n\n"
else
	echo -e "Content-type: text/html\n\n"
	echo "<html><body>"
	echo "<form action='pifm.cgi' method='get'>"
	 if [ "$PID" != "" ]; then
		echo "<h1>Stop Radio</h1>"
		echo "<input type='submit' value='Stop'>"
		echo "<input type='hidden' name='action' value='stop'>"
	else
		echo "<h1>Start Radio</h1>"
		echo "<input type='submit' value='Start'>"
		echo "<input type='hidden' name='action' value='start'>"
	fi

	echo "</form>"
	echo "</body></html>"
fi

