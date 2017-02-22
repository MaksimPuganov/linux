#!/bin/bash

if [ $(ls /home/wordpress/*-db-*.zip 2>/dev/null | wc -l) -ne 1 ]; then
	echo "Missing db backup file"
	exit 1
fi

if [ $(ls /home/wordpress/*-full-*.zip 2>/dev/null | wc -l) -ne 1 ]; then
	echo "Missing web site backup"
	exit 1
fi

WS_BACKUP="$(ls /home/wordpress/*-full-*.zip)"
DB_BACKUP="$(ls /home/wordpress/*-db-*.zip)"

sudo rm -rf /var/www/html
sudo mkdir /var/www/html
sudo unzip -o -q $WS_BACKUP -d /var/www/html

if [ -f /var/www/html/.htaccess.txt ]; then
	sudo rm /var/www/html/.htaccess.txt
fi

if [ -f /var/www/html/.ftpquota.txt ]; then
	sudo rm /var/www/html/.ftpquota.txt
fi

sudo find /var/www/html -type d -exec chmod ugo+rx {} \;
sudo find /var/www/html -type f -exec chmod ugo+r {} \;
sudo chown -R wordpress:www-data /var/www/html
sudo chown wordpress:www-data /var/www/html/.htaccess
sudo chown wordpress:www-data /var/www/html/.ftpquota

RESULT=$(find /var/www/html -name "*.php" -exec grep -l "www.aqi.edu.au" {} \;)
for i in $RESULT; do
	sudo sed -i "s:http\://www.aqi.edu.au/:/:g" $i
done

RESULT=$(find /var/www/html -name "*.php" -exec grep -l "www.aqi.net.au" {} \;)
for i in $RESULT; do
	sudo sed -i "s:http\://www.aqi.net.au/:/:g" $i
done

sed -i "s:^define('DB_USER'.*:define('DB_USER', 'aqidb');:g" /var/www/html/wp-config.php
sed -i "s:^define('DB_NAME'.*:define('DB_NAME', 'aqidb');:g" /var/www/html/wp-config.php
sed -i "s:^define('DB_PASSWORD'.*:define('DB_PASSWORD', 'password');:g" /var/www/html/wp-config.php

mkdir /tmp/db-$$
unzip -q $DB_BACKUP -d /tmp/db-$$

RESULT=$(find /tmp/db-$$ -name "*.sql" -exec grep -l "www.aqi.edu.au" {} \;)
for i in $RESULT; do
	# ignore download tracking, as its a log we don't need to rewrite the urls here
	if [ $(echo $i | grep "wp_downloadtracking.sql" | wc -l) -eq 0 ]; then
		sed -i "s:http\://www.aqi.edu.au/:/:g" $i
	fi
done

RESULT=$(find /tmp/db-$$ -name "*.sql" -exec grep -l "www.aqi.net.au" {} \;)
for i in $RESULT; do
	# ignore download tracking, as its a log we don't need to rewrite the urls here
	if [ $(echo $i | grep "wp_downloadtracking.sql" | wc -l) -eq 0 ]; then
		sed -i "s:http\://www.aqi.net.au/:/:g" $i
	fi
done

cat /tmp/db-$$/*.sql > /home/wordpress/db.sql

# lets not expose the current web site details
echo "drop user 'aqidb'@'localhost'" | mysql -s -u root --password=password 
echo "drop database aqidb" | mysql -s -u root --password=password
echo "create database aqidb" | mysql -s -u root --password=password
echo "CREATE USER 'aqidb'@'localhost' IDENTIFIED BY 'password'" | mysql -s -u root --password=password mysql
echo "GRANT ALL PRIVILEGES ON aqidb.* TO 'aqidb'@'localhost';" | mysql -s -u root --password=password mysql
echo "FLUSH PRIVILEGES;" | mysql -s -u root --password=password mysql

mysql -s -u root --password=password aqidb < /home/wordpress/db.sql
rm -rf /tmp/db-$$

echo "Setting Admin user 'Webadmin-clair' password to 'password'"
echo "update wp_users set user_pass = MD5('password') where user_login = 'Webadmin-clair'" | mysql -s -u root --password=password aqidb

ETH_DEVICE=$(ip link | grep ": e" | tr ':' ' ' | awk '{print $2}')
IP_ADDRESS=$(ip addr show dev $ETH_DEVICE | sed -nr "s/.*inet ([^/]+).*/\1/p")
SCRIPT="update wp_options set option_value = 'http://$IP_ADDRESS' where option_name in ('siteurl', 'home')"
echo $SCRIPT | mysql -u root --password=password aqidb 2>/dev/null

sudo systemctl restart apache2
