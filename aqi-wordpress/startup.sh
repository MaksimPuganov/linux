#!/bin/bash

ETH_DEVICE=$(ip link | grep ": e" | tr ':' ' ' | awk '{print $2}')

IP_ADDRESS=$(ip addr show dev $ETH_DEVICE | sed -nr "s/.*inet ([^/]+).*/\1/p")

echo ""
echo "Your current IP Address is $IP_ADDRESS"
echo ""

SCRIPT="update wp_options set option_value = 'http://$IP_ADDRESS' where option_name in ('siteurl', 'home')"
echo $SCRIPT | mysql -u root --password=password  aqinetau_wp1 2>/dev/null
