#!/bin/bash
#version: 1.1.1
# updated fresh install script, now installs everything needed for a portable digital station
# Note: this is for the raspberry pi with a DRAWS Hat from nwdigitalradio
#taken from the NW Digital Radio group wiki on installing fldigi

# set flags first taken from http://www.kk5jy.net/fldigi-build/:
export CXXFLAGS='-O2 -march=native -mtune=native'
export CFLAGS='-O2 -march=native -mtune=native'

Build_Install (){
	#note: static linking enabled, possibly do not need it as other libraries get loaded.
	./configure --enable-static
	make
	sudo make install
}

FLDIGICUR=4.0.18
FLAMPCUR=2.2.03
FLMSGCUR=4.0.7
echo "This script will install all software nessecay for the DRAWS, it will pull down and run the NW digital radio script from the github repository"
echo "This script will also install the following versions of fldigi/flamp/flmsg:"
echo "fldigi: " $FLDIGICUR
echo "flamp: " $FLAMPCUR
echo "flmsg: " $FLMSGCUR
read -n 1 -s -r -p "Press any key to continue, ctrl+c to quit"
echo

#BEFORE INSTALL, get all the deps for it!!! this takes editing the source list file and other fun stuff
sudo cp /etc/apt/sources.list /etc/apt/sources.$FLDIGICUR.bkup
#dirty way of doing it
echo  "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
deb-src http://archive.raspbian.org/raspbian/ stretch main contrib non-free rpi
" | sudo tee /etc/apt/sources.list
echo "sources.list backed up to sources."$FLDIGICUR".bkup, please add any other sources from the old file to the new one that are not already in there"

#check the dtoverlay for draws, if not then prompt the user and open the file for editing
#NEW ISSUE: with compass 4.9.80-v7 udrc is broken! must add 'dtoverlay=' and 'dtoverlay=udrc' to the END of /boot/config.txt
#check for dtoverlay:
if !(grep -x "dtoverlay=" /boot/config.txt && grep -x "dtoverlay=draws" /boot/config.txt); then
	echo "draws not detected, opening boot config for editing, page down to the end and change 'udrc' to 'draws'"
	echo
	read -n 1 -s -r -p "Press any key to edit the file"
	sudo nano /boot/config.txt
	echo
else
	echo "dtoverlay lines found, continuing with install"
fi
read -n 1 -s -r -p "Press any key to continue"
echo

#update and build the deps for fldigi
sudo apt-get update
sudo apt-get build-dep fldigi -y

#apparently some files are missing, adding in a bunch of dependencies that might be needed from http://www.kk5jy.net/fldigi-build/:
sudo apt-get install libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev

#make sure in home directory
cd ~
#grab the scripts
git clone https://github.com/nwdigitalradio/n7nix
#install the base files
cd n7nix/config
sudo ./core_install.sh

#copy the 'default' config file
cd ~
cp ./DRAWS/direwolf.conf ./direwolf.conf

#note: install script sets audio levels automatiaclly

#get current version of fldigi
wget -N https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz
tar -zxvsf fldigi-$FLDIGICUR.tar.gz
cd fldigi-$FLDIGICUR
# now we can configure and install
Build_Install
# cpy the desktop shortcuts
cp data/fldigi.desktop ~/Desktop/
cp data/flarq.desktop ~/Desktop/
#install flamp
cd ~
wget -N https://sourceforge.net/projects/fldigi/files/flamp/flamp-$FLAMPCUR.tar.gz
tar -zxvsf flamp-$FLAMPCUR.tar.gz
cd flamp-$FLAMPCUR
Build_Install
cp data/flamp.desktop ~/Desktop
#install flmsg
cd ~
wget -N https://sourceforge.net/projects/fldigi/files/flmsg/flmsg-$FLMSGCUR.tar.gz
tar -zxvsf flmsg-$FLMSGCUR.tar.gz
cd flmsg-$FLMSGCUR
Build_Install
cp data/flmsg.desktop ~/Desktop/

#install xastir, gps and chrony
sudo apt-get install xastir gpsd gpsd-clients python-gps pps-tools libgps-dev chrony -y

#copy all config files
cd ~
cp ./DRAWS/fldigi/fldigi_def.xml ./.fldigi/fldigi_def.xml
cp ./DRAWS/xastir/* ./.xastir/config
sudo cp ./DRAWS/gpsd /etc/default/gpsd
sudo cp ./DRAWS/chrony.conf /etc/chrony/chrony.conf

#enable gps daemon:
sudo systemctl enable gpsd && sudo systemctl restart gpsd
echo "GPS daemon ready, run 'gpsmon' to check gps"
read -n 1 -s -r -p "Press any key to continue"
echo
#check for DRAWS:
echo "checking DRAWS eeprom version...."
draws="Digital Radio Amateur Work Station"
outvar=`cat /sys/firmware/devicetree/base/hat/product`
if [ "$draws" == "$outvar" ]
then
echo "yep, you have a DRAWS Hat"
else
echo "nope, you do not have a DRAWS Hat! Modifications this script made may NOT work!!"
fi


