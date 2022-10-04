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

        #################################
        echo "--------------------------"
        echo " Copy files to destination"
        echo "--------------------------"
        #################################

        chmod +x "$wrk_dir"/AutoHotSpot/Autohotspot/autohotspot-setup.sh
        mkdir /usr/share/Autohotspot
        mv "$wrk_dir"/AutoHotSpot/* /usr/share/Autohotspot

        echo "Completed"

        ####################################
    	echo "-----------------------------"  
        echo " Install Hotspot dependencies"
        echo "-----------------------------" 
        ####################################

        apt-get install --assume-yes --fix-missing expect dnsmasq hostapd

        echo "Completed"

        #############################
        echo "----------------------"      
        echo " Create/Enable hotspot"
        echo "----------------------"
        #############################
        
        /usr/share/Autohotspot/Autohotspot/autohotspot-setup.sh -a
        
        echo "Completed"
        
    fi
}
