#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -gt 0 ]; then
	VPN_CONF=/tmp/vpn-$$.ovpn
	AUTH_USER=/tmp/vpn-$$.auth
	
	read -s -p "Enter Username: " username
	echo ""
	read -s -p "Enter Password: " password
	echo ""

	echo "$username" > $AUTH_USER
	echo "$password" >> $AUTH_USER

	cp $DIR/template.ovpn $VPN_CONF
	sudo sed -i "s!%HOST%!$1!g" $VPN_CONF
	sudo sed -i "s!%VPN_TMP_DIR%!$VPN_TMP_DIR!g" $VPN_CONF
	sudo sed -i "s!%DIR%!$DIR!g" $VPN_CONF
	sudo sed -i "s!%AUTH_USER%!$AUTH_USER!g" $VPN_CONF

	sudo openvpn --config $VPN_CONF
	rm $VPN_CONF
	rm $AUTH_USER
	sudo ufw disable
else
	echo "Usage: $(basename $0): <server>"
	exit 1
fi

