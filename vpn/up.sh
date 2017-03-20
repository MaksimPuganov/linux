#!/bin/bash

/etc/openvpn/update-resolv-conf $@

ufw reset
ufw disable

# deny everything
ufw default deny outgoing
ufw default deny incoming

# allow everything via the tunnel
ufw allow out on tun0 from any to any
ufw allow in on tun0 from any to any

ufw allow out to 192.168.0.3
ufw allow out to 192.168.0.9
ufw allow out to 192.168.0.69

ufw enable

