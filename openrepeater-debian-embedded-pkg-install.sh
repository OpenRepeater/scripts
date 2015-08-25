#!/bin/bash
(
############################
#Date Aug 15, 2015 10;00 CST
############################
#
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
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
###################################################################
# Auto Install Configuration options 
# (set it, forget it, run it)
###################################################################

#################################################
# Config file creation and checking.
#################################################
file=config.txt         # Config File Name

# If the config file doesn exist then create it
loadConfigContent=false
if [ ! -e $file ]
        then
        echo "Config file $file doesn't exist, file will be created for your editing prior to your next run of this script."
        touch "$file"
        loadConfigContent=true
fi
# --------------------------
# If the config file is not readable then its not going to do us any good
# --------------------------
if [ ! -r $file ]
        then
        echo "$file exists however it is not readable"
        exit 1
fi
# --------------------------
## If the file exists but doesnt contain variables needed by script, then we really need to
## create those variables in the file, maybe move the file to a backup location then create
## the file with the variables needed so that we can assure that the configuration is correct
# --------------------------
source $file
if ([ ! $cs ] || [ $cs='Set-This' ]) || ([ $odroid_boards='n' ] && [ $beaglebone_boards='n' ] && [ $raspi2_boards='n' ])
        then
        echo "Please make sure you have looked at the options in the configure file."
fi
##################################################
# If there was no config file then we need to load the config
# file with contents
##################################################
if ($loadConfigContent  && [ -e $file ]  &&  [ -w $file ])
        then
                echo "Loading base $file"
                cat <<EOF > $file
####################################################
# Repeater call sign
# Please change this to match the repeater call sign
####################################################
cs="Set-This"

##################################################
# Change this to your domain name if you have one.
##################################################
dn="mydomain.com"

######################################
# The following section allows you to configure your board and some options
######################################
odroid_boards="n"
beaglebone_boards="n"
raspi2_boards="n"
raspi2_overclock="n"
# The following must be raspbian OS updated to jessie
raspbian_os_img="n"

################################################################
# Install Ajenti Optional Admin Portal (Optional) (Not Required)
#           (Currently broken on beaglebone installs)
################################################################
install_ajenti="n" #y/n

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
EOF
else echo "Base $file exists"
fi
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
  echo
  echo "Looks like you need to configure the scirpt before running"
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
echo
echo "Looks Like you are root.... continuing!"
echo

###############################################
#if lsb_release is not installed it installs it
###############################################
if [ ! -s /usr/bin/lsb_release ]; then
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
	echo
	echo " Your OS appears to be: " lsb_release -a
	echo
	echo " Your OS is not currently supported by this script ... "
	echo
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
echo
echo " ArmEL is currenty UnSupported "
echo
exit
esac

########
# ARMHF
########
case $(uname -m) in armv[6-9]l)
echo
echo " ArmHF arm v7 v8 v9 boards supported "
echo
esac

#############
# Intel/AMD
#############
case $(uname -m) in x86_64|i[4-6]86)
echo
echo " Intel / Amd boards currently UnSupported"
echo
exit
esac

################################
#backup default repo source.list
################################
echo " Making backup of sources.list prior to editing... "
cp /etc/apt/sources.list /etc/apt/sources.list.preOpenRepeater

#################################################################################################
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#################################################################################################
echo "installing jessie release repo"
cat > "/etc/apt/sources.list" << DELIM
deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-updates main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-backports main contrib non-free

DELIM

######################
#Update base os
######################
for i in update upgrade ;do apt-get -y "${i}" ; done

apt-get clean
rm /var/cache/apt/archive/*

##########################
# Adding OpenRepeater Repo
##########################
echo " Installing OpenRepeater repo "
echo " svxlink & openrepeater pkgs "
cat > "/etc/apt/sources.list.d/openrepeater.list" <<DELIM
deb http://repo.openrepeater.com/openrepeater/release/debian/ jessie main
DELIM

#####################################
#Update base os with new repo in list
#####################################
apt-get update

###################
#odroid extra repo
###################
if [[ $odroid_boards == "y" ]]; then
	cat >> "/etc/apt/sources.list.d/odroid.list" << DELIM
	deb http://deb.odroid.in/ trusty main
DELIM

#####################################
#Update base os with new repo in list
#####################################
apt-get update
fi

#########################
#beagle bone  extra repo
#########################
if [[ $beaglebone_boards == "y" ]]; then
cat >> "/etc/apt/sources.list.d/beaglebone.list" << DELIM
	deb [arch=armhf] http://repos.rcn-ee.net/debian/ jessie main
	#deb-src [arch=armhf] http://repos.rcn-ee.net/debian/ jessie main
DELIM

#####################################
#Update base os with new repo in list
#####################################
apt-get update

#########################
#raspi2 repo
#########################
if [[ $raspi2_boards == "y" ]]; then
cat >> "/etc/apt/sources.list.d/raspi2.list" << DELIM
deb [trusted=yes] https://repositories.collabora.co.uk/debian/ jessie rpi2
DELIM
fi

#####################################
#Update base os with new repo in list
#####################################
apt-get update
fi

#########################
# Raspbian repo
#########################
if [[ $raspbian_os_img == "y" ]]; then
cat >> "/etc/apt/sources.list.d/raspbian.list" << DELIM
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi
DELIM
#####################################
#add in the raspbian key for the repo
#####################################
wget http://mirrordirector.raspbian.org/raspbian.public.key | apt-key add -

#####################################
#Update base os with new repo in list
#####################################
apt-get update
fi

###################
# Notes / Warnings
###################
echo
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

###########################
# Pre-Install Information
###########################
echo
cat << DELIM
  Note:

  Pre-Install Information:

    This script uses Sqlite by default. No plans to use Other DB. 

DELIM
echo

###############################################################################################
#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
###############################################################################################
echo
echo "This Script Currently Requires a internet connection "
echo
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "I Found the Internet ... continuing!!!!!"
	/bin/rm /tmp/index.google
fi
echo
printf ' Current ip is : '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
echo

######################
#Install Dependancies
#####################
echo " Installing install deps and svxlink + remotetrx"
apt-get install -y --force-yes memcached sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		minicom ntp libasound2 libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 alsa-base bzip2 sudo network-manager \
		gpsd gpsd-clients flite wvdial usbmount htop screen time uuid rsyslog vim install-info usbutils tcpd \
		python-pysqlite2 \
		svxlink-server remotetrx 
apt-get clean
rm /var/cache/apt/archive/*

#Working on sounds pkgs for future release of svxlink
cd /usr/share/svxlink/sounds
wget https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
tar xjvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
mv en_US-heather* en_US
cd /root

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
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
DELIM

# ####################################
# DISABLE BEAGLEBONE 101 WEB SERVICES
# ####################################
if [[ $beaglebone_boards == "y" ]]; then
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

cat >> /boot/uEnv.txt << DELIM

#####################
#Disable HDMI sound
#####################
optargs=capemgr.disable_partno=BB-BONELT-HDMI
DELIM

apt-get -y autoremove apache2*
fi

##########################################
# Overclock the Raspi-2 to 1ghz for better
# Performance and stablization.
##########################################
if [[ $raspi2_overclock == "y" ]]; then
cat >> /boot/firmware/config.txt << DELIM
#over clocking for stability
arm_freq=1000
sdram_freq=500
core_freq=500
over_voltage=2
DELIM
fi

########################################
# Configure nptd to use gps/npt servers
# for getting and setting time
########################################
cp /etc/ntp.conf /etc/ntp.conf.orig

cat > /etc/ntp.conf << DELIM
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help
driftfile       /var/lib/ntp/ntp.drift 
# Enable this if you want statistics to be logged.
# statsdir /var/log/ntpstats/
statistics      loopstats       peerstats       clockstats
filegen loopstats       file    loopstats       type    day     enable
filegen peerstats       file    peerstats       type    day     enable
filegen clockstats      file    clockstats      type    day     enable
# Access control configuration; see /usr/share/doc/ntp-doc/html/accopt.html for
# details.  The web page <http://support.ntp.org/bin/view/Support/AccessRestrictions>
# might also be helpful.
#
# Note that "restrict" applies to both servers and clients, so a configuration
# that might be intended to block requests from certain clients could also end
# up blocking replies from your own upstream servers.
# By default, exchange time with everybody, but don't allow configuration.
restrict        -4      default kod     notrap  nomodify        nopeer  noquery
restrict        -6      default kod     notrap  nomodify        nopeer  noquery
restrict        127.0.0.1 # Local users may interrogate the ntp server more closely.
restrict        ::1
# Read the rough GPS time from device 127.127.28.0
# Read the accurate PPS time from device 127.127.28.1
server 127.127.28.0 minpoll 4 maxpoll 4
fudge 127.127.28.0 time1 0.535 refid GPS
server 127.127.28.1 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.1 refid PPS
# Use servers from the ntp pool for the first synchronization,
# or as a backup if the GPS is disconnected
server	0.pool.ntp.org
server  1.pool.ntp.org
server  2.pool.ntp.org
server  3.pool.ntp.org
DELIM

##########################################
#---Start of nginx / php5 install --------
##########################################
apt-get -y install ssl-cert nginx php5-cli php5-common php-apc php5-gd php-db php5-fpm php5-memcache php5-sqlite

apt-get clean
rm /var/cache/apt/archive/*

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

##############################################################
# linking fusionpbx nginx config from avaible to enabled sites
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
mkdir $WWW_PATH/$gui_name

apt-get install -y --force-yes openrepeater

find "$WWW_PATH" -type d -exec chmod 775 {} +
find "$WWW_PATH" -type f -exec chmod 664 {} +

chown -R www-data:www-data $WWW_PATH

cp /etc/default/svxlink /etc/default/svxlink.orig
cat > "/etc/default/svxlink" << DELIM
#############################################################################
#
# Configuration file for the SvxLink startup script /etc/init.d/svxlink
#
#############################################################################

# The log file to use
LOGFILE=/var/log/svxlink

# The PID file to use
PIDFILE=/var/run/svxlink.pid

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/svxlink.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

# GPIO_PTT_PIN=<num>
#     <num> defines the GPIO pin used for PTT.
# GPIO_SQL_PIN=<num>
#     <num> defines the GPIO pin used for Squelch.

#GPIO_PTT_PIN=
#GPIO_SQL_PIN=

#uesd for openrepeater to get gpio pins
if [ -r /etc/openrepeater/svxlink/svxlink_gpio.conf ]; then
        . /etc/openrepeater/svxlink/svxlink_gpio.conf
fi

DELIM

mv /etc/default/remotetrx /etc/default/remotetrx.orig
cat > "/etc/default/remotetrx" << DELIM
#############################################################################
#
# Configuration file for the RemoteTrx startup script /etc/init.d/remotetrx
#
#############################################################################

# The log file to use
LOGFILE=/var/log/remotetrx

# The PID file to use
PIDFILE=/var/run/remotetrx.pid

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

DELIM

#making links...
ln -s /usr/share/openrepeater/sounds/courtesy_tones /var/www/openrepeater/courtesy_tones
ln -s /etc/openrepeater/svxlink/local-events.d/ /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown www-data:www-data /var/www/openrepeater/courtesy_tones

cp -rp /usr/share/examples/openrepeater/install/svxlink/* /etc/openrepeater/svxlink
cp -rp /usr/share/examples/openrepeater/install/sql/openrepeater.db /var/lib/openrepeater/db
cp -rp /usr/share/examples/openrepeater/install/sql/database.php /etc/openrepeater

chown -R www-data:www-data /var/lib/openrepeater /etc/openrepeater

#########################
#restart svxlink service
#########################
service svxlink restart

#################
# Configure Sudo 
#################
cat > "/usr/local/bin/svxlink_restart" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running"
    echo "\$(date): Restarting svxlink service with updated configuration"
    sudo service svxlink try-restart
else
    echo "\$(date): \$SERVICE is not running"
    echo "\$(date): Starting svxlink up with first time new configuration"
    sudo service svxlink start
fi
DELIM

cat > "/usr/local/bin/svxlink_stop" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running, Stopping svxlink service"
    sudo svxlink stop
else
    echo "\$(date): \$SERVICE is not running"
fi
DELIM

cat > "/usr/local/bin/svxlink_start" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running, all is fine"
else
    echo "\$(date): \$SERVICE is not running"
    echo "\$(date): Atempting to start svxlink"
    sudo service svxlink start
fi
DELIM

cat > "/usr/local/bin/repeater_reboot" << DELIM
#!/bin/bash
sudo -u www-data /sbin/reboot
DELIM

sudo chown root:www-data /usr/local/bin/svxlink_restart /usr/local/bin/svxlink_start /usr/local/bin/svxlink_stop /usr/local/bin/repeater_reboot
sudo chmod 550 /usr/local/bin/svxlink_restart /usr/local/bin/svxlink_start /usr/local/bin/svxlink_stop /usr/local/bin/repeater_reboot

cat >> /etc/sudoers << DELIM
#allow www-data to access amixer and service
www-data   ALL=(ALL) NOPASSWD: /usr/local/bin/svxlink_restart, NOPASSWD: /usr/local/bin/svxlink_start, NOPASSWD: /usr/local/bin/svxlink_stop, NOPASSWD: /usr/local/bin/repeater_reboot
DELIM

#########################################################
#-----Installing Fail2Ban/monit Protection services------
#########################################################
for i in fail2ban monit ;do apt-get -y install "${i}" ; done

###############################################
# INSTALL FTP SERVER / ADD USER FOR DEVELOPMENT
###############################################
if [[ $install_vsftpd == "y" ]]; then
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

#############################
#Install Ajenti Admin Portal
#############################
if [[ $install_ajenti == "y" ]]; then
##########################
#ADD Ajenti repo & ajenti
##########################
echo "Installing Ajenti Admin Portal"
cat > "/etc/apt/sources.list.d/ajenti.list" <<DELIM
deb http://repo.ajenti.org/debian main main debian
DELIM

######################
# add ajenti repo key
######################
wget http://repo.ajenti.org/debian/key -O- | apt-key add -

#################
# install ajenti
#################
apt-get update
apt-get install -y ajenti task openvpn supervisor python-memcache python-beautifulsoup cron
apt-get clean
rm /var/cache/apt/archive/*
fi

#############################
#Setting Host/Domain name
#############################
cat >> /etc/hostname << DELIM
$cs-repeater
DELIM

#################
#Setup /etc/hosts
#################
cat > /etc/hosts << DELIM
127.0.0.1       localhost
127.0.0.1       $sc-repeater
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
DELIM

echo " You will need to edit the php.ini file and add extensions=memcache.so " 
echo " location : /etc/php5/fpm/php.ini and then restart web service "

echo " ########################################################################################## "
echo " #    The Open Repeater Project / SVXLink / Echolink server Install is now complete       # "
echo " #                          and your system is ready for use..                            # "
echo " #                                                                                        # "
echo " #                   Please send any feed back to kb3vgw@gmail.com                        # "
echo " ########################################################################################## "
) | tee logfile.txt
