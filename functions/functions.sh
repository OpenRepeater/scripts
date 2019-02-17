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

# THIS PACKAGE IS OUT OF DATE. USING COMPILE FROM SOURCE INSTEAD

# function install_svxlink_packge {
# 	echo "--------------------------------------------------------------"
# 	echo " Installing SVXLink from Package"
# 	echo "--------------------------------------------------------------"
# 	
# 	# Based on: https://github.com/sm0svx/svxlink/wiki/InstallBinRaspbian
# 	echo 'deb http://mirrordirector.raspbian.org/raspbian/ buster main' | sudo tee /etc/apt/sources.list.d/svxlink.list
# 	apt-get update
# 	
# 	apt-get install svxlink-server
# 	
# 	rm /etc/apt/sources.list.d/svxlink.list
# 	
# 	# Add svxlink user to user groups
# 	usermod -a -G daemon,gpio,audio svxlink
# }

################################################################################

function install_svxlink_source () {
	echo "--------------------------------------------------------------"
	echo " Compile/Install SVXLink from Source Code (ver $SVXLINK_VER)"
	echo "--------------------------------------------------------------"
	
	# Based on: https://github.com/sm0svx/svxlink/wiki/InstallSrcDebian

	# Install required packages
 	apt-get update
	apt-get install --assume-yes --fix-missing g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev tcl8.5-dev \
		libgcrypt11-dev libspeex-dev libasound2-dev libopus-dev librtlsdr-dev doxygen \
		groff alsa-utils vorbis-tools curl git

	# Add svxlink user and add to user groups
	useradd -r svxlink
	usermod -a -G daemon,gpio,audio svxlink

	# Download and compile from source, either the trunk or latest package
	cd "/root"
	echo "svx_trunk=$1"
	if [ $1="svx_trunk" ]; then
		mkdir svxlink
		cd svxlink
		git clone https://github.com/sm0svx/svxlink.git
		cd svxlink/src

	else
		curl -Lo svxlink-source.tar.gz "https://github.com/sm0svx/svxlink/archive/$SVXLINK_VER.tar.gz"
		tar xvzf svxlink-source.tar.gz
		cd svxlink-$SVXLINK_VER/src
	fi
	
	# If Selected, enable the non-standard modules to be included in the build process
	
	echo "USE_CONTRIBS=$2"
	if [ $2="USE_CONTRIBS" ]; then
		echo "Entering config to enable optional contrib modules"
		Modules_Build_Cmake_switches=' -DWITH_CONTRIB_MODULE_REMOTE_RELAY=ON -DWITH_CONTRIB_MODULE_SITE_STATUS=ON -DWITH_CONTRIB_MODULE_TCLSSTV=ON -DWITH_CONTRIB_MODULE_TXFAN=ON '
	else
		echo "Optional contrib modules not selected"
		Modules_Build_Cmake_switches=""
	fi
	
	mkdir build
	cd build
	echo "make command: cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON -DUSE_QT=no $Modules_Build_Cmake_switches .."
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON -DUSE_QT=no $Modules_Build_Cmake_switches ..
	
	make
	make doc

	make install
	ldconfig

 	# Enable/Disable Services
	systemctl enable svxlink
	systemctl disable remotetrx

	# Clean Up
	#rm /root/svxlink-source.tar.gz
	#rm /root/svxlink-$SVXLINK_VER -R
	rm /root/svxlink* -r -f
}

################################################################################

function fix_svxlink_gpio {
	echo "--------------------------------------------------------------"
	echo " Apply Fixes to SVXLink GPIO Support until corrected"
	echo "--------------------------------------------------------------"
	
	sed -i -e 's/$GPIOPATH/$GPIO_PATH/g' /usr/sbin/svxlink_gpio_up
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
	
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/0.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_0.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/1.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_1.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/2.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_2.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/3.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_3.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/4.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_4.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/5.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_5.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/6.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_6.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/7.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_7.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/8.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_8.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/9.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_9.wav"	
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/O.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/oX.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/MetarInfo/hours.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/hours.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/MetarInfo/hour.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/hour.wav"

	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/Hz.wav" "$SVXLINK_SOUNDS_DIR/en_US/Core/hz.wav"
	
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Core/repeater.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/repeater.wav"
}

################################################################################
function wifi_hotspot {
	# functionality adapted from
	# http://www.raspberryconnect.com/network/item/330-raspberry-pi-auto-wifi-hotspot-switch-internet
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot"
	echo "--------------------------------------------------------------"
	
	apt-get install hostapd
	apt-get install dnsmasq
	systemctl disable hostapd
	systemctl disable dnsmasq
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - /etc/hostapd/hostapd.conf"
	echo "--------------------------------------------------------------"
	
	cat >> /etc/hostapd/hostapd.conf <<- DELIM
	#2.4GHz setup wifi 80211 b,g,n
	interface=wlan0
	driver=nl80211
	ssid=OpenRepeater
	hw_mode=g
	channel=8
	wmm_enabled=0
	macaddr_acl=0
	auth_algs=1
	ignore_broadcast_ssid=0
	wpa=2
	wpa_passphrase=OpenRepeaterHotSpot
	wpa_key_mgmt=WPA-PSK
	wpa_pairwise=CCMP TKIP
	rsn_pairwise=CCMP
	
	#80211n - Change US to your WiFi country code
	country_code=US
	ieee80211n=1
	ieee80211d=1
	DELIM

	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - /etc/default/hostapd"
	echo "--------------------------------------------------------------"
	
	sed -i /etc/default/hostapd -e "s#\#DAEMON_CONF=\"\"#DAEMON_CONF=/etc/hostapd/hostapd.conf#"
	sed -i /etc/default/hostapd -e "s#DAEMON_OPTS=#\#DAEMON_OPTS=#"	
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - /etc/dnsmasq.conf"
	echo "--------------------------------------------------------------"
	
	cat >> /etc/dnsmasq.cof  <<- DELIM
	#AutoHotspot config
	interface=wlan0
	bind-dynamic 
	server=8.8.8.8
	domain-needed
	bogus-priv
	dhcp-range=192.168.50.150,192.168.50.200,255.255.255.0,12h
	DELIM
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - prepare /etc/network/inferfaces"
	echo "--------------------------------------------------------------"
	#make a backup just in case, this should not be needed with a new card
	# but just to be safe.  Then clear it out so its ready to be setup
	cp /etc/network/interfaces /etc/network/interfaces-backup
	echo "" > /etc/network/interfaces
	
	cat >> /etc/network/interfaces <<- DELIM
	# interfaces(5) file used by ifup(8) and ifdown(8)
	# Please note that this file is written to be used with dhcpcd
	# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'
	# Include files from /etc/network/interfaces.d:
	source-directory /etc/network/interfaces.d
	DELIM
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - prepare /etc/sysctl.conf"
	echo " Configure Hotspot - to allow IP forwarding"
	echo "--------------------------------------------------------------"
	
	sed -i /etc/sysctl.conf -e "s#\#net.ipv4.ip_forward=1#net.ipv4.ip_forward=1#"	
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - prepare /etc/dhcpd.conf"
	echo "--------------------------------------------------------------"
	
	echo >> /etc/dhcpd.conf <<- DELIM
	nohook wpa_supplicant
	DELIM
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - Create autohotspot service"
	echo "--------------------------------------------------------------"
	
	echo "" > /etc/systemd/system/autohotspot.service
	cat >> /etc/systemd/system/autohotspot.service <<- DELIM
	[Unit]
	Description=Automatically generates an internet Hotspot when a valid ssid is not in range
	After=multi-user.target
	[Service]
	Type=oneshot
	RemainAfterExit=yes
	ExecStart=/usr/bin/autohotspotN
	[Install]
	WantedBy=multi-user.target
	DELIM

	systemctl enable autohotspot.service
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - Create autohotspot script"
	echo "--------------------------------------------------------------"
	
	echo "" > /usr/bin/autohotspotN
	cat >> /usr/bin/autohotspotN <<- DELIM
#!/bin/bash
#version 0.95-4-N/HS-I

#You may share this script on the condition a reference to RaspberryConnect.com 
#must be included in copies or derivatives of this script. 

#A script to switch between a wifi network and an Internet routed Hotspot
#A Raspberry Pi with a network port required for Internet in hotspot mode.
#Works at startup or with a seperate timer or manually without a reboot
#Other setup required find out more at
#http://www.raspberryconnect.com

wifidev="wlan0" #device name to use. Default is wlan0.
ethdev="eth0" #Ethernet port to use with IP tables
#use the command: iw dev ,to see wifi interface name 

IFSdef=$IFS
cnt=0
#These four lines capture the wifi networks the RPi is setup to use
wpassid=$(awk '/ssid="/{ print $0 }' /etc/wpa_supplicant/wpa_supplicant.conf | awk -F'ssid=' '{ print $2 }' ORS=',' | sed 's/\"/''/g' | sed 's/,$//')
IFS=","
ssids=($wpassid)
IFS=$IFSdef #reset back to defaults


#Note:If you only want to check for certain SSIDs
#Remove the # in in front of ssids=('mySSID1'.... below and put a # infront of all four lines above
# separated by a space, eg ('mySSID1' 'mySSID2')
#ssids=('mySSID1' 'mySSID2' 'mySSID3')

#Enter the Routers Mac Addresses for hidden SSIDs, seperated by spaces ie 
#( '11:22:33:44:55:66' 'aa:bb:cc:dd:ee:ff' ) 
mac=()

ssidsmac=("${ssids[@]}" "${mac[@]}") #combines ssid and MAC for checking

createAdHocNetwork()
{
    echo "Creating Hotspot"
    ip link set dev "$wifidev" down
    ip a add 192.168.50.5/24 brd + dev "$wifidev"
    ip link set dev "$wifidev" up
    dhcpcd -k "$wifidev" >/dev/null 2>&1
    iptables -t nat -A POSTROUTING -o "$ethdev" -j MASQUERADE
    iptables -A FORWARD -i "$ethdev" -o "$wifidev" -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i "$wifidev" -o "$ethdev" -j ACCEPT
    systemctl start dnsmasq
    systemctl start hostapd
    echo 1 > /proc/sys/net/ipv4/ip_forward
}

KillHotspot()
{
    echo "Shutting Down Hotspot"
    ip link set dev "$wifidev" down
    systemctl stop hostapd
    systemctl stop dnsmasq
    iptables -D FORWARD -i "$ethdev" -o "$wifidev" -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -D FORWARD -i "$wifidev" -o "$ethdev" -j ACCEPT
    echo 0 > /proc/sys/net/ipv4/ip_forward
    ip addr flush dev "$wifidev"
    ip link set dev "$wifidev" up
    dhcpcd  -n "$wifidev" >/dev/null 2>&1
}

ChkWifiUp()
{
	echo "Checking WiFi connection ok"
        sleep 20 #give time for connection to be completed to router
	if ! wpa_cli -i "$wifidev" status | grep 'ip_address' >/dev/null 2>&1
        then #Failed to connect to wifi (check your wifi settings, password etc)
	       echo 'Wifi failed to connect, falling back to Hotspot.'
               wpa_cli terminate "$wifidev" >/dev/null 2>&1
	       createAdHocNetwork
	fi
}


FindSSID()
{
#Check to see what SSID's and MAC addresses are in range
ssidChk=('NoSSid')
i=0; j=0
until [ $i -eq 1 ] #wait for wifi if busy, usb wifi is slower.
do
        ssidreply=$((iw dev "$wifidev" scan ap-force | egrep "^BSS|SSID:") 2>&1) >/dev/null 2>&1 
        echo "SSid's in range: " $ssidreply
        echo "Device Available Check try " $j
        if (($j >= 10)); then #if busy 10 times goto hotspot
                 echo "Device busy or unavailable 10 times, going to Hotspot"
                 ssidreply=""
                 i=1
	elif echo "$ssidreply" | grep "No such device (-19)" >/dev/null 2>&1; then
                echo "No Device Reported, try " $j
		NoDevice
        elif echo "$ssidreply" | grep "Network is down (-100)" >/dev/null 2>&1 ; then
                echo "Network Not available, trying again" $j
                j=$((j + 1))
                sleep 2
	elif echo "$ssidreplay" | grep "Read-only file system (-30)" >/dev/null 2>&1 ; then
		echo "Temporary Read only file system, trying again"
		j=$((j + 1))
		sleep 2
	elif ! echo "$ssidreply" | grep "resource busy (-16)"  >/dev/null 2>&1 ; then
               echo "Device Available, checking SSid Results"
		i=1
	else #see if device not busy in 2 seconds
                echo "Device unavailable checking again, try " $j
		j=$((j + 1))
		sleep 2
	fi
done

for ssid in "${ssidsmac[@]}"
do
     if (echo "$ssidreply" | grep "$ssid") >/dev/null 2>&1
     then
	      #Valid SSid found, passing to script
              echo "Valid SSID Detected, assesing Wifi status"
              ssidChk=$ssid
              return 0
      else
	      #No Network found, NoSSid issued"
              echo "No SSid found, assessing WiFi status"
              ssidChk='NoSSid'
     fi
done
}

NoDevice()
{
	#if no wifi device,ie usb wifi removed, activate wifi so when it is
	#reconnected wifi to a router will be available
	echo "No wifi device connected"
	wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
	exit 1
}

FindSSID

#Create Hotspot or connect to valid wifi networks
if [ "$ssidChk" != "NoSSid" ] 
then
       echo 0 > /proc/sys/net/ipv4/ip_forward #deactivate ip forwarding
       if systemctl status hostapd | grep "(running)" >/dev/null 2>&1
       then #hotspot running and ssid in range
              KillHotspot
              echo "Hotspot Deactivated, Bringing Wifi Up"
              wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
              ChkWifiUp
       elif { wpa_cli -i "$wifidev" status | grep 'ip_address'; } >/dev/null 2>&1
       then #Already connected
              echo "Wifi already connected to a network"
       else #ssid exists and no hotspot running connect to wifi network
              echo "Connecting to the WiFi Network"
              wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
              ChkWifiUp
       fi
else #ssid or MAC address not in range
       if systemctl status hostapd | grep "(running)" >/dev/null 2>&1
       then
              echo "Hostspot already active"
       elif { wpa_cli status | grep "$wifidev"; } >/dev/null 2>&1
       then
              echo "Cleaning wifi files and Activating Hotspot"
              wpa_cli terminate >/dev/null 2>&1
              ip addr flush "$wifidev"
              ip link set dev "$wifidev" down
              rm -r /var/run/wpa_supplicant >/dev/null 2>&1
              createAdHocNetwork
       else #"No SSID, activating Hotspot"
              createAdHocNetwork
       fi
fi

DELIM

	chmod +x /usr/bin/autohotspotN
	
	echo "--------------------------------------------------------------"
	echo " Configure Hotspot - Done"
	echo "--------------------------------------------------------------"
	
}
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
		
		#Enable mcp3008 adc overlay
		dtoverlay=mcp3008:spi0-0-present,spi0-0-speed=3600000

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
		openssl-blacklist php-common php-fpm php-common php-curl php-dev php-gd php-imagick php-mcrypt \
		php-memcache php-pspell php-snmp php-sqlite3 php-xmlrpc php-xsl php-pear php-ssh2 php-cli php-zip
	
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
		libxslt1-dev logrotate ntp python3-configobj python-cheetah python3-dev python-imaging \
		python3-pip python3-usb python3-serial python3-serial resolvconf screen sox sqlite3 \
		sudo tcl8.6 time tk8.6 usbutils uuid vim vorbis-tools watchdog wvdial

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
	git clone -b 2.1.x --single-branch https://github.com/OpenRepeater/openrepeater.git $WWW_PATH/$GUI_NAME

	if [ $ORP_FILE_LOCATIONS = "dev" ]; then
		#######################################################################
		# DEVELOPER SETUP: LINK FILES INTO PLACE FOR GITHUB SYNC
		#######################################################################

		# DEV LINKING: Database
		mkdir -p "/var/lib/openrepeater/db"
		ln -sf "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"
		mkdir -p "/etc/openrepeater"
		ln -sf "$WWW_PATH/$GUI_NAME/install/sql/database.php" "/etc/openrepeater/database.php"
	
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
		mv "$WWW_PATH/$GUI_NAME/install/sql/database.php" "/etc/openrepeater/database.php"
		
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

	chown www-data:www-data "/var/lib/openrepeater/" -R
	chmod 777 "/var/lib/openrepeater/" -R

	# Reset database...just in case it contains callsign info.
	sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE settings SET value='' WHERE keyID='callSign'"
	sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE modules SET moduleEnabled='0', moduleOptions='' WHERE moduleName='EchoLink'"

}

################################################################################

function install_orp_from_package {
	echo "ORP Package install code goes here"
}

################################################################################

### THIS FUNCTION IS BEING DEPRECIATED ###
function install_orp_modules {
	echo "--------------------------------------------------------------"
	echo " Installing OpenRepeater custom SVXLink Modules"
	echo "--------------------------------------------------------------"

	### Install ORP Remote Relay Module
	cd /root
	curl -sSLo remote_relay.zip https://github.com/OpenRepeater/MODULE_Remote_Relay/archive/${ORP_RMT_RELAY_BRANCH}.zip
	unzip remote_relay.zip
	BASE_DIR=MODULE_Remote_Relay-${ORP_RMT_RELAY_BRANCH}
	cp ${BASE_DIR}/svxlink/events.d/RemoteRelay.tcl /usr/share/svxlink/events.d/RemoteRelay.tcl
	cp ${BASE_DIR}/svxlink/modules.d/ModuleRemoteRelay.tcl /usr/share/svxlink/modules.d/ModuleRemoteRelay.tcl
	rm -R ${BASE_DIR}
	rm remote_relay.zip
}

################################################################################

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
