#!/bin/bash
(
#   Open Repeater Project
#
#    Copyright (C) <2015-2017>  <Richard Neese> kb3vgw@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.
#
#    If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>






#
# Request user input to ask for device type
#
echo ""

heading="What Arm Board?"
title="Please choose the device you are building on:"
prompt="Pick a Arm Board:"
options=("Raspberry Pi 2" "Raspberry Pi 3" "Raspberry Pi 3 B+" "Odroid C1+" "Odroid C2" "CHIP" "BeagleBoneBlack" )
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in

    # RASPBERRY PI2 32bit
    1 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="rpi2"; break;;

    # RASPBERRY PI3 64bit
    2) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="rpi3"; break;;

    # RASPBERRY PI3 64bit
    3) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="rpi3"; break;;

    # ODROID C1/C1+ 32bit
    4 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="oc1+"; break;;

    # ODROID-C2 64bit
    5 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="oc2"; break;;

    # Chip  32bit
    6 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="chip"; break;;
    
    # BBB  32bit
    7 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="bbb"; break;;  
    

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to ask for os type
#
echo ""
heading="What OS ?"
title="Please choose the OS you are building on:"
prompt="Pick a OS:"
options=("Armbian" "Dietpi" "Raspbian" "Debian")
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in

    # Armbian
    1 ) echo ""; echo "Building for $opt1"; os_long_name="$opt1"; os_short_name="Armb"; break;;

    # Dietpi
    2 ) echo ""; echo "Building for $opt1"; os_long_name="$opt1"; os_short_name="Diet"; break;;
    
    # Raspbian
    3 ) echo ""; echo "Building for $opt1"; os_long_name="$opt1"; os_short_name="Rasp"; break;;  
    
    # Debian
    4 ) echo ""; echo "Building for $opt1"; os_long_name="$opt1"; os_short_name="BBB-Deb"; break;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to ask for type of svxlink install
#
echo ""
heading="What type of svxlink istall: Stable=15.11.5 Teesting is 16.04.x  Devel=Head ?"
title="Please choose svxlink install type:"
prompt="Pick a Svxlink install type Stable=15.11.5 Teesting is 16.04.x  Devel=Head : "
options=("Stable" "Testing" "Devel")
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in

    # Stable Release
    1 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="SVX-Stable"; break;;

    # Testing Release
    2 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="SVX-Testing"; break;;
    
    # Devel Release
    3 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="SVX-Devel"; break;;  
    
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to ask for type of svxlink install
#
echo ""
heading="What type of OpenRepeater istall: Stable=1.0.0 Teesting is 1.2.0  Devel=Head ?"
title="Please choose OpenRepeater install type:"
prompt="Pick a ORP install Type Stable=1.0.0 Teesting is 1.2.0  Devel=Head :"
options=("Stable" "Testing" "Devel")
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in
    # Stable Release
    1 ) echo ""; echo "Building for $opt1"; orp_long_name="$opt1"; orp_short_name="ORP-Stable"; break;;

    # Testing Release
    2 ) echo ""; echo "Building for $opt1"; orp_long_name="$opt1"; orp_short_name="ORP-Testing"; break;;
    
    # Devel Release
    3 ) echo ""; echo "Building for $opt1"; orp_long_name="$opt1"; orp_short_name="ORP-Devel"; break;;  
    
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to ask for type of svxlink install
#
echo ""
heading="What type of SoundCard ?"
title="Please choose Soundcard type:"
prompt="Pick your sound card:"
options=("USB" "OnBoard" )
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in
    # Soundcard usb
    1 ) echo ""; echo "Building for $opt1"; snd_long_name="$opt1"; snd_short_name="USB"; break;;

    # Soundcard onboard
    2 ) echo ""; echo "Building for $opt1"; snd_long_name="$opt1"; snd_short_name="OnBoard"; break;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to set hostname
#
echo ""
heading="HOSTNAME"
title="What would you like to set your hostname to? Valid characters are a-z, 0-9, and hyphen. Hit ENTER to use the default hostname ($default_hostname) for this device OR enter your own and hit ENTER:"

echo "$heading"
echo "$title"
read -r orp_hostname

if [[ $orp_hostname == "" ]]; then
	orp_hostname="$default_hostname"
fi

echo ""
echo "Using $orp_hostname as hostname."
echo ""



echo "--------------------------------------------------------------"
printf ' Current ip is : '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
echo "--------------------------------------------------------------"
echo


echo "--------------------------------------------------------------"
echo " Set a reboot if Kernel Panic                                 "
echo "--------------------------------------------------------------"
cat >> /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

echo "--------------------------------------------------------------"
echo " Setting Host/Domain name                                     "
echo "--------------------------------------------------------------"
cat > /etc/hostname << DELIM
$orp_hostname
DELIM

# Setup /etc/hosts
cat >> /etc/hosts << DELIM
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $orp_hostname

DELIM


#Arbbian repo
if [ $os_short_name == "Armb" ]; then
echo "--------------------------------------------------------------"
echo " Adding Armbian repository                                    "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/armbian.list << DELIM
deb http://apt.armbian.com jessie main utils jessie-desktop
DELIM
fi

#Dietpi repo
if [ $os_short_name == "Diet" ]; then
echo "--------------------------------------------------------------"
echo " Adding DietPi repository                                     "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/dietpi.list << DELIM
deb http://mirror.ox.ac.uk/sites/archive.raspbian.org/archive/raspbian jessie main contrib non-free rpi
DELIM
fi

#Raspbian Repos
if [ $os_short_name == "Rasp" ]; then
echo "--------------------------------------------------------------"
echo " Adding Raspbierry P repository                               "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/rpi.list << DELIM
deb http://archive.raspberrypi.org/debian/ jessie main ui
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
#deb-src http://archive.raspberrypi.org/debian/ jessie main ui
DELIM

cat > /etc/apt/sources.list.d/raspbian.list  << DELIM
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib firmware non-free rpi
DELIM

echo "--------------------------------------------------------------"
echo " Updating Raspberry Pi repository keys...                     "
echo "--------------------------------------------------------------"
gpg --keyserver pgp.mit.edu --recv 8B48AD6246925553 
gpg --export --armor 8B48AD6246925553 | apt-key add -
gpg --keyserver pgp.mit.edu --recv  7638D0442B90D010
gpg --export --armor  7638D0442B90D010 | apt-key add -
gpg --keyserver pgp.mit.edu --recv CBF8D6FD518E17E1
gpg --export --armor CBF8D6FD518E17E1 | apt-key add -
wget https://www.raspberrypi.org/raspberrypi.gpg.key
gpg --import raspberrypi.gpg.key | apt-key add -
wget https://archive.raspbian.org/raspbian.public.key
gpg --import raspbian.public.key | apt-key add -
fi

if [ $os_short_name == "BBB-Deb" ]; then
echo "--------------------------------------------------------------"
echo " Adding BBBlack repository                                    "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/beaglebone.list << DELIM
deb [arch=armhf] http://repos.rcn-ee.net/debian/ jessie main
DELIM
fi

if [ $device_short_name == "chip" ]; then
echo "--------------------------------------------------------------"
echo " Adding C.H.I.P repository                                    "
echo "--------------------------------------------------------------"
	cat > /etc/apt/source.list.d/nextthing.list  << DELIM
deb http://opensource.nextthing.co/chip/debian/repo jessie main
DELIM
fi

if [ $svx_short_name == "SVX-Stable" ]; then
echo "--------------------------------------------------------------"
echo " Adding SvxLink Stable Repository                             "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://repo.openrepeater.com/svxlink/stable/debian/ jessie main
DELIM
fi

# SvxLink Testing Repo 
if [ $svx_short_name == "SVX-Testing" ]; then
echo "--------------------------------------------------------------"
echo " Adding SvxLink Testing Repository                            "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://repo.openrepeater.com/svxlink/testing/debian/ jessie main
DELIM
fi

# SvxLink Release Repo 
if [ $svx_short_name == "SVX-Devel" ]; then
echo "--------------------------------------------------------------"
echo " Adding SvxLink Devel Repository                              "
echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://repo.openrepeater.com/svxlink/devel/debian/ jessie main
DELIM
fi

if [ $orp_short_name == "ORP-Stable" ]; then
echo "--------------------------------------------------------------"
echo " Adding OpenRepeater Stable repository                        "
echo "--------------------------------------------------------------"
	cat > "/etc/apt/sources.list.d/openrepeater.list" << DELIM
deb http://repo.openrepeater.com/openrepeater/stable/debian/ jessie main
DELIM
fi

# Adding OpenRepeater Testing Repo
if [ $orp_short_name == "ORP-Testing" ]; then
echo "--------------------------------------------------------------"
echo " Adding OpenRepeater Testing repository                       "
echo "--------------------------------------------------------------"
	cat > "/etc/apt/sources.list.d/openrepeater.list" << DELIM
deb http://repo.openrepeater.com/openrepeater/testing/debian/ jessie main
DELIM
fi

# Adding OpenRepeater Devel Repo
if [ $orp_short_name == "ORP-Devel" ]; then
echo "--------------------------------------------------------------"
echo " Adding OpenRepeater Devel repository                         "
echo "--------------------------------------------------------------"
	cat > "/etc/apt/sources.list.d/openrepeater.list" << DELIM
deb http://repo.openrepeater.com/openrepeater/devel/debian/ jessie main
DELIM
fi

echo "--------------------------------------------------------------"
echo "Performing Base OS Update...                                  "
echo "--------------------------------------------------------------"
for i in update upgrade clean ;do apt-get -y --force-yes "${i}" ; done

if [ $device_short_name == "bbb" ] ; then
echo "--------------------------------------------------------------"
echo "Adding new kernel to the Beagle Bone Black                    "
echo "--------------------------------------------------------------"
	#update the kernal on the beaglebone black
	apt-get install linux-image-4.4.0-rc5-bone0 linux-firmware-image-4.4.0-rc5-bone0
fi


# Install svxlink
echo "--------------------------------------------------------------"
echo " Installing svxlink + remotetrx"
echo "--------------------------------------------------------------"
apt-get -y --force-yes install svxserver svxlink-server remotetrx
apt-get clean

#adding user svxlink to gpio user group
usermod -a -G gpio svxlink

echo "--------------------------------------------------------------"
echo " Installing svxlink sounds"
echo "--------------------------------------------------------------"
wget http://github.com/kb3vgw/Svxlink-sounds-en_US-laura/releases/download/15.11.2/Svxlink-sounds-en_US-laura-16k-15.11.2.tar.bz2
tar xjvf Svxlink-sounds-en_US-laura-16k-15.11.2.tar.bz2
mv en_US-laura-16k /usr/share/svxlink/sounds/en_US
rm Svxlink-sounds-en_US-laura-16k-15.11.1.tar.bz2






echo "--------------------------------------------------------------"
echo " Fetch and Install open repeater project web ui..."
echo "--------------------------------------------------------------"
apt-get install -y --force-yes openrepeater

echo "--------------------------------------------------------------"
echo " Configuring openrepeater..."
echo "--------------------------------------------------------------"

find "$WWW_PATH" -type d -exec chmod 775 {} +
find "$WWW_PATH" -type f -exec chmod 664 {} +

chown -R www-data:www-data $WWW_PATH

cp /etc/default/svxlink /etc/default/svxlink.orig
cp /etc/default/remotetrx /etc/default/remotetrx.orig

echo "--------------------------------------------------------------"
echo " Copying configs for php and nginx into place                 "
echo "--------------------------------------------------------------"
cp /usr/share/examples/openrepeater/default/svxlink /etc/default
cp /usr/share/examples/openrepeater/nginx/nginx.conf /etc/nginx
cp /usr/share/examples/openrepeater/php5/fpm/php5-fpm.conf /etc/php5/fpm
cp /usr/share/examples/openrepeater/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d

echo "--------------------------------------------------------------"
echo " Final Required Linking and permissions into place            "
echo "--------------------------------------------------------------"
ln -s  /var/lib/openrepeater/sounds /var/www/openrepeater/sounds
rm /usr/share/svxlink/events.d/local
mkdir /etc/openrepeater/svxlink/local-events.d
ln -s /etc/openrepeater/svxlink/local-events.d /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown -R www:www-data /var/www/openrepeater 
chown -R root:www-data /etc/openrepeater

# RASPBERRY PI ONLY: Add svxlink user to groups: gpio, audio, and daemon
if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
	echo "--------------------------------------------------------------"
	echo " Add svxlink user to groups: gpio, audio, and daemon"
	echo "--------------------------------------------------------------"
	usermod -a -G daemon,gpio,audio svxlink
fi


# RASPBERRY PI ,ODROID, BBB :
# Set up usb sound for alsa mixer
if [ $snd_short_name == "USB" ]; then
if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] || [ $device_short_name == "oc1+" ] || [ $device_short_name == "oc2" ] || [ $device_short_name == "bbb" ]; then
	echo "--------------------------------------------------------------"
	echo " Set up usb sound for alsa mixer"
	echo "--------------------------------------------------------------"
	if ( ! $(grep "snd-usb-audio" /etc/modules >/dev/null) ); then
		echo "snd-usb-audio" >> "/etc/modules"
	fi
	FILE=/etc/modprobe.d/alsa-base.conf
	sed "s/options snd-usb-audio index=-2/options snd-usb-audio index=0/" $FILE > ${FILE}.tmp
	mv -f ${FILE}.tmp ${FILE}
	if ( ! $(grep "options snd-usb-audio nrpacks=1" ${FILE} > /dev/null) ); then
		echo "options snd-usb-audio nrpacks=1 index=0" >> ${FILE}
	fi
fi
fi

if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
	echo "--------------------------------------------------------------"
	echo " Configuring /etc/modules for bcm chip i2c / spi / 1 wire     "
	echo "--------------------------------------------------------------"
	#ModProbe moules
	modprobe i2c-bcm2708
	modeporbe spi-bcm208
fi

if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] || [ $device_short_name == "oc1+" ] || [ $device_short_name == "oc2" ] ; then
	echo "--------------------------------------------------------------"
	echo " Modprobing modules"
	echo "--------------------------------------------------------------"
	#ModProbe moules
	modprobe i2c-dev
	modprobe w1-gpio
	modprobe w1-therm

	echo "--------------------------------------------------------------"
	echo " Enable the spi & i2c /etc/modules"	
	echo "--------------------------------------------------------------"
	echo "i2c-dev" >> /etc/modules
	echo "w1-gpio" >> /etc/modules
	echo "w1-therm" >> /etc/modules
fi

if [ $os_short_name == "Raspbian" ]; then
	if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ]; then
		echo "--------------------------------------------------------------"
		echo " Configuring /boot/config.txt options 1"
		echo "--------------------------------------------------------------"
		sed -i /boot/config.txt -e "s#dtparam=audio=on#dtparam=audio=off#"
		sed -i /boot/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
		sed -i /boot/config.txt -e "s#\#dtparam=spi=on#dtparam=spi=on#"
	fi
fi

if [ $os_short_name == "Dietpi" ] ; then
	if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
		echo "--------------------------------------------------------------"
		echo " Configuring /boot/config.txt options part 2"
		echo "--------------------------------------------------------------"
		sed -i /boot/config.txt -e "s#dtparam=audio=on#dtparam=audio=off#"
		sed -i /boot/config.txt -e "s#dtparam=i2c_arm=off#dtparam=i2c_arm=on#"
		sed -i /boot/config.txt -e "s#dtparam=i2c1=off#dtparam=i2c_arm=on#"
		sed -i /boot/config.txt -e "s#dtparam=spi=off#dtparam=spi=on#"
	fi
fi

if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
	echo "--------------------------------------------------------------"
	echo " Configuring /boot/config.txt options part 3                  "
	echo "--------------------------------------------------------------"
	# set usb power level
	cat >> /boot/config.txt << DELIM

#usb max current
usb_max_current=1

#enable 1wire onboard temp
dtoverlay=w1-gpio,gpiopin=4
DELIM
fi

if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
fi

echo "--------------------------------------------------------------"
echo " Set fs to run in a tempfs                                    "
echo "--------------------------------------------------------------"
cat >> /etc/fstab << DELIM
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/cache/apt/archives tmpfs   size=100M,defaults,noexec,nosuid,nodev,mode=0755 0 0
DELIM

echo "--------------------------------------------------------------"
echo " Enable SvxLink systemd services                              "
echo "--------------------------------------------------------------"
systemctl enable svxserver
systemctl enable svxlink
systemsctl enable remotertrx

# BEAGLEBONE ONLY Disable HDMI sound
if [ $device_short_name == "bbb" ] ; then
	echo "--------------------------------------------------------------"
	echo " Disable HDMI sound                                           "
	echo "--------------------------------------------------------------"
	cat >> /boot/uEnv.txt << DELIM
optargs=capemgr.disable_partno=BB-BONELT-HDMI
DELIM
fi

if [ $device_short_name == "rpi2" ] || [ $device_short_name == "rpi3" ] ; then
	echo "--------------------------------------------------------------"
	echo " Add-on extra scripts for cloning the drive                   "
	echo "--------------------------------------------------------------"
	cd /usr/local/bin || exit
	wget https://raw.githubusercontent.com/billw2/rpi-clone/master/rpi-clone
	chmod +x rpi-clone
	cd /root || exit
fi

) | tee /root/install.log