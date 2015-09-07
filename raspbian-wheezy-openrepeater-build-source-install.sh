#!/bin/bash
(
####################################################################
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

# ----- Start Edit Here ----- #
####################################################
# Repeater call sign
# Please change this to match the repeater call sign
####################################################
cs="Set_This"

###################################################
# Put /var/log into a tmpfs to improve performance 
# Super user option dont try this if you must keep 
# logs after every reboot
###################################################
put_logs_tmpfs="n"

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
lsb_release -c |grep -i wheezy &> /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo " OK you are running Debian 8 : wheezy "
else
	echo " This script was written for Debian 8 wheezy "
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
echo " ArmHF arm v6 v7 v8 v9 boards supported "
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

                         Debian 8 (wheezy)

     If It Fails For Any Reason Please Report To kb3vgw@gmail.com

   Please Include Any Screen Output You Can To Show Where It Fails

DELIM

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

####################################
# Reconfigure system for performance
####################################
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
tmpfs /tmp  tmpfs size=20M,defaults,nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs size=20M,defaults,nodev,nosuid,mode=1777  0 0
tmpfs /var/cache/apt/archives tmpfs   size=100M,defaults,noexec,nosuid,nodev,mode=0755 0 0
DELIM

########################
# cnfigure tmpfs sizes
########################
cp /etc/default/tmpfs /etc/default/tmpfs.orig
cat > /etc/default/tmpfs << DELIM
RAMLOCK=yes
RAMSHM=yes
RAMTMP=yes

TMPFS_SIZE=10%VM
RUN_SIZE=10M
LOCK_SIZE=5M
SHM_SIZE=10M
TMP_SIZE=25M

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
# hdmi sound interface card
####################################
cat >> /etc/modules << DELIM
#disable onboard sound
#snd-bcm2835
DELIM

##########################################
# SETUP configuration for /tmpfs for logs
##########################################
if [[ $put_logs_tmpfs == "y" ]]; then
#################
#configure fstab
#################
cat >> /etc/fstab << DELIM
tmpfs   /var/log  tmpfs   size=20M,defaults,noatime,mode=0755 0 0 
DELIM

#######################################
# Configure /var/log dir's on reboots
#######################################
cat > /etc/init.d/preplog-dirs << DELIM
#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          prepare-dirs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Required-Start:
# Required-Stop:
# Short-Description: Create needed directories on /var/log/ for tmpfs at startup
# Description:       Create needed directories on /var/log/ for tmpfs at startup
### END INIT INFO
# needed Dirs
DIR[0]=/var/log/nginx
DIR[1]=/var/log/apt
DIR[2]=/var/log/ConsoleKit
DIR[3]=/var/log/fsck
DIR[4]=/var/log/news
DIR[5]=/var/log/ntpstats
DIR[6]=/var/log/samba
DIR[7]=/var/log/lastlog
DIR[8]=/var/log/exim
DIR[9]=/var/log/watchdog
case "${1:-''}" in
  start)
        typeset -i i=0 max=${#DIR[*]}
        while (( i < max ))
        do
                mkdir  ${DIR[$i]}
                chmod 755 ${DIR[$i]}
                i=i+1
        done
        # set rights
        chown www-data.adm ${DIR[0]}
        chown root.adm ${DIR[6]}
    ;;
  stop)
    ;;
  restart)
   ;;
  reload|force-reload)
   ;;
  status)
   ;;
  *)
DELIM

chmod 755 /etc/init.d/preplog-dirs

fi

###############################
# Disable the dphys swap file
# Extend life of sd card
###############################
swapoff --all
apt-get -y remove dphys-swapfile
rm -rf /var/swap

######################
#Update base os
######################
for i in update upgrade clean ;do apt-get -y "${i}" ; done

#################
#Installing Deps
#################
apt-get install -y --force-yes sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		ntp libasound2 libspeex1 libgcrypt11 libpopt0 libgsm1 tcl8.5 alsa-base bzip2 flite screen time \
		uuid inetutils-syslogd
 vim install-info whiptail dialog logrotate cron usbutils git-core tk8.5

########################
# Install Build Depends
#######################		
apt-get install -y --force-yes gawk uuid-dev g++ make cmake libsigc++-2.0-dev libgsm1-dev libpopt-dev \
		libgcrypt11-dev libspeex-dev libasound2-dev alsa-utils vorbis-tools sox libsox-fmt-mp3 sqlite3 \
		unzip opus-tools tcl8.5-dev alsa-base ntp groff doxygen libopus-dev tk8.5-dev

##################################
# Add User and include in groupds
##################################
# Sane defaults:
[ -z "$SERVER_HOME" ] && SERVER_HOME=/usr/bin
[ -z "$SERVER_USER" ] && SERVER_USER=svxlink
[ -z "$SERVER_NAME" ] && SERVER_NAME="Svxlink-related Daemons"
[ -z "$SERVER_GROUP" ] && SERVER_GROUP=daemon
     
# Groups that the user will be added to, if undefined, then none.
ADDGROUP="audio dialout"
     
# create user to avoid running server as root
# 1. create group if not existing
if ! getent group | grep -q "^$SERVER_GROUP:" ; then
   echo -n "Adding group $SERVER_GROUP.."
   addgroup --quiet --system $SERVER_GROUP 2>/dev/null ||true
   echo "..done"
fi
    
# 2. create homedir if not existing
test -d $SERVER_HOME || mkdir $SERVER_HOME
    
# 3. create user if not existing
if ! getent passwd | grep -q "^$SERVER_USER:"; then
   echo -n "Adding system user $SERVER_USER.."
   adduser --quiet \
           --system \
           --ingroup $SERVER_GROUP \
           --no-create-home \
           --disabled-password \
           $SERVER_USER 2>/dev/null || true
   echo "..done"
fi
    
# 4. adjust passwd entry
usermod -c "$SERVER_NAME" \
    -d $SERVER_HOME   \
    -g $SERVER_GROUP  \
    $SERVER_USER
# 5. Add the user to the ADDGROUP group

for group in $ADDGROUP ; do
if test -n "$group"
then
    if ! groups $SERVER_USER | cut -d: -f2 | grep -qw "$group"; then
	adduser $SERVER_USER "$group"
    fi
fi
done

#########################
# get svxlink src
#########################
cd /usr/src
wget https://github.com/sm0svx/svxlink/archive/14.08.1.tar.gz
tar xzvf 14.08.1.tar.gz

#############################
#Build & Install svxllink
#############################
cd /usr/src/svxlink-14.08.1/src || exit
mkdir /usr/src/svxlink-14.08.1/src/build
cd /usr/src/svxlink-14.08.1/src/build || exit
cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DBUILD_STATIC_LIBS=YES -DUSE_OSS=NO -DUSE_QT=NO ..
make -j4
make doc
make install
ldconfig
cd /root

#############################
# Svx Init.d/systamd scripts
#############################
cat > /etc/init.d/svxlink << DELIM
#!/bin/sh

### BEGIN INIT INFO
# Provides:        svxlink
# Required-Start:  $network $local_fs $remote_fs $syslog $time
# Required-Stop:   $remote_fs
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: Start SvxLink Server daemon
# Description: Start SvxLink Server daemon
### END INIT INFO

# Use the following command to activate the start script
#   update-rc.d svxlink start 30 2 3 4 5 . stop 70 0 1 6 .

PATH=/sbin:/bin:/usr/sbin:/usr/bin

. /lib/lsb/init-functions

PNAME=svxlink

NAME="SvxLink Server"
DAEMON=/usr/bin/$PNAME

test -x $DAEMON || exit 0

if [ -r /etc/default/$PNAME ]; then
        . /etc/default/$PNAME
fi

#if [ -n "$PIDFILE" ]; then PIDFILE=/var/run/$PNAME; fi
#if [ -n "$LOGFILE" ]; then LOGFILE=/var/log/$PNAME; fi
#if [ -n "$CFGFILE" ]; then CFGFILE=/etc/svxlink/$PNAME.conf; fi
#if [ -n "$RUNASUSER" ]; then RUNASUSER=svxlink; fi


POPTS="--daemon ${RUNASUSER:+--runasuser=$RUNASUSER} ${PIDFILE:+--pidfile=$PIDFILE} ${LOGFILE:+--logfile=$LOGFILE} ${CFGFILE:+--config=$CFGFILE}"

gpio_setup() {
   NAME=$1
   PIN=$2
   DIR=$3
   if [ ! -z "$PIN" -a ! -e /sys/class/gpio/gpio$PIN ]; then
       # Enable the pin for GPIO:
       echo $PIN > /sys/class/gpio/export
       # Set the direction to output for the pin:
       echo $DIR > /sys/class/gpio/gpio$PIN/direction
       # If pin direction is an input then set active low:
       if [ "$DIR" = "in" ]; then
          echo 1 >/sys/class/gpio/gpio$PIN/active_low
       fi
       # Make sure that the "RUNASUSER" user can write to the GPIO pin:
       chown $RUNASUSER /sys/class/gpio/gpio$PIN/value
       log_progress_msg "[$NAME: GPIO_$PIN]"
   fi
}


gpio_teardown() {
   NAME=$1
   PIN=$2
   if [ ! -z "$PIN" -a -e /sys/class/gpio/gpio$PIN ]; then
       log_progress_msg "[$NAME: GPIO_$PIN stop]"
       # Disable the pin for GPIO:
       echo $PIN > /sys/class/gpio/unexport
   fi
}

create_logfile()
{
        touch $LOGFILE

        if [ -n "$RUNASUSER" ]; then
                chown $RUNASUSER $LOGFILE
        fi
}


case $1 in
        start)
                log_daemon_msg "Starting $NAME: $PNAME"
                create_logfile

                ## GPIO PTT support ?
                for i in $GPIO_PTT_PIN
                do
                if [ ! -z "$i" -a ! -e /sys/class/gpio/gpio"$i" ]; then
                   log_daemon_msg "Initialize PTT GPIO" "gpio$i"
                   gpio_setup PTT "$i" out
                fi
                done
                
                ## GPIO SQL support ?
                for i in $GPIO_SQL_PIN
                do
                if [  ! -z "$i" -a ! -e /sys/class/gpio/gpio"$i" ]; then
                   log_daemon_msg "Initialize Squelch GPIO" "gpio$i"
                   gpio_setup SQL "$i" in
                fi
                done
                
                export $ENV
                start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON -- $POPTS
                log_end_msg $?
                ;;
        stop)
                log_daemon_msg "Stopping $NAME: $PNAME"
                start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
                rm -f $PIDFILE
                
                ## Unset GPIO PTT pin, if used
                for i in $GPIO_PTT_PIN
                do
                if [ ! -z "$i" ]; then
                   log_daemon_msg "Tearing Down PTT GPIO" "gpio$i"
                   gpio_teardown PTT "$i"
                fi
                done
				
                ## Unset GPIO SQL pin, if used
                for i in $GPIO_SQL_PIN
                do
                if [ ! -z "$i" ]; then
                   log_daemon_msg "Tearing Down Squelch GPIO" "gpio$i"
                   gpio_teardown SQL "$i"
                fi
                done

                log_end_msg $?
                ;;
        restart|force-reload)
                $0 stop && sleep 2 && $0 start
                ;;
        try-restart)
                if $0 status >/dev/null; then
                       $0 stop && sleep 5 && $0 restart
                else
                        exit 0
                fi
                ;;
        reload)
                exit 3
                ;;
        status)
                pidofproc -p $PIDFILE $DAEMON >/dev/null
                status=$?
                if [ $status -eq 0 ]; then
                        log_success_msg "$NAME is running."
                else
                        log_failure_msg "$NAME is not running."
                fi
                exit $status
                ;;
        *)
                echo "Usage: $0 {start|stop|restart|try-restart|force-reload|status}"
                exit 2
                ;;
esac
DELIM

cat > /etc/init.d/remotetrx << DELIM
#!/bin/sh

### BEGIN INIT INFO
# Provides:        remotetrx
# Required-Start:  $network $local_fs $remote_fs $syslog $time
# Required-Stop:   $remote_fs
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: Start RemoteTRX Server daemon
# Description: Start RemoteTRX Server daemon
### END INIT INFO

# Use the following command to activate the start script
#   update-rc.d svxlink start 30 2 3 4 5 . stop 70 0 1 6 .

PATH=/sbin:/bin:/usr/sbin:/usr/bin

. /lib/lsb/init-functions

PNAME=remotetrx
NAME="RemoteTRX Server"
DAEMON=/usr/bin/$PNAME

test -x $DAEMON || exit 0

if [ -r /etc/default/$PNAME ]; then
	. /etc/default/$PNAME
fi

#PIDFILE=/var/run/$PNAME
#LOGFILE=/var/log/$PNAME
#CFGFILE=/etc/svxlink/$PNAME.conf
#RUNASUSER=svxlink

POPTS="--daemon ${RUNASUSER:+--runasuser=$RUNASUSER} ${PIDFILE:+--pidfile=$PIDFILE} ${LOGFILE:+--logfile=$LOGFILE} ${CFGFILE:+--config=$CFGFILE}"

create_logfile()
{
	touch $LOGFILE
	if [ -n "$RUNASUSER" ]; then
		chown $RUNASUSER $LOGFILE
	fi
}

case $1 in
	start)
		log_daemon_msg "Starting $NAME: $PNAME"
		create_logfile
 		export $ENV
  		start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON -- $POPTS
		log_end_msg $?
  		;;
	stop)
		log_daemon_msg "Stopping $NAME: $PNAME"
  		start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
		log_end_msg $?
		rm -f $PIDFILE
  		;;
	restart|force-reload)
		$0 stop && sleep 2 && $0 start
  		;;
	try-restart)
		if $0 status >/dev/null; then
			$0 restart
		else
			exit 0
		fi
		;;
	reload)
		exit 3
		;;
	status)
		pidofproc -p $PIDFILE $DAEMON >/dev/null
		status=$?
		if [ $status -eq 0 ]; then
			log_success_msg "$NAME is running."
		else
			log_failure_msg "$NAME is not running."
		fi
		exit $status
		;;
	*)
		echo "Usage: $0 {start|stop|restart|try-restart|force-reload|status}"
		exit 2
		;;
esac
DELIM

cat > /etc/default/svxlink << DELIM
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
CFGFILE=/etc/svxlink/svxlink.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

# GPIO_PTT_PIN="<num> <num>"
#     <num> defines the GPIO pin used for PTT.
# GPIO_SQL_PIN="<num> <num>"
#     <num> defines the GPIO pin used for Squelch.

#GPIO_PTT_PIN=""
#GPIO_SQL_PIN=""
DELIM

cat > /etc/default/remotetrx<< DELIM
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
CFGFILE=/etc/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"
DELIM

cat > /lib/systemd/system/svxlink.service << DELIM
;;;;; Author: Richard Neese<kb3vgw@gmail.com>

[Unit]
Description=svxlink
After=syslog.target network.target local-fs.target

[Service]
; service
Type=forking
PIDFile=/run/svxlink/svxlink.pid
PermissionsStartOnly=true
ExecStartPre=/bin/mkdir -p /run/svxlink
ExecStartPre=/bin/chown svxlink:svxlink /run/svxlink
ExecStart=/usr/bin/svxlink 
TimeoutSec=45s
Restart=always
; exec
WorkingDirectory=/run/svxlink
User=svxlink
Group=svxlink
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
;LimitSTACK=240
LimitRTPRIO=infinity
LimitRTTIME=7000000
IOSchedulingClass=realtime
IOSchedulingPriority=2
CPUSchedulingPolicy=rr
CPUSchedulingPriority=89
UMask=0007

[Install]
WantedBy=multi-user.target
DELIM

cat > /lib/systemd/system/remotetrx.service << DELIM
;;;;; Author: Richard Neese<kb3vgw@gmail.com>

[Unit]
Description=remotetrx
After=syslog.target network.target local-fs.target

[Service]
; service
Type=forking
PIDFile=/run/svxlink/remotetrx.pid
PermissionsStartOnly=true
ExecStartPre=/bin/mkdir -p /run/svxlink
ExecStartPre=/bin/chown svxlink:svxlink /run/svxlink
ExecStart=/usr/bin/remotetrx 
TimeoutSec=45s
Restart=always
; exec
WorkingDirectory=/run/svxlink
User=svxlink
Group=svxlink
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
;LimitSTACK=240
LimitRTPRIO=infinity
LimitRTTIME=7000000
IOSchedulingClass=realtime
IOSchedulingPriority=2
CPUSchedulingPolicy=rr
CPUSchedulingPriority=89
UMask=0007

[Install]
WantedBy=multi-user.target
DELIM

cat > /etc/logrotate.d/svxlink-server << DELIM
/var/log/svxlink {
    missingok
    notifempty
    weekly
    create 0644 svxlink adm
    postrotate
        killall -HUP svxlink
    endscript
}
DELIM

cat > /etc/logrotate.d/remotetrx << DELIM
/var/log/remotetrx {
    missingok
    notifempty
    weekly
    create 0644 svxlink adm
    postrotate
        killall -HUP remotetrx
    endscript
}

DELIM

chmod +x /etc/init.d/svxlink /etc/init.x/remotetrx
#######################################################
#Install svxlink en_US sounds
#Working on sounds pkgs for future release of svxlink
########################################################
cd /usr/share/svxlink/sounds || exit
wget https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
tar xjvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
mv en_US-heather* en_US
cd /root || exit

##########################################
#---Start of nginx / php5 install --------
##########################################
apt-get -y install ssl-cert openssl-blacklist nginx memcached php5-cli php5-common \
		php-apc php5-gd php-db php5-fpm php5-memcache php5-sqlite

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
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
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
cp /etc/php5/fpm/php5-fpm.conf /etc/php5/fpm/php5-fpm.conf.orig

cat > /etc/php5/fpm/php5-fpm.conf << DELIM
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

######################################################
# Pull openrepeater from github and then cp into place
######################################################
cd /usr/src || exit
git clone https://github.com/OpenRepeater/webapp.git openrepeater-gui
cd /usr/src/openrepeater-gui || exit

###############################
# create fhs layout directories
################################
mkdir -p /etc/openrepeater/svxlink
mkdir -p /usr/share/openrepeater/sounds
mkdir -p /usr/share/examples/openrepeater/install
mkdir -p /var/lib/openrepeater/db
mkdir -p /var/lib/openrepeater/recordings
mkdir -p /var/lib/openrepeater/macros
mkdir -p /var/www/openrepeater

##########################################
#copy openrepeater into proper fhs layout
##########################################
cp -rp install/sql /usr/share/examples/openrepeater/install
cp -rp install/svxlink /usr/share/examples/openrepeater/install
cp -rp install/courtesy_tones /usr/share/openrepeater/sounds
cp -rp theme functions dev includes ./*.php /var/www/openrepeater

#################################################
# Fetch and Install open repeater project web ui
# ################################################

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

cp -rp /usr/share/examples/openrepeater/install/svxlink-conf/* /etc/openrepeater/svxlink
cp -rp /usr/share/examples/openrepeater/install/sql/openrepeater.db /var/lib/openrepeater/db
cp -rp /usr/share/examples/openrepeater/install/sql/database.php /etc/openrepeater

chown -R www-data:www-data /var/lib/openrepeater /etc/openrepeater

#########################
#restart svxlink service
#########################
service svxlink restart

#####################################################################
# Configure Sudo / scripts for the gui to start/stop/restart svxlink
#####################################################################
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
www-data   ALL=(ALL) NOPASSWD: /usr/local/bin/svxlink_restart, NOPASSWD: /usr/local/bin/svxlink_start, NOPASSWD: /usr/local/bin/svxlink_stop, NOPASSWD: /usr/local/bin/repeater_reboot, NOPASSWD: /usr/bin/aplay, NOPASSWD: /usr/bin/arecord
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

##########################################
#addon extra scripts for cloning the drive
##########################################
cd /usr/local/bin
wget https://raw.githubusercontent.com/billw2/rpi-clone/master/rpi-clone
chmod +x rpi-clone
cd /root 

########################################
#Install raspi-openrepeater-config menu
########################################
#apt-get install openrepeater-menu

##################################
# Enable New shellmenu for logins
# on enabled for root and only if 
# the file exist
##################################
cat >> /root/.profile << DELIM

if [ -f /usr/local/bin/odroid-openrepeater-conf ]; then
        . /usr/local/bin/odroid-openrepeater-conf
fi

DELIM

echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " ########################################################################################## "
) | tee /root/install.log
