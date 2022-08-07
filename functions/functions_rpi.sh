#!/bin/bash

################################################################################
#
# DEFINE RPI SPECIFIC FUNCTIONS
#
################################################################################

function rpi_disables {
	echo "--------------------------------------------------------------"
	echo " Disable onboard HDMI sound card not used in OpenRepeater"
	echo "--------------------------------------------------------------"
	#/boot/config.txt
	sed -i /boot/config.txt -e"s#dtparam=audio=on#\#dtparam=audio=on#"
    sed -i /boot/config.txt -e"s#dtoverlay=vc4-kms-v3d#\#dtoverlay=vc4-kms-v3d#" 
    sed -i /boot/config.txt -e"s#max_framebuffers=2#\#max_framebuffers=2#"

    echo "--------------------------------------------------------------"
    echo " Disable onboard Display/Camera Ports not used in OpenRepeater"
    echo "--------------------------------------------------------------"
    sed -i /boot/config.txt -e"s#camera_auto_detect=1#\#camera_auto_detect=1#"
    sed -i /boot/config.txt -e"s#display_auto_detect=1#\#display_auto_detect=1#"
    sed -i /boot/config.txt -e"s#disable_overscan=1#\#disable_overscan=1#"
    
    echo "--------------------------------------------------------------"
    echo " Disable Onboard BlueTooth not used in OpenRepeater "
    echo "--------------------------------------------------------------"
    
    ech0 "dtoverlay=disable-bt" >> /boot/config.txt

    #echo "--------------------------------------------------------------"
    #echo " Disable onboard Broadcom sound card not used in OpenRepeater"
    #echo "--------------------------------------------------------------"
	#sed -i /etc/modules -e"s#snd-bcm2835#\#snd-bcm2835#"

}

################################################################################
