#!/bin/bash
#(
####################################################################
#
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
#    -- 2015-11-24:0100 added various fixes to GPG, repos, and error corrections (Chris Tripp, KK4CT)
#	 -- 2016 (April) Created Unified install script with conditional logic, 
#       fix typos and other corrections. (Aaron Crawford, N3MBH) 
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
####################################################################


########################################################
# Set mp3/wav file upload/post size limit for php/nginx
# ( Must Have the M on the end )
########################################################
upload_size="25M"

#######################
# Nginx default www dir
#######################
WWW_PATH="/var/www"

#################################
# Set Web User Interface Dir Name
#################################
gui_name="openrepeater"

#####################
# PHP ini config file
#####################
php_ini="/etc/php5/fpm/php.ini"

##################################################################
# Check to confirm running as root. # First, we need to be root...
##################################################################
if [ "$(id -u)" -ne "0" ]; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi
echo ""
echo "--------------------------------------------------------------"
echo ""
echo "Looks Like you are root.... continuing!"
echo ""

############################################
# Request user input to ask for device type
############################################
echo "--------------------------------------------------------------"
echo ""
heading="WHAT DEVICE?"
title="Please choose the device you are building on:"
prompt="Pick an option:"
options=("Raspberry Pi 2/3" "Beaglebone Black" "Odroid C1/C1+")

echo "$heading"
echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; do 
    case "$REPLY" in

    # RASPBERRY PI
    1 ) echo "";echo "Building for $opt";device_long_name="$opt";device_short_name="rpi";default_hostname="orp-rpi";break;;

    # BEAGLEBONE
    2 ) echo "";echo "Building for $opt";device_long_name="$opt";device_short_name="bbb";default_hostname="orp-bbb";break;;

    # ODROID
    3 ) echo "";echo "Building for $opt";device_long_name="$opt";device_short_name="odroid";default_hostname="orp-odroid";break;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#####################################
# Request user input to set hostname
#####################################
echo "--------------------------------------------------------------"
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

################################################
# If lsb_release is not installed it installs it
################################################
if [ ! -s /usr/bin/lsb_release ]; then
	echo ""
	echo "--------------------------------------------------------------"
	echo "Installing lsb_release..."
	echo "--------------------------------------------------------------"
	apt-get update && apt-get -y install lsb-release
fi

#################
# OS/Distro Check
#################
lsb_release -c |grep -i jessie &> /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo " OK you are running Debian 8 : Jessie "
else
	echo " This script was written for Debian 8 Jessie "
	echo " Your OS appears to be: " lsb_release -a
	echo ""
echo "--------------------------------------------------------------"
echo ""
	echo " Your OS is not currently supported by this script ... "
	echo ""
echo "--------------------------------------------------------------"
echo ""
	echo " Exiting the install. "
	exit
fi

###########################################
# Run Platform compatibility Check
###########################################
########
# ARMEL
########
case $(uname -m) in armv[4-5]l)
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
	echo " ArmEL is currently UnSupported "
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
	exit
esac

########
# ARMHF
########
case $(uname -m) in armv[6-9]l)
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
	echo " ArmHF arm v7 v8 v9 boards supported "
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
esac

#############
# Intel/AMD
#############
case $(uname -m) in x86_64|i[4-6]86)
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
	echo " Intel / AMD boards currently UnSupported"
	echo ""
	echo "--------------------------------------------------------------"
	echo ""
	exit
esac

#######################################
# RASPBERRY PI ONLY:
#
# Update base os with new repo in list
#######################################
if [ $device_short_name == "rpi" ] ; then
	echo ""
	echo "--------------------------------------------------------------"
	echo "Updating Raspberry Pi repository keys..."
	echo "--------------------------------------------------------------"
	echo ""
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
	for i in update upgrade clean ;do apt-get -y --force-yes "${i}" ; done
fi

###################
# Notes / Warnings
###################
echo ""
cat << DELIM
                   Not Ment For L.A.M.P Installs

                  L.A.M.P = Linux Apache Mysql PHP

                 THIS IS A ONE TIME INSTALL SCRIPT

             IT IS NOT INTENDED TO BE RUN MULTIPLE TIMES

         This Script Is Meant To Be Run On A Fresh Install Of

                         Debian 8 (Jessie)

     If It Fails For Any Reason Please Report To kb3vgw@gmail.com

   Please Include Any Screen Output You Can To Show Where It Fails

DELIM

################################################################################################
# Testing for internet connection. Pulled from and modified
# http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
################################################################################################
echo ""
echo "--------------------------------------------------------------"
echo ""
echo "This Script Currently Requires a internet connection "
echo ""
echo "--------------------------------------------------------------"
echo ""
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "I Found the Internet ... continuing!!!!!"
	/bin/rm /tmp/index.google
fi
echo ""
echo "--------------------------------------------------------------"
echo ""
printf ' Current ip is : '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
echo ""
echo "--------------------------------------------------------------"
echo ""
echo

##############################
# Set a reboot if Kernel Panic
##############################
cat >> /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

####################################
# Set fs to run in a tempfs ramdrive
####################################
cat >> /etc/fstab << DELIM
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/cache/apt/archives tmpfs   size=100M,defaults,noexec,nosuid,nodev,mode=0755 0 0
DELIM

######################################
# BEAGLEBONE ONLY:
#
# Disable Beaglebone 101 Web Services
######################################
if [ $device_short_name == "bbb" ] ; then
	echo " Disabling The Beaglebone 101 web services "
	systemctl disable cloud9.service
	systemctl disable gateone.service
	systemctl disable bonescript.service
	systemctl disable bonescript.socket
	systemctl disable bonescript-autorun.service
	systemctl disable avahi-daemon.service
	systemctl disable gdm.service
	systemctl disable mpd.service
	
	echo " Stoping The Beaglebone 101 web services "
	systemctl stop cloud9.service
	systemctl stop gateone.service
	systemctl stop bonescript.service
	systemctl stop bonescript.socket
	systemctl stop bonescript-autorun.service
	systemctl stop avahi-daemon.service
	systemctl stop gdm.service
	systemctl stop mpd.service
	
	apt-get -y autoremove apache2*
fi

#####################
# RASPBERRY PI ONLY:
#
# set usb power level
#####################
if [ $device_short_name == "rpi" ] ; then
cat >> /boot/config.txt << DELIM

#usb max current
usb_max_current=1
DELIM
fi

##############################
# RASPBERRY PI ONLY:
#
# Disable the dphys swap file
# Extend life of sd card
###############################
if [ $device_short_name == "rpi" ] ; then
	echo ""
	echo "--------------------------------------------------------------"
	echo "Disabling swap..."
	echo "--------------------------------------------------------------"
	
	swapoff --all
	apt-get -y remove dphys-swapfile
	rm -rf /var/swap
fi

############################################
# RASPBERRY PI ONLY:
#
# Add-on extra scripts for cloning the drive
############################################
if [ $device_short_name == "rpi" ] ; then
	cd /usr/local/bin
	wget https://raw.githubusercontent.com/billw2/rpi-clone/master/rpi-clone
	chmod +x rpi-clone
	cd /root 
fi

######################################################
# RASPBERRY PI ONLY:
#
# Fix usb sound/nic issue so network interface gets IP
######################################################
if [ $device_short_name == "rpi" ] ; then
cat >> /etc/network/interfaces << DELIM
auto lo eth0
iface lo inet loopback
iface eth0 inet dhcp
DELIM
fi

#############################
# Setting Host/Domain name
#############################
cat >> /etc/hostname << DELIM
$orp_hostname
DELIM

##################
# Setup /etc/hosts
##################
cat >> /etc/hosts << DELIM
127.0.0.1       localhost 
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $orp_hostname

DELIM

###########################################################
# RASPBERRY PI ONLY:
#
# Disable onboard HDMI sound card not used in openrepeater
###########################################################
if [ $device_short_name == "rpi" ] ; then
	#/boot/config.txt
	sed -i /boot/config.txt -e"s#dtparam=audio=on#\#dtparam=audio=on#"
	
	# Enable audio (loads snd_bcm2835)
	# dtparam=audio=on
	#/etc/modules
	sed -i /etc/modules -e"s#snd-bcm2835#\#snd-bcm2835#"
fi

#####################
# BEAGLEBONE ONLY:
#
# Disable HDMI sound
#####################
if [ $device_short_name == "bbb" ] ; then
cat >> /boot/uEnv.txt << DELIM
optargs=capemgr.disable_partno=BB-BONELT-HDMI
DELIM
fi

#################################################################################################
# RASPBERRY PI ONLY:
#
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#################################################################################################
if [ $device_short_name == "rpi" ] ; then
cat >> /etc/apt/sources.list << DELIM
deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free
DELIM
fi

###########################################################################
# RASPBERRY PI ONLY:
#
# Raspi Repo
# Put in Proper Location. All addon repos should be source.list.d sub dir
###########################################################################
if [ $device_short_name == "rpi" ] ; then
cat >> /etc/apt/sources.list.d/raspi.list << DELIM
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib firmware non-free rpi
DELIM
fi

##########################
# BEAGLEBONE ONLY:
#
# Adding bbblack Repo
##########################
if [ $device_short_name == "bbb" ] ; then
cat >> /etc/apt/sources.list.d/beaglebone.list << DELIM
deb [arch=armhf] http://repos.rcn-ee.net/debian/ jessie main
DELIM
fi

#############################
# SvxLink Release Repo ArmHF
#############################
cat >> /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://repo.openrepeater.com/svxlink/release/debian/ jessie main
DELIM

##########################
# Adding OpenRepeater Repo
##########################
cat >> "/etc/apt/sources.list.d/openrepeater.list" << DELIM
deb http://repo.openrepeater.com/openrepeater/release/debian/ jessie main
DELIM

######################
# Update base OS
######################
echo ""
echo "--------------------------------------------------------------"
echo "Performing Base OS Update..."
echo "--------------------------------------------------------------"

for i in update upgrade clean ;do apt-get -y --force-yes "${i}" ; done

######################
# BEAGLEBONE ONLY:
#
# Update base OS
######################
if [ $device_short_name == "bbb" ] ; then
	#update the kernal on the beaglebone black
	apt-get install linux-image-4.4.0-rc5-bone0 linux-firmware-image-4.4.0-rc5-bone0
fi

##########################
# Installing Dependencies
##########################
echo ""
echo "--------------------------------------------------------------"
echo " Installing Dependencies..."
echo "--------------------------------------------------------------"

apt-get install -y --force-yes --fix-missing memcached sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		ntp libasound2 libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 tk8.6 alsa-base bzip2 sudo gpsd gpsd-clients \
		flite wvdial inetutils-syslogd screen time uuid vim install-info usbutils whiptail dialog logrotate cron \
		gawk watchdog python3-serial wiringpi

######################
# Install svxlink
#####################
echo ""
echo "--------------------------------------------------------------"
echo " Installing svxlink + remotetrx"
echo "--------------------------------------------------------------"
echo ""
apt-get -y --force-yes install svxlink-server remotetrx
apt-get clean

######################################################
# Get SVXLink Sound Package (English)
######################################################
wget --no-check-certificate https://github.com/OpenRepeater/svxlink-sounds-en_US-laura/archive/15.11.1.tar.gz
tar -zxvf 15.11.1.tar.gz
mv svxlink-sounds-en_US-laura-15.11.1 en_US
mv en_US /usr/share/svxlink/sounds
rm 15.11.1.tar.gz

##########################################
# Start of nginx / php5 install
##########################################
echo ""
echo "--------------------------------------------------------------"
echo " Installing nginx and php5..."
echo "--------------------------------------------------------------"
apt-get -y install ssl-cert openssl-blacklist nginx memcached php5-cli php5-common \
		php-apc php5-gd php-db php5-fpm php5-memcache php5-sqlite

apt-get clean

##################################################
# Changing file upload size from 2M to upload_size
##################################################
sed -i "$php_ini" -e "s#upload_max_filesize = 2M#upload_max_filesize = $upload_size#"

######################################################
# Changing post_max_size limit from 8M to upload_size
######################################################
sed -i "$php_ini" -e "s#post_max_size = 8M#post_max_size = $upload_size#"

######################################################################################################
# Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
######################################################################################################
cat >> "/etc/nginx/sites-available/$gui_name"  << DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 25M;
        client_body_buffer_size 128k;

        root /var/www/openrepeater;
        index index.php;

        location ~ \.php$ {
           include snippets/fastcgi-php.conf;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
              deny all;
        }
        location ~ .htpassword {
              deny all;
        }
        location ~^.+.(db)$ {
              deny all;
        }
}
server{
        listen 443;
        listen [::]:443 default_server ipv6only=on;

        include snippets/snakeoil.conf;
        ssl  on;

        root /var/www/openrepeater;

        index index.php;

        server_name $gui_name;

        location / {
            try_files \$uri \$uri/ =404;
        }

        client_max_body_size 25M;
        client_body_buffer_size 128k;
        
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        location ~ \.(html|htm|ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
                if (!-f \$request_filename) {
                    rewrite ^(.*)\.(html|htm|ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ \$1.php permanent;
                }
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/\$fastcgi_script_name;
            error_page 404 404.php;
            fastcgi_intercept_errors on;

        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}

DELIM

###############################################
# Set nginx worker level limit for performance
###############################################
cat >> "/etc/nginx/nginx.conf"  << DELIM
user www-data;
worker_processes 4;
pid /run/nginx.pid;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	open_file_cache max=1000 inactive=20s;
	open_file_cache_valid 30s;
	open_file_cache_min_uses 2;
	open_file_cache_errors off;

	fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=microcache:15M max_size=1000m inactive=60m;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;
	gzip_static on;
	gzip_disable "msie6";

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

DELIM

#################################
# Backup and replace www.conf
#################################
cp /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig

cat >> /etc/php5/fpm/pool.d/www.conf << DELIM
[www]

user = www-data
group = www-data

listen = /var/run/php5-fpm.sock

listen.owner = www-data
listen.group = www-data

pm = static

pm.max_children = 5

pm.start_servers = 2

pm.max_requests = 100

chdir = /
DELIM

##################################
# Backup and replace php5-fpm.conf
##################################
cp /etc/php5/fpm/php-fpm.conf /etc/php5/fpm/php-fpm.conf.orig

cat >> /etc/php5/fpm/php-fpm.conf << DELIM
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;include=/etc/php5/fpm/*.conf

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]

pid = /run/php5-fpm.pid

; Error log file
error_log = /var/log/php5-fpm.log

; syslog_facility is used to specify what type of program is logging the
; message. This lets syslogd specify that messages from different facilities
; will be handled differently.
; See syslog(3) for possible values (ex daemon equiv LOG_DAEMON)
; Default Value: daemon
;syslog.facility = daemon

syslog.ident = php-fpm

emergency_restart_threshold = 10

emergency_restart_interval = 1m

process_control_timeout = 10

process.max = 12

systemd_interval = 60

include=/etc/php5/fpm/pool.d/*.conf
DELIM

###################################################################
# Linking openrepeater nginx config from available to enabled sites
###################################################################
ln -s /etc/nginx/sites-available/"$gui_name" /etc/nginx/sites-enabled/"$gui_name"

######################
# Disable default site
######################
rm -rf /etc/nginx/sites-enabled/default

# Make sure the path /var/www/ is owned by your web server user:
chown -R www-data:www-data /var/www

##############################
# Restarting Nginx and PHP FPM
##############################
for i in nginx php5-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done

#################################################
# Fetch and Install open repeater project web ui
#################################################
echo ""
echo "--------------------------------------------------------------"
echo " Installing openrepeater package..."
echo "--------------------------------------------------------------"

apt-get install -y --force-yes openrepeater

echo ""
echo "--------------------------------------------------------------"
echo " Configuring openrepeater..."
echo "--------------------------------------------------------------"

find "$WWW_PATH" -type d -exec chmod 775 {} +
find "$WWW_PATH" -type f -exec chmod 664 {} +

chown -R www-data:www-data $WWW_PATH

cp /etc/default/svxlink /etc/default/svxlink.orig

echo ""
echo "--------------------------------------------------------------"
echo " Generating openrepeater svxlink configuration...."
echo "--------------------------------------------------------------"

cat >> "/etc/default/svxlink" << DELIM

#############################################################################
# Configuration file for the SvxLink startup script /etc/init.d/svxlink
#############################################################################
# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/svxlink.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

#uesd for openrepeater to get gpio pins
if [ -r /etc/openrepeater/svxlink/svxlink_gpio.conf ]; then
        . /etc/openrepeater/svxlink/svxlink_gpio.conf
fi

DELIM

mv /etc/default/remotetrx /etc/default/remotetrx.orig

echo ""
echo "--------------------------------------------------------------"
echo " Generating remotetrx configuration..."
echo "--------------------------------------------------------------"

cat >> "/etc/default/remotetrx" << DELIM

#############################################################################
# Configuration file for the RemoteTrx startup script /etc/init.d/remotetrx
#############################################################################
# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

DELIM

# Final Required Linking and permissions
ln -s  /var/lib/openrepeater/sounds /var/www/openrepeater/sounds
rm /usr/share/svxlink/events.d/local
mkdir /etc/openrepeater/svxlink/local-events.d
ln -s /etc/openrepeater/svxlink/local-events.d /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown -R www-data:www-data /var/www/openrepeater /etc/openrepeater
chown root:www-data /usr/bin/openrepeater_*

# RASPBERRY PI ONLY: Add svxlink user to groups: gpio, audio, and daemon
if [ $device_short_name == "rpi" ] ; then
	usermod -a -G daemon,gpio,audio svxlink
fi

cat >> /etc/sudoers << DELIM
#allow www-data to access amixer and service
www-data   ALL=(ALL) NOPASSWD: /usr/bin/openrepeater_svxlink_restart, NOPASSWD: /usr/bin/aplay, NOPASSWD: /usr/bin/arecord
# Future Options
#NOPASSWD: /usr/bin/openrepeater_svxlink_start, NOPASSWD: /usr/bin/openrepeater_svxlink_stop, \
#NOPASSWD: /usr/bin/openrepeater_enable_svxlink_service, NOPASSWD: /usr/bin/openrepeater_diable_svxlink_service
DELIM

#################################
# RASPBERRY PI & BEAGLEBONE:
#
# Set up usb sound for alsa mixer
#################################
if [ $device_short_name == "rpi" ] || [ $device_short_name == "bbb" ] ; then
	if ( ! `grep "snd-usb-audio" /etc/modules >/dev/null`) ; then
	   echo "snd-usb-audio" >> /etc/modules
	fi
	FILE=/etc/modprobe.d/alsa-base.conf
	sed "s/options snd-usb-audio index=-2/options snd-usb-audio index=0/" $FILE > ${FILE}.tmp
	mv -f ${FILE}.tmp ${FILE}
	if ( ! `grep "options snd-usb-audio nrpacks=1" ${FILE} > /dev/null` ) ; then
	  echo "options snd-usb-audio nrpacks=1 index=0" >> ${FILE}
	fi
fi

########################
# Enable Systemd Service
########################
echo " Enabling the Svxlink systemd Service Daemon "
systemctl enable svxlink.service

########################
# Enable Systemd Service
########################
echo " Enabling the Svxlink Remotetrx systemd Service Daemon "
systemctl enable remotetrx.service

echo " ########################################################################################## "
echo " #            You will need to edit the php.ini file and add extensions=memcache.so       # " 
echo " #               location : /etc/php5/fpm/php.ini and then restart web service            # "
echo " ########################################################################################## "
echo
echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " #                                                                                        # "
echo " ########################################################################################## "
#) | tee /root/install.log