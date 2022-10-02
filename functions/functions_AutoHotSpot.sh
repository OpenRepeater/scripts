#!/bin/bash
################################################################################
# DEFINE AutoHotSpot_Autosetup FUNCTIONS
################################################################################

function AutoHotSpot_Autosetup () {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then

        #################################################    
        echo "------------------------------------------"
        echo " Install OpenRepeater HotSpot & Configure "
        echo "------------------------------------------"
        #################################################

        ########################################
        echo "---------------------------------"
        echo " Edit autohotspot-setup.sh to get"
        echo " correct Wifi Regional Domain "
        echo "---------------------------------"
        ########################################

        sed -i "$wrk_dir"/AutoHotSpot/Autohotspot/autohotspot-setup.sh -e"s/wpa=($(cat "/etc/wpa_supplicant/wpa_supplicant.conf" | grep "country="))/wpa=($(cat "/etc/default/crda" | grep "REGDOMAIN="))/g"  

		echo "complete"

        #################################
        echo "--------------------------"
        echo " Copy files to destination"
        echo "--------------------------"
        #################################

        chmod +x "$wrk_dir"/AutoHotSpot/Autohotspot/autohotspot-setup.sh
        mkdir /usr/share/Autohotspot
        mv "$wrk_dir"/AutoHotSpot/* /usr/share/Autohotspot

        echo "complete"

        ####################################
    	echo "-----------------------------"  
        echo " Install Hotspot dependencies"
        echo "-----------------------------" 
        ####################################

        apt-get install --assume-yes --fix-missing expect dnsmasq hostapd

        echo "complete"

        #############################
        echo "----------------------"      
        echo " Create/Enable hotspot"
        echo "----------------------"
        #############################
        
        /usr/share/Autohotspot/Autohotspot/autohotspot-setup.sh -a
        
        echo "complete"
        
    fi
}
