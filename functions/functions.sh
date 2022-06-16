#!/bin/bash

################################################################################
# DEFINE FUNCTIONS
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

function check_filesystem {
	PARTITION_SIZE=$(df -m | awk '$1=="/dev/root"{print$2}')
	
	if [ $PARTITION_SIZE -ge $MIN_PARTITION_SIZE ]; then
		# Partition is large enough
		echo "--------------------------------------------------------------"
		echo " Partition Size Looks Good...Continuing!"
		echo "--------------------------------------------------------------"
	else
		# Partition is too small. Show Message
		menu_expand_file_system $MIN_DISK_SIZE
	fi
}

################################################################################

function check_network {
	# Get Eth0 IP for later display
	IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1);
}

################################################################################

function wait_for_network {
	echo "--------------------------------------------------------------"
	echo " Waiting for network/internet connection"
	echo "--------------------------------------------------------------"
	
	# Verify network is still up for building over wifi
	echo "Verifying network/internet is still available, please wait..."
	while !(wget -q --spider http://google.com >> /dev/null); do
		echo "Network is down.  Waiting 5 seconds for the network to reconnect..."
		sleep 5s
	done
	echo "Network connected.  Proceeding..."
}

################################################################################

function set_hostname () {
	### SET HOSTNAME ###
	echo "--------------------------------------------------------------"
	echo " Setting Hostname to $1"
	echo "--------------------------------------------------------------"

	sudo hostnamectl set-hostname "$1"
}

################################################################################

function enable_i2c {
	echo "--------------------------------------------------------------"
	echo " Enable I2C bus and I2C Devices"
	echo "--------------------------------------------------------------"

	apt-get install --assume-yes --fix-missing i2c-tools

	sed -i /boot/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
	echo "i2c-dev" >> /etc/modules
}
################################################################################

function config_ics_controllers {
	echo "--------------------------------------------------------------"
	echo " Enable ICS Controller intergrations"
	echo "--------------------------------------------------------------"

	cat >> /boot/config.txt <<- DELIM
		#Enable FE-Pi Overlay
		dtoverlay=fe-pi-audio
		dtoverlay=i2s-mmap

		#Enable mcp23s17 Overlay
		dtoverlay=mcp23017,addr=0x20,gpiopin=12
		
		#Enable mcp3208 adc overlay
		dtoverlay=mcp3202:spi0-0-present,spi0-0-speed=3600000

		# Enable UART for serial console
		enable_uart=1
		DELIM
}

################################################################################

function install_webserver {
    echo "--------------------------------------------------------------"
    echo " Installing NGINX and PHP"
    echo "--------------------------------------------------------------"
    apt-get install --assume-yes --fix-missing nginx-extras;
    apt-get install --assume-yes --fix-missing nginx memcached ssl-cert \
        php7.4-common php7.4-fpm php7.4-curl php7.4-dev php7.4-gd php-imagick \
        php-memcached php7.4-pspell php7.4-snmp php7.4-sqlite3 php7.4-xmlrpc \
        php7.4-xml php-pear php-ssh2 php7.4-cli php7.4-zip
    
    apt-get clean
    
    echo "--------------------------------------------------------------"
    echo " Backup original config files"
    echo "--------------------------------------------------------------"
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    cp /etc/php/7.4/fpm/php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf.orig
    cp /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.orig
    cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf.orig
	
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
		extensions=memcached.so 
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
		      fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
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
	# Create Temp Folder UI. Will later be replaced.
	mkdir "$WWW_PATH/$GUI_NAME"
	echo "Future home of ORP" > $WWW_PATH/$GUI_NAME/index.php

	# Change permissions
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

	apt-get install --assume-yes --fix-missing alsa-base alsa-utils bzip2 cron dialog fail2ban flite gawk \
		git-core gpsd gpsd-clients i2c-tools inetutils-syslogd install-info libasound2 libasound2-plugin-equal \
		libgcrypt20 libgsm1 libopus0 libpopt0 libsigc++-2.0-0v5 libsox-fmt-mp3 libxml2 libxml2-dev \
		libxslt1-dev logrotate ntp python3-configobj python3-cheetah python3-dev python3-pip python3-usb \
        python3-serial resolvconf screen sox sqlite3 sudo tcl8.6 time tk8.6 usbutils uuid vim vorbis-tools \
        watchdog wvdial shellinabox libhamlib-utils
        
	# w3rcr -> network-manager package was removed as it caused instability 
	# particularly with wifi networks. This is a packaged geared towards laptop
        # users who constant change their connection
	# This fixes issues:
	#   https://github.com/OpenRepeater/scripts/issues/20
	#   https://github.com/OpenRepeater/scripts/issues/21
	#
	# If this is needed down the road prior to the installation put entry in
	# config file in /etc/NetworkManager/conf.d.
	# [device]
	# wifi.scan-rand-mac-address=no
	# ethernet.scan-rand-mac-address=no
}

################################################################################

function install_orp_from_github {
	echo "--------------------------------------------------------------"
	echo " Installing OpenRepeater files from GitHub repo (Clone)"
	echo "--------------------------------------------------------------"

	rm -rf $WWW_PATH/$GUI_NAME/*
	cd $WWW_PATH
	git clone -b 2.2.x --single-branch https://github.com/OpenRepeater/openrepeater.git $WWW_PATH/$GUI_NAME

	if [ $ORP_FILE_LOCATIONS = "dev" ]; then
		#######################################################################
		# DEVELOPER SETUP: LINK FILES INTO PLACE FOR GITHUB SYNC
		#######################################################################

		# DEV LINKING: Database
		mkdir -p "/var/lib/openrepeater/db"
		ln -sf "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"
		mkdir -p "/etc/openrepeater"
	
		# DEV LINKING: ORP Sounds (Courtesy Tones / Sample IDs)
		ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "$WWW_PATH/$GUI_NAME/sounds"
		ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "/var/lib/openrepeater/sounds"
	
		# DEV LINKING: ORP Helper Bash Script
		ln -s "$WWW_PATH/$GUI_NAME/install/scripts/orp_helper" "/usr/sbin/orp_helper"
		
		# DEV LINKING: Link ORP into SVXLink directories
		ln -s "/etc/svxlink" "/etc/openrepeater/svxlink"
		mkdir -p "/etc/openrepeater/svxlink/local-events.d"	
	
		#Link ORP to SVXLink log
		ln -s "/var/log/svxlink" "/var/www/openrepeater/log"
	
		# DEV LINKING: Dev Test Folder
		ln -s "$WWW_PATH/$GUI_NAME/install/dev" "$WWW_PATH/$GUI_NAME/dev"


	else
		#######################################################################
		# NORMAL SETUP: PLACE FILES WHERE THEY SHOULD BE 
		#######################################################################

		# MOVE: Database
		mkdir -p "/var/lib/openrepeater/db"
		mv "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"
		mkdir -p "/etc/openrepeater"
		
		# MOVE: ORP Sounds (Courtesy Tones / Sample IDs)
		mv "$WWW_PATH/$GUI_NAME/install/sounds" "/var/lib/openrepeater/sounds"
		ln -s "/var/lib/openrepeater/sounds" "$WWW_PATH/$GUI_NAME/sounds"
		
		# MOVE: ORP Helper Bash Script
		mv "$WWW_PATH/$GUI_NAME/install/scripts/orp_helper" "/usr/sbin/orp_helper"
		
		# LINKING: Link ORP into SVXLink directories
		ln -s "/etc/svxlink" "/etc/openrepeater/svxlink"
		mkdir -p "/etc/openrepeater/svxlink/local-events.d"	
		
		# LINKING: Link ORP to SVXLink log
		ln -s "/var/log/svxlink" "/var/www/openrepeater/log"
		
		# REMOVE: Cleanup install folders/files
		rm -R "$WWW_PATH/$GUI_NAME/debian"
		rm -R "$WWW_PATH/$GUI_NAME/install"
		rm "$WWW_PATH/$GUI_NAME/README.md"
		rm /var/www/openrepeater/dev
		rm -R /var/www/openrepeater/.git*

	fi


	# FIX PERMISSIONS/OWNERSHIP
	chown www-data:www-data "$WWW_PATH/$GUI_NAME" -R

	chown www-data:www-data "/etc/openrepeater" -R
	chown www-data:www-data "/etc/svxlink" -R
	chown www-data:www-data "/usr/share/svxlink/events.d/" -R
	chown www-data:www-data "/usr/share/svxlink/modules.d/" -R
	chown www-data:www-data "/usr/share/svxlink/sounds/" -R

	chown www-data:www-data "/var/lib/openrepeater/" -R
	chmod 777 "/var/lib/openrepeater/" -R

	# Reset database...just in case it contains callsign info.
	sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE settings SET value='' WHERE keyID='callSign'"
	sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE modules SET moduleEnabled='0', moduleOptions='' WHERE svxlinkName='EchoLink'"

}

################################################################################

function add_orp_user {
	echo "--------------------------------------------------------------"
	echo " Adding OpenRepeater User (orp)"
	echo "--------------------------------------------------------------"
	useradd -m -G sudo -c "OpenRepeater" orp
	usermod --password $(openssl passwd -1 OpenRepeater) orp
}

function modify_sudoers {
	echo "--------------------------------------------------------------"
	echo " Setting up sudoers permissions for OpenRepeater"
	echo "--------------------------------------------------------------"
	cat >> "/etc/sudoers" <<- DELIM
		# OPENREPEATER: allow www-data to access orp_helper
		www-data   ALL=(ALL) NOPASSWD: /usr/sbin/orp_helper
		DELIM
}

################################################################################

function update_versioning {
	echo "--------------------------------------------------------------"
	echo " Setting ORP Build Version"
	echo "--------------------------------------------------------------"

	# Update version in database
	sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE version_info SET version_num='$ORP_VERSION'"
}

################################################################################
