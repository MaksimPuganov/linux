#!/bin/bash

if [ $# -eq 1 ]; then
        PID=`ps -ef | grep playlist | grep -v "grep" | grep -v "$$" | awk '{print $2}'`
        if [ "$PID" != "" ]; then
                echo "Killing previous playlist execution $PID..."
                PIDS=`pstree -A -pn $PID | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tr "\n" " "`
                echo "Killing $PIDS..."
                sudo kill -9 $PIDS
                sudo /home/pi/cleanup.py 2>&1
                sleep 10
        fi

        IFS=$'\n'
        while : ; do
                for j in `cat $1`; do
                        sox -t mp3 "$j" -t wav --input-buffer 80000 -r 22050 -c 1 - | sudo /home/pi/pifm - 91.3
                done
        done
else
        echo "Usage `basename $0`: <playlist>"
        exit 1
fi
