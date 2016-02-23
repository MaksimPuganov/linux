#!/bin/bash

if [ "$UID" != "0" ]; then
	echo "Must be executed as root!"
	exit 1
fi

function setupOracleJre() {
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
	"http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jre-7u80-linux-x64.rpm"

	sudo yum localinstall -y jre-7u80-linux-x64.rpm
	rm jre-7u80-linux-x64.rpm
	update-alternatives --install /usr/bin/java java /usr/java/latest/bin/java 1
	update-alternatives --set java /usr/java/latest/bin/java

	yes | cp /usr/java/latest/lib/security/US_export_policy.jar /usr/java/latest/lib/security/local_policy.jar
}

function disableSecurity() {
	# allow sudo without a tty
	sed 's/^Defaults[ \t]\+requiretty/#Defaults   requiretty/' -i /etc/sudoers
	sed 's/^Defaults[ \t]\+!visiblepw/#Defaults   !visiblepw/' -i /etc/sudoers
}

function installBasePackages() {
	yum clean all

	# freetds / libaio for oracle sql server
	yum install -y telnet unzip curl wget freetds libaio subversion 
	yum update -y
}

function configureEpelRepo() {
	wget http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6
	rpm --import RPM-GPG-KEY-EPEL-6
	rm -f RPM-GPG-KEY-EPEL-6
	wget http://ftp.riken.jp/Linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
	sudo yum localinstall -y epel-release-6-8.noarch.rpm
	rm epel-release-6-8.noarch.rpm
}

function setupLdap() {
	yum clean all
	yum install -y 389-ds-base 389-admin
	sed -i '/127.0.0.1[[:space:]]\+localhost/c\127.0.0.1 localhost.localdomain localhost' /etc/hosts
	useradd dirsrv
	setup-ds-admin.pl -s -f setup.inf
	ldapadd -xc -D "cn=Directory Manager" -w secret -h localhost -p 389 -f root.ldif

	# dirsrv is not enabled by default, but it is already started, so this is just for next boot
	chkconfig dirsrv on
}

installBasePackages

configureEpelRepo

disableSecurity

setupLdap

setupOracleJre

echo "Complete!"

