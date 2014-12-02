#!/bin/bash

password=`gkeyring --name vpn -1`
VALUE=`yad --center --title="VPN Login" --form --field="Code" --button="gtk-ok:0"`
if [ "$VALUE" != "" -a "$VALUE" != "||" ]; then 
	IFS="|"; declare -a Array=($VALUE) 
	#password=${Array[0]}
	code=${Array[0]}

#	echo "Password: $password"
#	echo "Code: $code"

	#exp_internal 1	
	EXPECTRESULT=$(expect -c "
	set timeout 60
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
else
	echo "Canceled"
	exit 1
fi

