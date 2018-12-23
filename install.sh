#!/bin/bash
#version: 1.1.2
# updated fresh install script, now installs everything needed for a portable digital station
# Note: this is for the raspberry pi with a DRAWS Hat from nwdigitalradio
#taken from the NW Digital Radio group wiki on installing fldigi

# Testing Variable: 1 for initial trial and tests/config file updates (does NOT copy config files)
TESTING=1
# set flags first taken from http://www.kk5jy.net/fldigi-build/:
export CXXFLAGS='-O2 -march=native -mtune=native'
export CFLAGS='-O2 -march=native -mtune=native'

############################
## BUILD INSTALL FUNCTION ##
############################
# pauses between configure/make/install to allow user to double check install progress
Build_Install (){
	#note: static linking enabled, possibly do not need it as other libraries get loaded.
	#./configure --enable-static
	./configure
	read -n 1 -s -r -p "Press any key to continue"
	echo
	make
	read -n 1 -s -r -p "Press any key to continue"
	echo
	sudo make install
	read -n 1 -s -r -p "Press any key to continue"
	echo
}

######################
## Current versions ##
######################
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

####################
## Enable Sources ##
####################
#BEFORE INSTALL, get all the deps for it!!! this takes editing the source list file and other fun stuff
sudo cp /etc/apt/sources.list /etc/apt/sources.$FLDIGICUR.bkup
#dirty way of doing it
echo  "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
deb-src http://archive.raspbian.org/raspbian/ stretch main contrib non-free rpi
" | sudo tee /etc/apt/sources.list
echo "sources.list backed up to sources."$FLDIGICUR".bkup, please add any other sources from the old file to the new one that are not already in there"

############################
## Double check dtoverlay ##
############################
#check the dtoverlay for draws, if not then prompt the user and open the file for editing
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
################
## DEP & LIBS ##
################
#update and build the deps for fldigi
sudo apt-get update
sudo apt-get build-dep fldigi -y
sudo apt-get remove imagemagick -y
#apparently some files are missing, adding in a bunch of dependencies that might be needed from http://www.kk5jy.net/fldigi-build/:
sudo apt-get install libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev libmotif-dev gpsman gpsd gpsd-clients python-gps pps-tools libgps-dev chrony graphicsmagick libgraphicsmagick1-dev festival festival-dev shapelib libshp-dev libpcre3-dev libproj-dev libdb-dev python-dev libwebp-dev libgeotiff-dev -y

#make sure in home directory
cd ~
#grab the scripts
git clone https://github.com/nwdigitalradio/n7nix
#install the base files
cd n7nix/config
sudo ./core_install.sh

#note: install script sets audio levels automatiaclly
###############
## FLDIGI    ##
###############
cd ~
wget https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz
tar -zxvsf fldigi-$FLDIGICUR.tar.gz
cd fldigi-$FLDIGICUR
Build_Install
cp data/fldigi.desktop ~/Desktop/
cp data/flarq.desktop ~/Desktop/
###############
## FLAMP     ##
###############
cd ~
wget -N https://sourceforge.net/projects/fldigi/files/flamp/flamp-$FLAMPCUR.tar.gz
tar -zxvsf flamp-$FLAMPCUR.tar.gz
cd flamp-$FLAMPCUR
Build_Install
cp data/flamp.desktop ~/Desktop
###############
## FLMSG     ##
###############
cd ~
wget https://sourceforge.net/projects/fldigi/files/flmsg/flmsg-$FLMSGCUR.tar.gz
tar -zxvsf flmsg-$FLMSGCUR.tar.gz
cd flmsg-$FLMSGCUR
Build_Install
cp data/flmsg.desktop ~/Desktop/

###############
## XASTIR    ##
###############
#note: use graphicsmagick, install above with all dep, remove imagemagick
cd ~
git clone https://github.com/xastir/xastir
cd xastir
./bootstrap.sh
./configure
#ask if it configured correctly
read -n 1 -s -r -p "Check configuration, Press any key to continue or ctrl+c to exit"
echo
make
sudo make install

##################
## config files ##
##################
if [ $TESTING == 0 ]
then
	#copy all config files
	cd ~
	cp ./DRAWS/direwolf.conf ./direwolf.conf
	cp ./DRAWS/fldigi/fldigi_def.xml ./.fldigi/fldigi_def.xml
	cp ./DRAWS/xastir/* ./.xastir/config

fi
sudo cp ./DRAWS/gpsd /etc/default/gpsd
sudo cp ./DRAWS/chrony.conf /etc/chrony/chrony.conf
#########################
## GPS & CHRONY DAEMON ##
#########################
sudo systemctl enable gpsd && sudo systemctl restart gpsd
sudo systemctl enable chrony && sudo systemctl restart chrony && systemctl status chrony

echo "GPS daemon ready, run 'gpsmon' to check gps"
echo "Chrony is ready, run 'chronyc sources' to verify"
read -n 1 -s -r -p "Press any key to continue"
echo
#check for DRAWS:
echo "checking DRAWS eeprom version...."
draws="Digital Radio Amateur Work Station"
outvar=$(tr -d '\0' </sys/firmware/devicetree/base/hat/product)
if [ "$draws" == "$outvar" ]
then
	echo "yep, you have a DRAWS Hat"
else
	echo "nope, you do not have a DRAWS Hat! Modifications this script made may NOT work!!"
fi
