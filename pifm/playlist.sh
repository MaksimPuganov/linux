#!/bin/bash

if [ $# -eq 1 ]; then
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

