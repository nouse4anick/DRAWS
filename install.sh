#!/bin/bash
#version: 1.1.4
# updated fresh install script, now installs everything needed for a portable digital station
# Note: this is for the raspberry pi with a DRAWS Hat from nwdigitalradio

# New update!
# - functionised everything
# - will have command line arguments (basic reinstall type stuff)
# - added checks for 'fresh installs'... it checks to see if draws is initialized
# - added flwrap, possibly will add other  fl options
# - added checks for existing software

#disable the pause
QUICK=0
# set flags first taken from http://www.kk5jy.net/fldigi-build/:
export CXXFLAGS='-O2 -march=native -mtune=native'
export CFLAGS='-O2 -march=native -mtune=native'

Usage (){
	echo "usage: install.sh (args)
	Args can be:
	source : enables sources and installs base/essectial libraries
	FLDIGI : installs fldigi
	FLAMP : installs flamp
	FLMSG : installs flmsg
	FLWRAP : installs flwrap
	GPS : installs gps
	CHRONY : installs/sets up chrony
	xastir : installs xastir and direwolf
	fdlog : installs FDLog Enhanced
	check : does system check using n7nix's scripts
	flsuite : installs all fl programs (ie fldigi/amp/msg/wrap/etc)
	beta : installs anything left out of the new beta image from nw digital radio
	-h shows this help and exits"
	exit
}

############################
## BUILD INSTALL FUNCTION ##
############################
# pauses between configure/make/install to allow user to double check install progress
Build_Install (){
	#note: static linking enabled, possibly do not need it as other libraries get loaded.
	#./configure --enable-static
	./configure
	Press_Any_key
	make
	Press_Any_key
	sudo make install
	Press_Any_key
}
####################
## Press continue ##
####################
Press_Any_key (){
	if [ $QUICK == 0 ]; then
		read -n 1 -s -r -p "Press any key to continue"
		echo
	fi
}
####################
## Enable Sources ##
####################
Enable_Sources () {
	#maybe check to see if the source list has already been backed up or fixed and skip?
	if grep "#deb-src" /etc/apt/sources.list
	then
		sudo cp /etc/apt/sources.list /etc/apt/sources.$FLDIGICUR.bkup
		#dirty way of doing it
echo  "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
deb-src http://archive.raspbian.org/raspbian/ stretch main contrib non-free rpi
" | sudo tee /etc/apt/sources.list
	
	echo "sources.list backed up to sources."$FLDIGICUR".bkup, please add any other sources from the old file to the new one that are not already in there"
	else
		echo "sources already enabled"
	fi
	# always update and upgrade:
	sudo apt-get update
	sudo apt-get upgrade -y
	# favorate apps:
	sudo apt-get install geany -y
	# Needed items from the nwdigital scripts:
	sudo apt-get install rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev scons -y
	Press_Any_key
}
############################
## Double check dtoverlay ##
############################
Check_overlay () {
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
	Press_Any_key
}
###############
## FLDIGI    ##
###############
FLDIGI_source () {
	#grab any dep we forget:
	sudo apt-get build-dep fldigi -y 
	# from http://www.kk5jy.net/fldigi-build/, make sure they are installed
	sudo apt-get install libfltk1.3-dev -y
	sudo apt-get install libjpeg9-dev -y
	sudo apt-get install libxft-dev -y
	sudo apt-get install libxinerama-dev -y
	sudo apt-get install libxcursor-dev -y
	sudo apt-get install libsndfile1-dev -y
	sudo apt-get install libsamplerate0-dev -y
	sudo apt-get install portaudio19-dev -y
	sudo apt-get install libusb-1.0-0-dev -y
	sudo apt-get install libpulse-dev -y
	echo "please check that all dep are installed"
	Press_Any_key
	cd ~
	wget https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz
	if [ $? -ne 0 ] ; then
		echo "download for FLDIGI failed! exiting...."
		exit 1
	fi
	tar -zxvsf fldigi-$FLDIGICUR.tar.gz
	cd fldigi-$FLDIGICUR
	Build_Install
	cp data/fldigi.desktop ~/Desktop/
	cp data/flarq.desktop ~/Desktop/
	cd ~
	# current settings for fldigi:
	# set soundcard capture
	# right channel NO check box
	# gpio: bcm 12 (gpio 26/pin 32)
	
	cp ~/DRAWS/fldigi/fldigi_def.xml ~/.fldigi/fldigi_def.xml
	cp ~/DRAWS/fldigi/macros.mdf ~/.fldigi/macros/macros.mdf
}
###############
## FLAMP     ##
###############
FLAMP_source () {
	cd ~
	wget -N https://sourceforge.net/projects/fldigi/files/flamp/flamp-$FLAMPCUR.tar.gz
	if [ $? -ne 0 ] ; then
		echo "download for FLAMP failed! exiting...."
		exit 1
	fi
	tar -zxvsf flamp-$FLAMPCUR.tar.gz
	cd flamp-$FLAMPCUR
	Build_Install
	cp data/flamp.desktop ~/Desktop
}
###############
## FLMSG     ##
###############
FLMSG_source () {
	cd ~
	wget https://sourceforge.net/projects/fldigi/files/flmsg/flmsg-$FLMSGCUR.tar.gz
	if [ $? -ne 0 ] ; then
		echo "download for FLMSG failed! exiting...."
		exit 1
	fi
	tar -zxvsf flmsg-$FLMSGCUR.tar.gz
	cd flmsg-$FLMSGCUR
	Build_Install
	cp data/flmsg.desktop ~/Desktop/
}
###############
## FLWRAP    ##
###############
FLWRAP_source () {
	cd ~
	wget https://sourceforge.net/projects/fldigi/files/flwrap/flwrap-$FLWRAP.tar.gz
	if [ $? -ne 0 ] ; then
		echo "download for FLWRAP failed! exiting...."
		exit 1
	fi
	tar -zxvsf flwrap-$FLWRAP.tar.gz
	cd flwrap-$FLWRAP
	Build_Install
	cp data/flwrap.desktop ~/Desktop/
}
##########
## GPSD ##
##########
GPSD_install (){
	#gpsd version check: gpsd -V
	# check version and remove if nessecary and install new version
	# output is: gpsd: 3.18.1 (revision 3.18.1)
	curver="$(gpsd -V)"
	if [ $curver == "gpsd: 3.18.1 (revision 3.18.1)" ]; then
		echo "current version of gpsd installed"
		return
	else
		echo "Another version is installed: $curver"
		Press_Any_key
	fi
	# its not up to date, 
	sudo apt-get remove gpsd -y
	# gpsd from repository is outdated, download new one and compile/install
	cd ~
	wget http://download.savannah.nongnu.org/releases/gpsd/gpsd-3.18.1.tar.gz
	if [ $? -ne 0 ] ; then
		echo "download for GPSD failed! exiting...."
		exit 1
	fi
	tar -zxvsf gpsd-3.18.1.tar.gz
	cd gpsd-3.18.1
	scons && scons check && sudo scons udev-install
	cd ~
	sudo cp ~/DRAWS/gpsd /etc/default/gpsd
	sudo systemctl unmask gpsd.service && sudo systemctl unmask gpsd.socket && sudo systemctl enable gpsd && sudo systemctl restart gpsd
	echo "GPS daemon ready, run 'gpsmon' to check gps, if it doesn't work reboot"
	Press_Any_key
}
###################
## CHRONY DAEMON ##
###################
chrony_setup (){
	# chrony installed from repository
	sudo dpkg -l | grep "chrony" > /dev/null
	if [ $? -eq 0 ]; then
		echo "chrony installed, assuming already set up"
		Press_Any_key
		return
	fi
	sudo apt-get install chrony -y
	sudo cp ~/DRAWS/chrony.conf /etc/chrony/chrony.conf
	sudo systemctl enable chrony && sudo systemctl restart chrony && systemctl status chrony
	echo "Chrony is ready, run 'chronyc sources' to verify"
	Press_Any_key
}
###############
## XASTIR    ##
###############
Xastir_install () {
	#note: use graphicsmagick, breaks with imagemagic
	sudo apt-get remove imagemagick -y
	#check for xastir
	sudo dpkg -l | grep 'xastir' > /dev/null
	xastircheck=$?
	if [ $xastircheck -eq 0 ]; then
		sudo apt-get remove xastir -y
	fi
	# install direwolf:
	#check to see if installed via repository:
	sudo dpkg -l | grep 'direwolf' > /dev/null
	dpkgcheck=$?
	whereis direwolf > /dev/null
	whereischeck=$?
	if [ $dpkgcheck -eq 1 && $whereischeck -eq 1 ]; then
		echo "direwolf is not installed. Installing from repository"
		sudo apt-get install direwolf -y
	else
		echo "direwolf is installed, version not determined, continuing with xastir install"
	fi
	#build list taken from https://xastir.org/index.php/HowTo:Raspbian_Jessie
	sudo apt-get install xorg-dev graphicsmagick gv libmotif-dev libcurl4-openssl-dev -y
	sudo apt-get install libpcre3-dev libproj-dev libdb5.3-dev python-dev libax25-dev libwebp-dev libproj-dev -y
	sudo apt-get install shapelib libshp-dev festival festival-dev libgeotiff-dev libgraphicsmagick1-dev gpsman -y
	sudo apt-get install xfonts-100dpi xfonts-75dpi -y
	xset +fp /usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/75dpi
	Press_Any_key
	cd ~
	git clone https://github.com/xastir/xastir.git
	cd xastir
	./bootstrap.sh
	./configure CPPFLAGS="-I/usr/include/geotiff"
	#ask if it configured correctly
	read -n 1 -s -r -p "Check configuration, Press any key to continue or ctrl+c to exit"
	echo
	make
	sudo make install
	# so xastir programmers are not lazy, but the binary install is, check to see if xastir.cnf exists, if it does move it to a backup and delete it.
	if [[ -e "~/.xastir/config/xastir.cnf" ]]; then
		echo "previous xastir config file detected, backing up file"
		mv ~/.xastir/config/xastir.cnf ~/.xastir/config/xastir.cnf.bkup
	fi
	#copy all config files
	cd ~
	cp ~/DRAWS/direwolf.conf ~/direwolf.conf
	cp ~/DRAWS/xastir/xastir.cnf ~/.xastir/config/xastir.cnf
	cp ~/DRAWS/desktop/xastir.desktop ~/Desktop/xastir.desktop
	cp ~/DRAWS/desktop/direwolf.desktop ~/Desktop/direwolf.desktop
	
	
}
#############
## js8call ##
#############
js8call_source () {
	#NOTE: no gpio support for fldigi. ignoring implementing for now, need to address this next month when 0.11.0 stops working.
	cd ~
	sudo apt-get install libqgsttools-p1 libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediaquick-p5 libqt5multimediawidgets5 libqt5qml5 libqt5quick5 libqt5serialport5 -y
	wget https://s3.amazonaws.com/js8call/0.11.0/js8call_0.11.0-devel_armhf.deb
	sudo dpkg -i js8call_0.11.0-devel_armhf.deb
	
}
####################
## fdlog_enhanced ##
####################
fdlog_install (){
	#installs fdlog from source:
	cd ~
	git clone https://github.com/scotthibbs/FDLog_Enhanced
	cp ./DRAWS/desktop/FDLog.desktop ./Desktop/FDLog.desktop
	
}
##################
## System Check ##
##################
System_check () {
	#run through checks for n7nix
	cd ~/n7nix
	if [ $? -ne 0 ] ; then
		echo "Errpr: nwdigial scrips not detected... exiting"
		exit 1
	fi
	echo "Running n7nix verify..."
	cd bin
	echo "backing up alsa settings and setting to default"
	./alsa-show.sh > ~/current-alsa-settings.txt
	sudo ./setalsa-default.sh
	echo "continuing with check..."
	./piver.sh
	Press_Any_key
	./udrcver.sh
	Press_Any_key
	~/bin/sndcard.sh
	Press_Any_key
	sensors
	Press_Any_key
	systemctl status chronyd
	Press_Any_key
	echo "testing gps using gpsmon, use ctrl+c to quit the monitor"
	Press_Any_key
	gpsmon
	echo "checking chrony sources..."
	chronyc sources
	Press_Any_key
	echo "testing AX25 protocols, test should come back as NOT ENABLED for all services for this install"
	ax25-status
	echo "Testing finished."
	exit 0
}
##############
## FL Suite ##
##############
FLSUITE (){
	#installs fl suite of programs:
	FLDIGI_source
	FLAMP_source
	FLMSG_source
	FLWRAP_source
}
##################
## Current beta ##
##################
Beta (){
	#installs does the cleanup/installs for beta 7 from nwdigital radio:
	FLMSG_source
	FLWRAP_source
	Xastir_install
	fdlog_install
	# copy files to the desktop and for xastir/fldigi:
	cp /usr/local/src/fldigi-$FLDIGICUR/data/fldigi.desktop ~/Desktop/
	cp /usr/local/src/fldigi-$FLDIGICUR/data/flarq.desktop ~/Desktop/
	# current settings for fldigi:
	# set soundcard capture
	# right channel NO check box
	# gpio: bcm 12 (gpio 26/pin 32)
	cp ~/DRAWS/fldigi/fldigi_def.xml ~/.fldigi/fldigi_def.xml
	cp ~/DRAWS/fldigi/macros.mdf ~/.fldigi/macros/macros.mdf
}

######################
## Current versions ##
######################
FLDIGICUR=4.0.18
FLAMPCUR=2.2.03
FLMSGCUR=4.0.7
FLWRAP=1.3.5
echo "To view optional arguments use './install.sh -h'"
echo "This script will install all software nessecay for the DRAWS, it will pull down and run the NW digital radio script from the github repository"
echo "This script will also install the following versions of fldigi/flamp/flmsg:"
echo "fldigi: " $FLDIGICUR
echo "flamp: " $FLAMPCUR
echo "flmsg: " $FLMSGCUR
echo "flwrap: " $FLWRAP
read -n 1 -s -r -p "Press any key to continue, ctrl+c to quit"
echo

############
## params ##
############

# params are:
# - source
# - fldigi
# - flmsg
# - flamp
# - gps
# - xastir (both xastir and direwolf
# - chrony
#  -h  help file
# if no params install everything

if [ $# -gt 0 ]; then
	#loop through commands and get them
	while [ "$1" != "" ]; do
		case $1 in
			"source" ) Enable_Sources ;;
			"FLDIGI" ) FLDIGI_source ;;
			"FLAMP" ) FLAMP_source ;;
			"FLMSG" ) FLMSG_source ;;
			"FLWRAP" ) FLWRAP_source ;;
			"GPS" ) GPSD_install ;;
			"CHRONY" ) chrony_setup ;;
			"xastir" ) Xastir_install ;;
			"fdlog" ) fdlog_install ;;
			"check" ) System_check ;;
			"flsuite" ) FLSUITE ;;
			"beta" ) beta ;;
			"-h" ) Usage ;;
		esac
		shift
	done
else
	echo "installing full suite"
	# install everything:
	Enable_Sources
	Check_overlay
	FLSUITE
	GPSD_install
	chrony_setup
	Xastir_install
	fdlog_install
fi

# libraries:
#apparently some files are missing, adding in a bunch of dependencies that might be needed from http://www.kk5jy.net/fldigi-build/:
#note: with beta 6 image this breaks, have no idea why, might need to break this up into smaller chunks and verify the install better.
#sudo apt-get install libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev libmotif-dev chrony graphicsmagick libgraphicsmagick1-dev festival festival-dev shapelib libshp-dev libpcre3-dev libproj-dev libdb-dev python-dev libwebp-dev libgeotiff-dev libtiff-dev -y
#gps specific stuff:
#sudo apt-get install gpsman gpsd-clients python-gps pps-tools libgps-dev

#make sure in home directory
#cd ~

#grab the scripts
#git clone https://github.com/nwdigitalradio/n7nix
#################################
###########  NOTE  ##############
#################################
# nwdigital radio scripts will not be used in this, I will be phasing them out as they might have unintended affects
# the scripts will still be downloaded for testing purposes and if other features not covered in this script
# (ie ax.25 stacks, rms, etc) are needed. Audio level setting will come from supplied file with this repository
