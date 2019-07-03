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

	# Enable audio (loads snd_bcm2835)
	# dtparam=audio=on
	# /etc/modules
	sed -i /etc/modules -e"s#snd-bcm2835#\#snd-bcm2835#"

	# echo "--------------------------------------------------------------"
	# echo " Disable PI user for security"
	# echo "--------------------------------------------------------------"
	# passwd --lock pi
}

################################################################################
