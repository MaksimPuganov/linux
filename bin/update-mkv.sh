#!/bin/bash

# based on http://www.makemkv.com/forum2/viewtopic.php?f=3&t=9451

sudo apt-get -y install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev libqt4-dev

version=$(curl "http://www.makemkv.com/forum2/viewtopic.php?f=3&t=224" -s | awk 'FNR == 160 {print $4}')

# check if makemkvcon even exists
command -v makemkvcon > /dev/null 2>&1
if [ $? -eq 0 ]; then
	# use a invalid drive to just print the version info
	old_version=`makemkvcon -r info /dev/null 2> /dev/null | grep -oPm1 "([0-9]+\.[0-9]+\.[0-9]+)" | awk 'NR>1{print $1}'`

	if [ "$old_version" = "$version" ]; then
		echo "Version already latest"
		exit 0;
	fi
fi

wget http://www.makemkv.com/download/makemkv-oss-$version.tar.gz
wget http://www.makemkv.com/download/makemkv-bin-$version.tar.gz

rm -rf makemkv-oss-$version
rm -rf makemkv-bin-$version
tar -xzvf makemkv-oss-$version.tar.gz
tar -xzvf makemkv-bin-$version.tar.gz

cd makemkv-oss-$version
./configure
make
sudo make install
cd ../

cd makemkv-bin-$version
echo "" > src/ask_eula.sh
chmod 777 src/ask_eula.sh
make
sudo make install

rm -rf makemkv-oss-$version
rm -rf makemkv-bin-$version
rm makemkv-oss-$version.tar.gz
rm makemkv-bin-$version.tar.gz

MAKEMKV_KEY=`curl "http://www.makemkv.com/forum2/viewtopic.php?f=5&t=1053" -s | awk 'FNR == 243 {print $57}' | cut -c 21-88`

# check if xclip exists
command -v xclip > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo $KEY | xclip -selection clipboard
	makemkv
else
	echo "Make MKV Key is: $MAKEMKV_KEY"
	echo "Xclip not installed"
fi

