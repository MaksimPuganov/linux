#!/bin/bash

PID=`ps -ef | grep playlist | grep -v "grep" | awk '{print $2}'`
if [ "$PID" != "" ]; then
        echo "Killing previous playlist execution $PID..."
        PIDS=`pstree -A -pn $PID | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tr "\n" " "`
        echo "Killing $PIDS..."
        sudo kill -9 $PIDS
        sudo /home/pi/cleanup.py 2>&1
fi

