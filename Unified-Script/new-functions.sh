#!/bin/bash
################################################################################
#
# DEFINE VARIABLES (Scroll down for main script)
#
################################################################################

REQUIRED_OS_VER="9"
REQUIRED_OS_NAME="Stretch"

# Upload size limit for php
upload_size="25M"

WWW_PATH="/var/www"
gui_name="openrepeater"

# PHP ini config file
php_ini="/etc/php/7.0/fpm/php.ini"



################################################################################
#
# DEFINE FUNCTIONS (Scroll down for main script)
#
################################################################################

function check_root {
	if [[ $EUID -ne 0 ]]; then
		echo "--------------------------------------------------------------"
		echo " This script must be run as root...ABORTING!"
		echo "--------------------------------------------------------------"
		exit 1
	else
		echo "--------------------------------------------------------------"
		echo " Looks like you are running as root...Continuing!"
		echo "--------------------------------------------------------------"
	fi	
}

################################################################################

function check_internet {
	wget -q --spider http://google.com
	
	if [ $? -eq 0 ]; then
		echo "--------------------------------------------------------------"
		echo " INTERNET CONNECTION REQUIRED: Connection Found...Continuing!"
		echo "--------------------------------------------------------------"
	else
		echo "--------------------------------------------------------------"
		echo " INTERNET CONNECTION REQUIRED: Not Connection...Aborting!"
		echo "--------------------------------------------------------------"
		exit 1
	fi
}

################################################################################

function check_os {
	# Detects ARM processor
	if (cat < /proc/cpuinfo | grep ARM > /dev/null) ; then
		PROCESSOR="ARM"
	else
		PROCESSOR="UNSUPPORTED"
	fi
	
	# Detects Debian Version
	if (grep -q "$REQUIRED_OS_VER." /etc/debian_version) ; then
		DEBIAN_VERSION="$REQUIRED_OS_VER"
	else
		DEBIAN_VERSION="UNSUPPORTED"
	fi

	# Abort if there is a mismatch
	if [ "$PROCESSOR" != "ARM" ] || [ "$DEBIAN_VERSION" != "$REQUIRED_OS_VER" ] ; then
		echo
		echo "**** ERROR ****"
		echo "This script will only work on Debian $REQUIRED_OS_VER ($REQUIRED_OS_NAME) images at this time."
		echo "No other version of Debian is supported at this time. "
		echo "**** EXITING ****"
		exit -1
	fi
}

################################################################################

function check_network {
	# Get Eth0 IP for later display
	ip_address=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1);
}

################################################################################

function add_debian_repos {
	echo "--------------------------------------------------------------"
	echo " Adding Debian Repository...                                  "
	echo "--------------------------------------------------------------"

	LC_OS_NAME=$(echo "$REQUIRED_OS_NAME" | tr '[:upper:]' '[:lower:]')

# 	cat > /etc/apt/sources.list <<- DELIM
# 		deb http://httpredir.debian.org/debian/ $LC_OS_NAME main contrib non-free
# 		deb http://httpredir.debian.org/debian/ $LC_OS_NAME-updates main contrib non-free
# 		deb http://httpredir.debian.org/debian/ $LC_OS_NAME-backports main contrib non-free
# 		deb http://security.debian.org/ $LC_OS_NAME/updates main contrib non-free
# 		DELIM
# 
# 	#install debian keys
# 	echo "--------------------------------------------------------------"
# 	echo " Updating Debian repository keys..                            "
# 	echo "--------------------------------------------------------------"
# 	apt-get install -y --force-yes --fix-missing debian-archive-keyring debian-keyring debian-ports-archive-keyring
# 	apt-key update
}

################################################################################

function install_svxlink {
	echo "GitHub install code goes here"
}

################################################################################

function install_webserver {
	echo "GitHub install code goes here"

	echo "--------------------------------------------------------------"
	echo " Installing NGINX and PHP"
	echo "--------------------------------------------------------------"
	apt-get install -y --fix-missing nginx-extras; apt-get install nginx memcached ssl-cert \
		openssl-blacklist php-common php-fpm php-common php-curl php-dev php-gd php-imagick php-mcrypt \
		php-memcache php-pspell php-snmp php-sqlite3 php-xmlrpc php-xsl php-pear php-ssh2 php-cli
	
	apt-get clean
	
	echo "--------------------------------------------------------------"
	echo " Backup original config files"
	echo "--------------------------------------------------------------"
	cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
	cp /etc/php/7.0/fpm/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf.orig
	cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.orig
	cp /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.orig
	
	echo "--------------------------------------------------------------"
	echo " Installing self signed certificate                           "
	echo "--------------------------------------------------------------"
	cp -r /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
	cp -r /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt
	
	echo "--------------------------------------------------------------"
	echo " Changing file upload size from 2M to upload_size             "
	echo "--------------------------------------------------------------"
	sed -i "$php_ini" -e "s#upload_max_filesize = 2M#upload_max_filesize = $upload_size#"
	
	# Changing post_max_size limit from 8M to upload_size
	sed -i "$php_ini" -e "s#post_max_size = 8M#post_max_size = $upload_size#"
	
	echo "--------------------------------------------------------------"
	echo " Enabling memcache in php.ini                                 "
	echo "--------------------------------------------------------------"
	cat >> "$php_ini" <<- DELIM 
		extensions=memcache.so 
		DELIM
	
	echo "--------------------------------------------------------------"
	echo " Remove / Copy / Link  Nginx & php files into place                                   "
	echo "--------------------------------------------------------------"
	rm -rf /etc/nginx/sites-enabled/default
	
	echo "--------------------------------------------------------------"
	echo " Linking the nginx config to run                              "
	echo "--------------------------------------------------------------"
	ln -s /etc/nginx/sites-available/"$gui_name" /etc/nginx/sites-enabled/"$gui_name"
	
	echo "--------------------------------------------------------------"
	echo " Make sure the path /var/www/ is owned by your web server user"
	echo "--------------------------------------------------------------"
	chown -R www-data:www-data "$WWW_PATH/$gui_name"
	
	echo "--------------------------------------------------------------"
	echo " Restarting Nginx and PHP FPM...                              "
	echo "--------------------------------------------------------------"
	for i in nginx php-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done	
}

################################################################################

function install_orp_dependancies {
	echo "--------------------------------------------------------------"
	echo " Installing OpenRepeater/SVXLink Dependencies"
	echo "--------------------------------------------------------------"

	apt-get install -y --fix-missing alsa-base alsa-utils bzip2 cron dialog fail2ban flite gawk \
		git-core gpsd gpsd-clients i2c-tools inetutils-syslogd install-info libasound2 libasound2-plugin-equal \
		libgcrypt20 libgsm1 libopus0 libpopt0 libsigc++-2.0-0v5 libsox-fmt-mp3 libxml2 libxml2-dev \
		libxslt1-dev logrotate network-manager ntp python3-configobj python-cheetah python3-dev python-imaging \
		python3-pip python3-usb python3-serial python3-serial resolvconf screen sox sqlite3 \
		sudo tcl8.6 time tk8.6 usbutils uuid vim vorbis-tools watchdog wvdial
}

################################################################################

function install_orp_from_github {
	echo "GitHub install code goes here"
}

################################################################################

function install_orp_from_package {
	echo "Package install code goes here"
}

################################################################################

# Messages

function message_start {
	echo ""
	echo "--------------------------------------------------------------"
	echo " WELCOME TO OPENREPEATER"
	echo "--------------------------------------------------------------"
	echo " This script is not meant for LAMP installs."
	echo " (LAMP = Linux Apache Mysql PHP)"
	echo "--------------------------------------------------------------"
	echo " THIS SCRIPT IS NOT INTENDED TO BE RUN MORE THAN ONCE"
	echo "--------------------------------------------------------------"
	echo " This script is meant to be run on a fresh install of"
	echo " Debian $REQUIRED_OS_VER ($REQUIRED_OS_NAME)"
	echo "--------------------------------------------------------------"
}

function message_end {
	echo "------------------------------------------------------------------------------------------"
	echo " The OpenRepeater install is now complete and your system is ready for use."
	echo " Please go to https://$ip_address in your browser and configure your OpenRepeater setup."
	echo ""
	echo " NOTE: You may receive a security warning from your web browser. This is normal as the"
	echo "       SSL certificate is self-signed."
	echo "------------------------------------------------------------------------------------------"
}

################################################################################
#
# MAIN SCRIPT
#
################################################################################

(
check_root
check_os
check_network

# message_start
# check_internet

# add_debian_repos
install_webserver
#install_orp_dependancies
# install_orp_from_github
# install_orp_from_package
# message_end

) | tee /root/install.log