#!/bin/bash

PROXY=
PROXY_USER=
PROXY_PASSWORD=
CLEAR=false

function clearProxy() {
	# remove proxy configuration if present
	sudo sed -i '/proxy=/d' /etc/yum.conf
	sudo sed -i '/proxy_username=/d' /etc/yum.conf
	sudo sed -i '/proxy_password=/d' /etc/yum.conf
	sudo sed -i '/http_proxy=/d' /etc/wgetrc
}

if [ $# -gt 0 ]; then
	while true; do
		case "$1" in
			--user )
			PROXY_USER="$2"; shift 2 ;;

			--passwd )
			PROXY_USER="$2"; shift 2 ;;

			--proxy )
			PROXY="$2"; shift 2 ;;

			--clear )
			CLEAR=true; shift ;;

			* ) 
			echo "Invalid option $1"
			break ;;
		esac
	done

	if [ "$CLEAR" = "true" ]; then
		clearProxy
	elif [ "$PROXY" != "" ]; then
		clearProxy

		echo "proxy=http://$PROXY" >> /etc/yum.conf

		if [ "$PROXY_USER" != "" -a "$PROXY_PASSWORD" != "" ]; then
			echo "http_proxy=http://$PROXY_USER:$PROXY_PASSWORD@$PROXY" >> /etc/wgetrc
			echo "proxy_username=$PROXY_USER" >> /etc/yum.conf
			echo "proxy_password=$PROXY_PASSWORD" >> /etc/yum.conf
		else
			echo "http_proxy=http://$PROXY" >> /etc/wgetrc
		fi
	else
		echo "Invalid options provided"
		exit 2
	fi
else
	echo "Usage: `basename $0`: --proxy <Host>:<Port> [--user <Username>] [--password <Password>]"
	exit 1
fi
