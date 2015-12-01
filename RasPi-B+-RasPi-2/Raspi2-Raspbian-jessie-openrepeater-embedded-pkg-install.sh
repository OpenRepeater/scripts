#!/bin/bash
(
####################################################################
#
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
#    -- 2015-11-24:0100 added various fixes to GPG, repos, and error corrections (KK4CT)
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
#######################################
# Auto Install Configuration options
# (set it, forget it, run it)
#######################################

# ----- Start Edit Here ----- #
####################################################
# Repeater call sign
# Please change this to match the repeater call sign
####################################################
cs="Set-This"

####################################################
# Install vsftpd for devel (Optional) (Not Required)
####################################################
install_vsftpd="y" #y/n

#####################
# set vsftp user name
#####################
vsftpd_user=""

########################
# set vsftp config path
########################
FTP_CONFIG_PATH="/etc/vsftpd.conf"

# ----- Stop Edit Here ------- #
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
#set Web User Interface Dir Name
#################################
gui_name="openrepeater"

#####################
#Php ini config file
#####################
php_ini="/etc/php5/fpm/php.ini"
######################################################################
# check to see that the configuration portion of the script was edited
######################################################################
if [[ $cs == "Set-This" ]]; then
  echo ""
echo "--------------------------------------------------------------"
echo ""
  echo "Looks like you need to configure the script before running"
  echo "Please configure the script and try again"
  exit 0
fi

##################################################################
# check to confirm running as root. # First, we need to be root...
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
echo "--------------------------------------------------------------"
echo ""

###############################################
#if lsb_release is not installed it installs it
###############################################
if [ ! -s /usr/bin/lsb_release ]; then
echo ""
echo "--------------------------------------------------------------"
echo "Installing lsb_release..."
echo "--------------------------------------------------------------"
apt-get update && apt-get -y install lsb-release
fi

#################
# Os/Distro Check
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
# Run a OS and Platform compatabilty Check
###########################################
########
# ARMEL
########
case $(uname -m) in armv[4-5]l)
echo ""
echo "--------------------------------------------------------------"
echo ""
echo " ArmEL is currenty UnSupported "
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
echo " Intel / Amd boards currently UnSupported"
echo ""
echo "--------------------------------------------------------------"
echo ""
exit
esac

#####################################
#Update base os with new repo in list
#####################################
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

###################
# Notes / Warnings
###################
echo ""
cat << DELIM
                   Not Ment For L.a.m.p Installs

                  L.A.M.P = Linux Apache Mysql PHP

                 THIS IS A ONE TIME INSTALL SCRIPT

             IT IS NOT INTENDED TO BE RUN MULTIPLE TIMES

         This Script Is Ment To Be Run On A Fresh Install Of

                         Debian 8 (Jessie)

     If It Fails For Any Reason Please Report To kb3vgw@gmail.com

   Please Include Any Screen Output You Can To Show Where It Fails

DELIM

###############################################################################################
#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
###############################################################################################
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
#Set a reboot if Kernel Panic
##############################
cat > /etc/sysctl.conf << DELIM
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

############################
# set usb power level
############################
cat >> /boot/config.txt << DELIM

#usb max current
usb_max_current=1
DELIM

#####################################
# Disable Kernel Modules for onboard 
# sound interface card
####################################
cat >> /etc/modules << DELIM
#disable onboard sound
#snd-bcm2835
DELIM

###############################
# Disable the dphys swap file
# Extend life of sd card
###############################
echo ""
echo "--------------------------------------------------------------"
echo "Disabling swap..."
echo "--------------------------------------------------------------"

swapoff --all
apt-get -y remove dphys-swapfile
rm -rf /var/swap

##########################################
#addon extra scripts for cloning the drive
##########################################
cd /usr/local/bin
wget https://raw.githubusercontent.com/billw2/rpi-clone/master/rpi-clone
chmod +x rpi-clone
cd /root 

#####################################################
#fix usb sound/nic issue so network interface gets IP
#####################################################
cat > /etc/network/interfaces << DELIM
auto lo eth0
iface lo inet loopback
iface eth0 inet dhcp
DELIM

#############################
#Setting Host/Domain name
#############################
cat > /etc/hostname << DELIM
$cs-repeater
DELIM

#################
#Setup /etc/hosts
#################
cat > /etc/hosts << DELIM
127.0.0.1       localhost 
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $cs-repeater

DELIM
#################################################################################################
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#################################################################################################
cat > "/etc/apt/sources.list" << DELIM
deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free
DELIM

############
# Raspi Repo
###########################################################################
# Put in Proper Location. All addon repos should be source.list.d sub dir
###########################################################################
cat > /etc/apt/sources.list.d/raspi.list << DELIM
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib firmware non-free rpi
DELIM

#########################
# SVXLink Testing repo
#########################
cat > "/etc/apt/sources.list.d/svxlink.list" <<DELIM
deb http://repo.openrepeater.com/svxlink/devel/debian/ jessie main
DELIM

##########################
# Adding OpenRepeater Repo
##########################
cat > "/etc/apt/sources.list.d/openrepeater.list" <<DELIM
deb http://repo.openrepeater.com/openrepeater/devel/debian/ jessie main
DELIM

######################
#Update base os
######################
echo ""
echo "--------------------------------------------------------------"
echo "Performing Base OS Update..."
echo "--------------------------------------------------------------"

for i in update upgrade clean ;do apt-get -y --force-yes "${i}" ; done

##########################
#Installing Deps
##########################
echo ""
echo "--------------------------------------------------------------"
echo " Installing Dependencies..."
echo "--------------------------------------------------------------"

apt-get install -y --force-yes --fix-missing memcached sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		ntp libasound2 libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 tk8.6 alsa-base bzip2 sudo gpsd gpsd-clients \
		flite wvdial inetutils-syslogd screen time uuid vim install-info usbutils whiptail dialog logrotate cron \
		gawk watchdog python3-serial

######################
#Install svxlink
#####################
echo ""
echo "--------------------------------------------------------------"
echo " Installing install deps and svxlink + remotetrx"
echo "--------------------------------------------------------------"
echo ""
apt-get -y --force-yes install svxlink-server remotetrx
apt-get clean

#making links...
ln -s /etc/openrepeater/svxlink/local-events.d/ /usr/share/svxlink/events.d/local

#add svxlinkuser to gpio group
usermod -G gpio svxlink

#Working on sounds pkgs for future release of svxlink
cd /usr/share/svxlink/sounds
wget https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
tar xjvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
mv en_US-heather* en_US
cd /root

##########################################
#---Start of nginx / php5 install --------
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

#####################################################################################################
#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#####################################################################################################
cat > "/etc/nginx/sites-available/$gui_name"  << DELIM
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

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/\$fastcgi_script_name;
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
# set nginx worker level limit for performance
###############################################
cat > "/etc/nginx/nginx.conf"  << DELIM
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

cat >  /etc/php5/fpm/pool.d/www.conf << DELIM
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

#################################
# Backup and replace php5-fpm.conf
#################################
cp /etc/php5/fpm/php-fpm.conf /etc/php5/fpm/php-fpm.conf.orig

cat > /etc/php5/fpm/php-fpm.conf << DELIM
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

##############################################################
# linking openrepeater nginx config from avaible to enabled sites
##############################################################
ln -s /etc/nginx/sites-available/"$gui_name" /etc/nginx/sites-enabled/"$gui_name"

######################
#disable default site
######################
rm -rf /etc/nginx/sites-enabled/default

# Make sure the path /var/www/ is owned by your web server user:
chown -R www-data:www-data /var/www

##############################
#Restarting Nginx and PHP FPM
##############################
for i in nginx php5-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done

#################################################
# Fetch and Install open repeater project web ui
# ################################################

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

cat > "/etc/default/svxlink" << DELIM
#############################################################################
#
# Configuration file for the SvxLink startup script /etc/init.d/svxlink
#
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

cat > "/etc/default/remotetrx" << DELIM
#############################################################################
#
# Configuration file for the RemoteTrx startup script /etc/init.d/remotetrx
#
#############################################################################
# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

DELIM

#FinalRequired Linking
ln -s /var/www/openrepeater/sounds /usr/share/openrepeater/sounds
rm /usr/share/svxlink/events.d/local
ln -s /etc/openrepeater/svxlink/local-events.d/ /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown www-data:www-data /var/www/openrepeater /etc/openrepeater

cat >> /etc/sudoers << DELIM
#allow www-data to access amixer and service
www-data   ALL=(ALL) NOPASSWD: /usr/local/bin/openrepeater_svxlink_restart, NOPASSWD: /usr/local/bin/openrepeater_svxlink_start, NOPASSWD: /usr/local/bin/openrepeater_svxlink_stop, NOPASSWD: /usr/bin/aplay, NOPASSWD: /usr/bin/arecord
DELIM

###############################################
# INSTALL FTP SERVER / ADD USER FOR DEVELOPMENT
###############################################
if [[ $install_vsftpd == "y" ]]; then
echo ""
echo "--------------------------------------------------------------"
echo " Installing vsFTPd..."
echo "--------------------------------------------------------------"

	apt-get install vsftpd

	edit_config $FTP_CONFIG_PATH anonymous_enable NO enabled
	edit_config $FTP_CONFIG_PATH local_enable YES enabled
	edit_config $FTP_CONFIG_PATH write_enable YES enabled
	edit_config $FTP_CONFIG_PATH local_umask 022 enabled

	cat "force_dot_files=YES" >> "$FTP_CONFIG_PATH"

	system vsftpd restart

	# ############################
	# ADD FTP USER & SET PASSWORD
	# ############################
	adduser $vsftpd_user
fi

echo " ########################################################################################## "
echo " #            You will need to edit the php.ini file and add extensions=memcache.so       # " 
echo " #               location : /etc/php5/fpm/php.ini and then restart web service            # "
echo " ########################################################################################## "
echo
echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " #                                                                                        # "
echo " #                   To Start the service fo svxlink on the cmd line                      # "
echo " #                        run cmd: systemctl enable svxlink.service                       # "
echo " #                                                                                        # "
echo " #                   To Start the service fo remotetrx on the cmd line                    # "
echo " #                        run cmd: systemctl enable remotetrx.service                     # "
echo " #                                                                                        # "
echo " ########################################################################################## "
) | tee /root/install.log