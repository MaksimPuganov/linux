#!/bin/bash

/etc/openvpn/update-resolv-conf $@

# we don't want to disable the firewall unless we explicitly take down the vpn
# ufw disable
