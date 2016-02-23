#!/bin/bash

if [ $# -gt 0 ]; then
	if [ "$1" = "start" ]; then
		if  [ "$2" != "" ]; then
			IP=$2
			sudo sed -i 's!^#address=/netflix.com!address=/netflix.com!g' /etc/dnsmasq.conf
			sudo sed -i -r "s|(^address=/netflix.com/).*|\\1$IP|g" /etc/dnsmasq.conf
			sudo service dnsmasq restart
		else
			echo "Missing IP address"
			exit 2
		fi
	elif [ "$1" = "stop" ]; then
		sudo sed -i 's!^address=/netflix.com!#address=/netflix.com!g' /etc/dnsmasq.conf
		sudo service dnsmasq restart
	fi
else
	exit 1
fi
