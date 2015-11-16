#!/bin/bash

WLAN_DEFAULT_GATEWAY=`route | grep default | grep wlan0 | awk '{print $2}'`

if [ "$WLAN_DEFAULT_GATEWAY" != "" ]; then
	echo "Configuring WLAN to take over internet"
	sudo route del -net default gw $WLAN_DEFAULT_GATEWAY netmask 0.0.0.0 dev wlan0
	sudo route add -net default gw $WLAN_DEFAULT_GATEWAY netmask 0.0.0.0 dev wlan0 metric 1

	switchlocation.sh VPN
else
	switchlocation.sh WORK
fi
