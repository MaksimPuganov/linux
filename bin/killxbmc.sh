#!/bin/bash

if [ `ps -ef | grep google-chrome | wc -l` -gt 0 ]; 
then
	echo "Kill Chrome..."
	killall chrome
else
	echo "Restart XBMC..."
	sudo killall -9 xbmc.bin
	sudo killall -9 xbmc

	sudo su - jason -c "/usr/bin/xbmc"
fi
