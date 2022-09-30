#!/bin/bash
################################################################################
# DEFINE FUNCTIONS
################################################################################
function AutoHotSpot_Autosetup () {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
        echo "---------------------------------"
        echo " Install ORP_HotSpot & Configure "
        echo "---------------------------------"
        ##############################
        # sed setup script
        ##############################
        sed -i "$wrk_dir"/AutoHotSpot/Autohotspot/autohotspot-setup.sh -e's/=($(cat "/etc/wpa_supplicant/wpa_supplicant.conf" | grep "country="))/=($(cat "/etc/default/crda" | grep "REGDOMAIN="))/g'  
        ##############################
        #Copy the files to the final location
        ##############################
        echo "---------------------------------"
        echo " Copy files to destination"
        echo "---------------------------------"
        ##############################
        chmod +x "$wrk_dir"/AutoHotSpot/Autohotspot/autohotspot-setup.sh
        mkdir /usr/share/Autohotspot
        mv "$wrk_dir"/AutoHotSpot/* /usr/share/Autohotspot
        ##############################
        # Install dependencies
        ##############################
    	echo "------------------------"  
        echo " Install Hotspot dependencies"
        echo "------------------------" 
        ##############################
        apt-get install --assume-yes --fix-missing expect dnsmasq hostapd
        ##############################
        # Create HotSpot
        ############################## 
        echo "-----------------------"      
        echo " Create ORP hotspot"
        echo "-----------------------"	
        /usr/share/Autohotspot/Autohotspot/autohotspot-setup.sh -a
    fi
}
