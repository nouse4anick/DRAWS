#!/bin/bash
# version 1.0.3
# this script updates a previous install script from a past install
# you should NOT use this script if you are starting out fresh!
# 
#current/past versions:
#note: this script will SKIP any item that has the same current and previous version numbers!
echo "This script will uninstall old versions of fldigi, flamp, and flmsg if found and update to defined version. Please double check to make sure the current versions are correct:"

FLDIGICUR=4.0.16
FLDIGIPREV=4.0.6

FLAMPCUR=2.2.03
FLAMPPREV=2.2.03

FLMSGCUR=4.0.6
FLMSGPREV=4.0.2

echo "Current versions:"
echo "fldigi: " $FLDIGICUR
echo "flamp: " $FLAMPCUR
echo "flmsg: " $FLMSGCUR

read -n 1 -s -r -p "Press any key to continue, ctrl+c to quit"
echo

#BEFORE INSTALL, get all the deps for it!!! this takes editing the source list file and other fun stuff
sudo cp /etc/apt/sources.list /etc/apt/sources.$FLDIGICUR.bkup
#dirty way of doing it
echo  "deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
deb-src http://archive.raspbian.org/raspbian/ jessie main contrib non-free rpi
" | sudo tee /etc/apt/sources.list
echo "sources.list backed up to sources."$FLDIGICUR".bkup, please add any other sources from the old file to the new one that are not already in there"
#tried to use sed and tee to remove the 3rd line but no go =(
#best method would be to just append the deb-src line to the bottom of the list but that also has issues
#sudo sed '3,3s/.//' /etc/apt/sources.list | sudo tee /etc/apt/sources.list
#NEW ISSUE: with compass 4.9.80-v7 udrc is broken! must add 'dtoverlay=' and 'dtoverlay=udrc' to the END of /boot/config.txt
#check for dtoverlay:
if !(grep -x "dtoverlay=" /boot/config.txt && grep -x "dtoverlay=udrc" /boot/config.txt); then
	#not found, insert it:
	echo "dtoverlay=" | sudo tee -a /boot/config.txt
	echo "dtoverlay=udrc" | sudo tee -a /boot/config.txt
	echo "dtoverlay lines added to /boot/config.txt, please check for correctness after install and reboot."
else
	echo "dtoverlay lines found, continuing with install"
fi
read -n 1 -s -r -p "Press any key to continue"
echo
#update and build the deps for fldigi
sudo apt-get update
sudo apt-get build-dep fldigi -y

cd ~
if [ "$FLDIGIPREV" != "$FLDIGICUR" ]; then
	if [ -d "~/fldigi-$FLDIGIPREV" ]; then
		cd ~/fldigi-$FLDIGIPREV
		sudo make uninstall
		cd ..
	fi
	#download and install the new one
	wget -N https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz
	tar -zxvsf fldigi-$FLDIGICUR.tar.gz
	cd fldigi-$FLDIGICUR

	# now we can configure and install
	./configure
	make
	sudo make install
	# cpy the desktop shortcuts
	cp data/fldigi.desktop ~/Desktop/
	cp data/flarq.desktop ~/Desktop/
fi
#install flamp and flmsg
cd ~
if [ "$FLAMPPREV" != "$FLAMPCUR" ]; then
	if [ -d "~/flamp-$FLAMPPREV" ]; then
		cd flamp-$FLAMPPREV
		sudo make uninstall
		cd ..
	fi
	wget -N https://sourceforge.net/projects/fldigi/files/flamp/flamp-$FLAMPCUR.tar.gz
	tar -zxvsf flamp-$FLAMPCUR.tar.gz
	cd flamp-$FLAMPCUR
	./configure
	make
	sudo make install
	cp data/flamp.desktop ~/Desktop
fi
if [ "$FLMSGPREV" != "$FLMSGCUR" ]; then
	if [ -d "~/flmsg-$FLMSGPREV" ]; then
		cd flmsg-$FLMSGPREV
		sudo make uninstall
		cd ..
	fi
	wget -N https://sourceforge.net/projects/fldigi/files/flmsg/flmsg-$FLMSGCUR.tar.gz
	tar -zxvsf flmsg-$FLMSGCUR.tar.gz
	cd flmsg-$FLMSGCUR
	./configure
	make
	sudo make install
	cp data/flmsg.desktop ~/Desktop/
fi

echo "update finished"
