#!/bin/bash
################################################################################
#
# DEFINE VARIABLES (Scroll down for main script)
#
################################################################################

REQUIRED_OS_VER="9"
REQUIRED_OS_NAME="Stretch"

# Upload size limit for php
UPLOAD_SIZE="25M"

WWW_PATH="/var/www"
GUI_NAME="openrepeater"

# PHP ini config file
PHP_INI="/etc/php/7.0/fpm/php.ini"

#SVXLink
SVXLINK_SOUNDS_DIR="/usr/share/svxlink/sounds"


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

function install_svxlink_sounds {
	echo "--------------------------------------------------------------"
	echo " Installing ORP Version of SVXLink Sounds (US English)"
	echo "--------------------------------------------------------------"

	cd /root
 	wget https://github.com/OpenRepeater/orp-sounds/archive/2.0.0.zip
	unzip 2.0.0.zip
	mkdir -p $SVXLINK_SOUNDS_DIR
	mv orp-sounds-2.0.0/en_US $SVXLINK_SOUNDS_DIR
	rm -R orp-sounds-2.0.0
	rm 2.0.0.zip
}

################################################################################

function config_fe_pi_audio_chip {
	echo "--------------------------------------------------------------"
	echo " Enable the Fe-Pi Audio Code Chip"
	echo "--------------------------------------------------------------"

# 	{echo "dtoverlay=fe-pi-audio"; echo "dtoverlay=i2s-mmap"} /boot/config.txt
	cat >> /boot/config.txt <<- DELIM
		#Enable FE-Pi Overlay
		dtoverlay=fe-pi-audio
		dtoverlay=i2s-mmap
		DELIM
	
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
	echo " Installing self signed SSL certificate"
	echo "--------------------------------------------------------------"
	cp -r /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
	cp -r /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt
	
	echo "--------------------------------------------------------------"
	echo " Changing file upload size from 2M to $UPLOAD_SIZE"
	echo "--------------------------------------------------------------"
	sed -i "$PHP_INI" -e "s#upload_max_filesize = 2M#upload_max_filesize = $UPLOAD_SIZE#"
	
	# Changing post_max_size limit from 8M to UPLOAD_SIZE
	sed -i "$PHP_INI" -e "s#post_max_size = 8M#post_max_size = $UPLOAD_SIZE#"
	
	echo "--------------------------------------------------------------"
	echo " Enabling memcache in php.ini"
	echo "--------------------------------------------------------------"
	cat >> "$PHP_INI" <<- DELIM 
		extensions=memcache.so 
		DELIM
	
	echo "--------------------------------------------------------------"
	echo " Setup NGINX Site Config File for OpenRepeater UI"
	echo "--------------------------------------------------------------"

	rm -rf /etc/nginx/sites-enabled/default
	ln -sf /etc/nginx/sites-available/"$GUI_NAME" /etc/nginx/sites-enabled/"$GUI_NAME"
	
	# Nginx Config File
	cat > /etc/nginx/sites-available/$GUI_NAME  <<- 'DELIM'
		server {
		   listen  80;
		   listen [::]:80 default_server ipv6only=on;
		   if ($ssl_protocol = "") {
		      rewrite     ^   https://$server_addr$request_uri? permanent;
		   }
		}
		
		server {
		   listen 443;
		   listen [::]:443 default_server ipv6only=on;
		   
		   include snippets/snakeoil.conf;
		   ssl  on;
		   
		   root /var/www/openrepeater;
		   index index.php;
		   
		   error_page 404 /404.php;
		   
		   client_max_body_size 25M;
		   client_body_buffer_size 128k;
		   
		   access_log /var/log/nginx/access.log;
		   error_log /var/log/nginx/error.log;
		   
		   location ~ \.php$ {
		      include snippets/fastcgi-php.conf;
		      include fastcgi_params;
		      fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
		      fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/$fastcgi_script_name;
		      error_page  404   404.php;
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


	echo "--------------------------------------------------------------"
	echo " Make sure WWW dir is owned by web server"
	echo "--------------------------------------------------------------"
	chown -R www-data:www-data "$WWW_PATH/$GUI_NAME"
	
	echo "--------------------------------------------------------------"
	echo " Restarting NGINX and PHP"
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
	echo "--------------------------------------------------------------"
	echo " Installing OpenRepeater files from GitHub repo (Clone)"
	echo "--------------------------------------------------------------"

# 	rm -rf $WWW_PATH/$GUI_NAME/* #Clear out folder
	cd $WWW_PATH/$GUI_NAME
# 	git clone https://github.com/OpenRepeater/openrepeater.git $WWW_PATH/$GUI_NAME
#	git checkout -b ionosphere

	#DEV LINKING: Database
# 	mkdir -p "/var/lib/openrepeater/db"
# 	ln -sf "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"
# 	mkdir -p "/etc/openrepeater"
# 	ln -sf "$WWW_PATH/$GUI_NAME/install/sql/database.php" "/etc/openrepeater/database.php"

#	ln -s "$WWW_PATH/$GUI_NAME/install/dev" "$WWW_PATH/$GUI_NAME/dev"
#ln -s /source /dest

	ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "$WWW_PATH/$GUI_NAME/sounds"
	ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "/var/lib/openrepeater/sounds"

	ln -s "$WWW_PATH/$GUI_NAME/install/scripts/orp_helper" "/usr/sbin/orp_helper"
	
#sounds -> /var/lib/openrepeater/sounds

	# FIX PERMISSIONS/OWNERSHIP
	chown www-data:www-data "/var/lib/openrepeater/" -R
	chmod 777 "/var/lib/openrepeater/" -R
	chown www-data:www-data "$WWW_PATH/$GUI_NAME" -R
}

################################################################################

function install_orp_from_package {
	echo "ORP Package install code goes here"
}

################################################################################

function modify_sudoers {
	echo "--------------------------------------------------------------"
	echo " Setting up sudoers permissions for openrepeater              "
	echo "--------------------------------------------------------------"
	cat >> /etc/sudoers <<- DELIM
		# OPENREPEATER: allow www-data to access orp_helper
		www-data   ALL=(ALL) NOPASSWD: /usr/sbin/orp_helper
		DELIM
}

################################################################################

function rpi_disables {
	echo "--------------------------------------------------------------"
	echo " Disable onboard HDMI sound card not used in OpenRepeater"
	echo "--------------------------------------------------------------"
	#/boot/config.txt
	sed -i /boot/config.txt -e"s#dtparam=audio=on#\#dtparam=audio=on#"

	# Enable audio (loads snd_bcm2835)
	# dtparam=audio=on
	#/etc/modules
	sed -i /etc/modules -e"s#snd-bcm2835#\#snd-bcm2835#"
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
# install_svxlink_sounds
# config_fe_pi_audio_chip
# install_webserver
# install_orp_dependancies
install_orp_from_github
# install_orp_from_package
modify_sudoers
# rpi_disables
# message_end


# can you add this to your /boot/config.txt
# enable_uart=1
# that way we can use a uart cable for local login

) | tee /root/install.log