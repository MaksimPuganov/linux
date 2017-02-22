#!/bin/bash

ETH_DEVICE=$(ip link | grep ": e" | tr ':' ' ' | awk '{print $2}')

IP_ADDRESS=$(ip addr show dev $ETH_DEVICE | sed -nr "s/.*inet ([^/]+).*/\1/p")

echo ""
echo "Your current IP Address is $IP_ADDRESS"
echo ""

SCRIPT="update wp_options set option_value = 'http://$IP_ADDRESS' where option_name in ('siteurl', 'home')"
echo $SCRIPT | mysql -u root --password=password aqidb 2>/dev/null

# ensure that wordpress uses the updated config, need to restart apache2
# TODO - only do this if the IP has changed.
sudo systemctl restart apache2

