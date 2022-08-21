#!/bin/bash

################################################################################
# DEFINE RPI SPECIFIC FUNCTIONS
################################################################################
function rpi_disables {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
    	echo "--------------------------------------------------------------"
        echo " Disable onboard HDMI sound card not used in OpenRepeater"
        echo "--------------------------------------------------------------"
        sed -i /boot/config.txt -e"s#dtoverlay=vc4-kms-v3d#\#dtoverlay=vc4-kms-v3d#"         
        echo "--------------------------------------------------------------"
        echo " Disable onboard audio not used in OpenRepeater"
        echo "--------------------------------------------------------------"
        sed -i /boot/config.txt -e"s#dtparam=audio=on#\#dtparam=audio=on#"
        echo "--------------------------------------------------------------"
        echo " Disable max_framebuffer not used in OpenRepeater"
        echo "--------------------------------------------------------------" 
        sed -i /boot/config.txt -e"s#max_framebuffers=2#\#max_framebuffers=2#"
        echo "--------------------------------------------------------------"
        echo " Disable CSI Camera port onboard not used in OpenRepeater"
        echo "--------------------------------------------------------------"        
        sed -i /boot/config.txt -e"s#camera_auto_detect=1#\#camera_auto_detect=1#"
		echo "--------------------------------------------------------------"
        echo " Disable DSI display used in OpenRepeater"
        echo "--------------------------------------------------------------"       
        sed -i /boot/config.txt -e"s#display_auto_detect=1#\#display_auto_detect=1#"
        echo "--------------------------------------------------------------"
        echo " Disable video overscan not used in OpenRepeater"
        echo "--------------------------------------------------------------"
        sed -i /boot/config.txt -e"s#disable_overscan=1#\#disable_overscan=1#"
        echo "--------------------------------------------------------------"
        echo " Disable BlueTooth not used in OpenRepeater"
        echo "--------------------------------------------------------------"        
        cat >> /boot/config.txt <<- DELIM
			#####################################################################
			# Disable Onboard BlueTooth not used in OpenRepeater "
			#####################################################################
			dtoverlay=disable-bt    
			DELIM
    fi   
}

