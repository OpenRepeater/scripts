#!/bin/bash
################################################################################
# DEFINE CLEANUP FUNCTIONS
################################################################################

function build_cleanup {

	#############################
	echo "----------------------"
	echo " Post Install Cleanup "
	echo "----------------------"
	#############################
	
	apt clean && apt autoclean
	
	echo "complete"
	
	#########################
	echo "------------------"
	echo " Stopping SVXLink "
	echo "------------------"
	#########################

	systemctl stop svxlink

	echo "complete"

	###################################
	echo "----------------------------"
	echo " Reset/Clearing SVXLink logs"
	echo "----------------------------"
	###################################

	echo "" > /etc/svxlink/svxlink.conf
	echo "" > /etc/svxlink/svxlink.d/ModuleEchoLink.conf
	echo "" > /var/log/svxlink
	
	echo "complete"
	
	###############################################
	echo "----------------------------------------"
	echo " Remove Debian dir from openrepeater dir"
	echo "----------------------------------------"
	###############################################
	
	rm -rf /var/www/openrepeater/debian
	
	echo "complete"
	
	######################
	echo "---------------"
	echo "Enable neofetch"
	echo "---------------"
	######################
	
	cat >> /etc/bash.bashrc <<- DELIM
		#######################################
		# Enable neofetch System info Reporting
		#######################################
		neofetch
		DELIM
		
	echo "complete"
}
