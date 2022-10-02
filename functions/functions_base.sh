#!/bin/bash
################################################################################
# DEFINE CORE FUNCTIONS
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

function check_os {
	# Detects ARM processor
	if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
		PROCESSOR="ARM"
    elif [ "$system_arch" == "amd64" ] || [ "$system_arch" == "X86_64" ] || [ "$system_arch" == "X86_32" ]; then
        PROCESSOR="INTEL"
	elif [ "$system_arch" == "riscv64" ]; then
		PROCESSOR="RISCV64"
    else
        PROCESSOR=UNSUPPORTED
	fi
    #####################################################################	
	# Detects Debian Version
    #####################################################################    
	if (grep -q "$REQUIRED_OS_VER." /etc/debian_version) ; then
		DEBIAN_VERSION="$REQUIRED_OS_VER"
	else
		DEBIAN_VERSION="UNSUPPORTED"
	fi
    #####################################################################
    # Abort if there is a mismatch
    #####################################################################
    if [ "$PROCESSOR" != "ARM" ] && [ "$PROCESSOR" != "INTEL" ] && [ "$PROCESSOR" != "RISCV64" ] || [ "$DEBIAN_VERSION" != "$REQUIRED_OS_VER" ] ; then
		echo
		echo "**** ERROR ****"
		echo "This script will only work on Debian ($REQUIRED_OS_VER) ($REQUIRED_OS_NAME) images at this time."
		echo "No other version of Debian is supported at this time. "
		echo "**** EXITING ****"
		exit 1
	fi
	echo "complete"
}

function check_filesystem {
if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ] || [ "$system_arch" == "riscv64" ]; then
    PARTITION_SIZE=$(df -m | awk '$1=="/dev/root"{print$2}')
    if [ $PARTITION_SIZE -ge $MIN_PARTITION_SIZE ]; then
        #####################################################################
        # Partition is large enough
        #####################################################################
        echo "--------------------------------------------------------------"
        echo " Partition Size Looks Good...Continuing!"
        echo "--------------------------------------------------------------"
    else
        #####################################################################
        # Partition is too small. Show Message
        #####################################################################
        menu_expand_file_system "$MIN_DISK_SIZE"
    fi
fi
}

function retrieve_system_ip {
    #####################################################################
	# Get System IP WLAN / ETH0 for later display
    #####################################################################
    #check ip wlan0/eth0 other boards that have onboard eth0 and wlan0
    IP_ADDRESS_ETH0="$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)";
    IP_ADDRESS_WLAN0="$(ip addr show wlan0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)";
}

function wait_for_network {
	echo "--------------------------------------------------------------"
	echo " Waiting for network/internet connection"
	echo "--------------------------------------------------------------"
    #####################################################################
	# Verify network is still up for building over wifi
    #####################################################################
	echo "Verifying network/internet is still available, please wait..."
	while ! (wget -q --spider http://google.com >> /dev/null); do
		echo "Network is down.  Waiting 5 seconds for the network to reconnect..."
		sleep 5s
	done
	echo "Network connected.  Proceeding..."
}

function set_hostname {
    #####################################################################
    ### SET HOSTNAME 
    #####################################################################
	echo "--------------------------------------------------------------"
	echo " Setting Hostname to $1"
	echo "--------------------------------------------------------------"
	sudo hostnamectl set-hostname "$1"
	echo "complete"
}

function set_wifi_domain {
    #####################################################################
    ### SET WIFI Regional Domain 
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Adding Wifi Regional Domain "
    echo "--------------------------------------------------------------"
	sed -i /etc/default/crda -e"s/=/=$WIFI_DOMAIN/g"
	iw reg set $WIFI_DOMAIN
	raspi-config nonint do_wifi_country $WIFI_DOMAIN
	echo "complete"
}

function config_locale {
    #####################################################################
    ### SET system locale 
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Setting proper locale "
    echo "--------------------------------------------------------------"
	dpkg-reconfigure locales
	echo "complete"
}

function post_system_ip {
    #####################################################################
	# Post System IP WLAN / ETH0 
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Current Network IP'S "
    echo "--------------------------------------------------------------"    
    echo eth0=$IP_ADDRESS_ETH0 $IP wlan0=$IP_ADDRESS_WLAN0
    echo "complete"
}