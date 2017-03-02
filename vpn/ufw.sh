sudo ufw reset
sudo ufw disable

# deny everything
sudo ufw default deny outgoing
sudo ufw default deny incoming

# allow everything via the tunnel
sudo ufw allow out on tun0 from any to any
sudo ufw allow in on tun0 from any to any

# allow access to the VPN server
sudo ufw allow in from 46.36.203.7
sudo ufw allow out to 46.36.203.7

sudo ufw allow in to 192.168.0.0/24
sudo ufw allow out to 192.168.0.0/24

sudo ufw allow out 1194/udp

sudo ufw enable

