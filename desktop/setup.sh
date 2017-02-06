#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function addToGsettingsList() {
    local schema=$1
	local key=$2
    local value=$3

    list=$(gsettings get $schema $key)
    if [ $(echo "$list" | grep "'$value'" | wc -l) -eq 0 ]; then
	    list=$(echo $list | sed 's/]//g')
	    list+=", '$value']"
	    gsettings set $schema $key "$list"
    else
        echo "Value $value already in list"
    fi
}

function removeFromGsettingsList() {
	 local schema=$1
	local key=$2
    local remove=$3

	value=$(gsettings get $schema $key)
	if [ $? -eq 0 ]; then
		# fixme, delete multiple characters
		entries=($(echo $value | tr -d '[' | tr -d ']' | tr -d ',' | tr -d "'"))

		output='['
		for entry in "${entries[@]}"; do
			if [ "$entry" != "$remove" ]; then
				if [ "$output" != "[" ]; then
					output+=", "
				fi
				output+="'$entry'"
			fi
		done
		output+=']'
		gsettings set $schema $key "$output"
	else
		echo "Entry $schema $key not found"
		exit 1
	fi
}

function addToFavourites() {
	if [ -f ~/.config/mate-menu/applications.list ]; then
		if [ -f ~/.local/share/applications/$1.desktop ]; then
			echo "location:~/.local/share/applications/$1.desktop" >> ~/.config/mate-menu/applications.list
		else
			echo "location:/usr/share/applications/$1.desktop" >> ~/.config/mate-menu/applications.list
		fi
	fi
}

function disableStartupApp() {
	if [ -f /etc/xdg/autostart/$1.desktop ]; then
		if [ ! -d ~/.config/autostart ]; then
			mkdir -p ~/.config/autostart
		fi

		cp /etc/xdg/autostart/$1.desktop ~/.config/autostart
		echo "X-MATE-Autostart-enabled=false" >> ~/.config/autostart/$1.desktop
	fi
}

function setupBasePackages() {
	sudo apt-get update
	sudo apt-get install -y software-properties-common

	sudo dpkg --add-architecture i386
	
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
	sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
	sudo sh -c 'echo "deb http://apt.insynchq.com/ubuntu xenial non-free contrib" > /etc/apt/sources.list.d/insync.list'

	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
	sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list.d/virtual-box.list'

	wget -q https://dl.sinew.in/keys/enpass-linux.key -O- | sudo apt-key add -
	sudo sh -c 'echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list'

	sudo apt-add-repository -y ppa:ubuntu-mate-dev/xenial-mate
	sudo add-apt-repository -y ppa:ubuntu-desktop/ubuntu-make	
	sudo add-apt-repository -y ppa:heyarje/makemkv-beta
	sudo add-apt-repository -y ppa:stebbins/handbrake-releases
	sudo add-apt-repository -y ppa:team-xbmc/ppa
	sudo add-apt-repository -y ppa:webupd8team/java

	sudo apt-get update

	sudo apt-get -y dist-upgrade 

	sudo apt-get install -y enpass libnss-mdns:i386 dkms makemkv-bin makemkv-oss handbrake-gtk nmap google-chrome-stable gdebi kodi kodi-pvr-hts insync insync-caja git ubuntu-make nodejs nodejs-legacy npm

	sudo apt-get install -y virtualbox-5.1 oracle-java8-installer libdvd-pkg ubuntu-restricted-extras
	sudo dpkg-reconfigure libdvd-pkg

	addToFavourites google-chrome
	addToFavourites makemkv
	addToFavourites ghb
	addToFavourites kodi

	LATEST=$(wget -q http://download.virtualbox.org/virtualbox/LATEST.TXT -O-)
	wget http://download.virtualbox.org/virtualbox/$LATEST/Oracle_VM_VirtualBox_Extension_Pack-$LATEST.vbox-extpack -O Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack
	VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack

	wget http://crossover.codeweavers.com/redirect/crossover.deb
	sudo gdebi crossover.deb
	sudo /opt/cxoffice/bin/cxregister --install $DIR/cxoffice/license.txt $DIR/cxoffice/license.sig 

	sudo usermod -a -G vboxusers jason
	
	mkdir -p ~/.MakeMKV
	echo "app_Key =\"M-mvZBv5dn5ZBO10g6PZtOW_psrcri2MmdLkIki1@iq3HTR5bU7gPKSaFJPOcBtkkHL6\"" > ~/.MakeMKV/settings.conf

	# https://github.com/ubuntu/ubuntu-make/issues/79
	sudo chgrp jason /opt
	sudo chmod g+w /opt
	umake --accept-license android android-studio /opt/android-studio
	addToFavourites android-studio
}

function customiseMate() {
	disableStartupApp deja-dup-monitor
	disableStartupApp mate-power-manager
	disableStartupApp mate-optimus-applet
	disableStartupApp orca-autostart

	if [ ! -d "~/.local/share/applications" ]; then
		mkdir -p ~/.local/share/applications
	fi

	if [ -f "~/.config/user-dirs.dirs" ]; then
		sed -i '/XDG_MUSIC_DIR=/d' ~/.config/user-dirs.dirs
		sed -i '/XDG_PICTURES_DIR=/d' ~/.config/user-dirs.dirs
		sed -i '/XDG_VIDEOS_DIR=/d' ~/.config/user-dirs.dirs

		echo 'XDG_MUSIC_DIR="$HOME"' >> ~/.config/user-dirs.dirs
		echo 'XDG_PICTURES_DIR="$HOME"' >> ~/.config/user-dirs.dirs
		echo 'XDG_VIDEOS_DIR="$HOME"' >> ~/.config/user-dirs.dirs
	fi

	if [ ! -d ~/.config/mate-menu ]; then
		mkdir -p ~/.config/mate-menu
	fi

	if [ ! -f ~/.config/mate-menu/applications.list ]; then
		cp /usr/share/mate-menu/applications.list ~/.config/mate-menu/applications.list
	fi

	menus=(galculator thunderbird pidgin rhythmbox mate-volume-control mate-display-properties mate-system-monitor)
	for menu in "${menus[@]}"; do
		sed -i "/location:\/usr\/share\/applications\/$menu.desktop/d" ~/.config/mate-menu/applications.list
	done

	gsettings set org.mate.pluma color-scheme classic
	   
	gsettings set org.mate.terminal.profile:/org/mate/terminal/profiles/default/ scrollback-unlimited true

	gsettings set org.mate.mate-menu start-with-favorites true

	gsettings set "org.mate.panel.object:/org/mate/panel/objects/mate-menu/" applet-iid "MateMenuAppletFactory::MateMenuApplet"
	gsettings set "org.mate.panel.object:/org/mate/panel/objects/mate-menu/" locked 'true'
	gsettings set "org.mate.panel.object:/org/mate/panel/objects/mate-menu/" object-type 'applet'
	gsettings set "org.mate.panel.object:/org/mate/panel/objects/mate-menu/" position 0
	gsettings set "org.mate.panel.object:/org/mate/panel/objects/mate-menu/" toplevel-id 'top'

	gsettings set org.mate.panel default-layout 'ubuntu-mate-fresh'
	gsettings set org.mate.panel object-id-list "['mate-menu', 'firefox', 'notification-area', 'clock', 'shutdown', 'show-desktop', 'window-list', 'workspace-switcher', 'trashapplet']"
	
	# https://github.com/mate-desktop/mate-utils/issues/37
	sudo cp $DIR/mate-screenshot /usr/local/bin
	chmod 777 /usr/local/bin/mate-screenshot

	gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ name 'Screenshot Area'
	gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ action 'bash -c "DISPLAY=:0 mate-screenshot -a"'
	gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ binding '<Shift>Print'

	mate-panel --replace &
}

function setupGithubDev() {
	ssh-keyscan -H github.com >> ~/.ssh/known_hosts
	git --global config credential.helper cache
	git config credential.helper 'cache --timeout=1800'
	git config --global user.name "Jason Pell"
	git config --global user.email jason@pellcorp.com
	git config --global alias.st status 
	git config --global alias.ci commit 

	if [ $(cat ~/.bashrc | grep "git-prompt.sh" | wc -l) -eq 0 ]; then
		mkdir ~/bin
		wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O ~/bin/git-prompt.sh
		echo "source ~/bin/git-prompt.sh" >> ~/.bashrc
		echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;34m\] \w\[\033[01;32m\]\$(__git_ps1) \[\033[01;34m\]\$\[\033[00m\] "' >> ~/.bashrc
	fi

	mkdir -p Development/Github
	cd Development/Github
	git clone git@github.com:pellcorp/maven2.git
	git clone git@github.com:pellcorp/linux.git

}

sudo sh -c 'echo "%sudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd'
ssh-keygen -f ~/.ssh/id_rsa -C jason@pellcorp.com -N ''

customiseMate
setupBasePackages
setupGithubDev

if [ ! -d /opt/data ]; then
	sudo mkdir /opt/data
fi

if [ $(cat /etc/fstab | grep "/opt/data" | wc -l) -eq 0 ]; then
	sudo su -c 'echo "UUID=68fefbe5-d301-427f-a81f-24bfc700b133 /opt/data     ext4    user,errors=remount-ro 0       1" >> /etc/fstab'
fi

mount /opt/data

rm -rf ~/Videos
ln -s /opt/data/Videos

rm -rf ~/Music
ln -s /opt/data/Google\ Drive/Music/

