#!/bin/bash

if [ "`route | grep tun | wc -l`" -gt 0 ]; then
	echo "Tunning already established!"
	exit 1
fi

# kwalletcli -e veda -f passwords -p <password>
password=`kwalletcli -e veda -f passwords`
VALUE=`yad --center --title="VPN Login" --form --field="Code" --button="gtk-ok:0"`
if [ "$VALUE" != "" -a "$VALUE" != "||" ]; then 
	IFS="|"; declare -a Array=($VALUE) 
	#password=${Array[0]}
	code=${Array[0]}

#	echo "Password: $password"
#	echo "Code: $code"

	EXPECTRESULT=$(expect -c "
	set timeout 60
	exp_internal 1	
	match_max 100000
	spawn sudo vpnc --local-port 0 corp.vpnc 
	expect \"Enter password for\"
	send \"$code\r\";
	expect \"Password for VPN\"
	send \"$password\r\";
	expect \"Connect Banner:\"
	wait;
	interact
	")

	echo $EXPECTEDRESULT

	if [ "`route | grep tun | wc -l`" -gt 0 ]; then
		switchlocation.sh VPN
		echo "Success!"
	else
		echo "Failure!"
	fi
	exit 0
else
	echo "Canceled"
	exit 1
fi

