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
	
	echo "Completed"
	
	#########################
	echo "------------------"
	echo " Stopping SVXLink "
	echo "------------------"
	#########################

	systemctl stop svxlink

	echo "Completed"

	###################################
	echo "----------------------------"
	echo " Reset/Clearing SVXLink logs"
	echo "----------------------------"
	###################################

	echo "" > /etc/svxlink/svxlink.conf
	echo "" > /etc/svxlink/svxlink.d/ModuleEchoLink.conf
	echo "" > /var/log/svxlink
	
	echo "Completed"
	
	###############################################
	echo "----------------------------------------"
	echo " Remove Debian dir from openrepeater dir"
	echo "----------------------------------------"
	###############################################
	
	rm -rf /var/www/openrepeater/debian
	
	echo "Completed"
	
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
		
	echo "Completed"
}
