#!/bin/bash

/etc/openvpn/update-resolv-conf $@

ufw disable
