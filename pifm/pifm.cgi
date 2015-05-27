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
        echo "<html>"
        echo "<head><style>"
        echo "h1,a { font-size: 100pt; }"
        echo "</style></head>"
        echo "<body><div>"
         if [ "$PID" != "" ]; then
                echo "<h1>Stop Radio</h1>"
                echo "<a href='pifm.cgi?action=stop'>Stop</a>"
        else
                echo "<h1>Start Radio</h1>"
                echo "<a href='pifm.cgi?action=start'>Start</a>"
        fi

        echo "</div></body></html>"
fi

