#!/bin/bash

# SCRIPT CONTRIBUTORS:
# Aaron Crawford (N3MBH), Richard Neese (KB3VGW), Dan Loranger (KG7PAR),
# Dana Rawding (N1OFZ)

################################################################################
# DEFINE VARIABLES (Scroll down for main script)
################################################################################
ORP_VERSION="2.0.0"

REQUIRED_OS_VER="9"
REQUIRED_OS_NAME="Stretch"

# Upload size limit for php
UPLOAD_SIZE="25M"

WWW_PATH="/var/www"
GUI_NAME="openrepeater"

# PHP ini config file
PHP_INI="/etc/php/7.0/fpm/php.ini"

#SVXLink
SVXLINK_SOUNDS_DIR="/usr/share/svxlink/sounds"

# SVXLINK VERSION - Must match versioning at https://github.com/sm0svx/svxlink/releases
SVXLINK_VER="17.12.2"


################################################################################
# PRE-INSTALL
################################################################################

# Make sure function scripts are executable.
chmod +x functions/*

# Include Main Functions File & RPI functions
source "${BASH_SOURCE%/*}/functions/menus.sh"

# Include Main Functions File & RPI functions
source "${BASH_SOURCE%/*}/functions/functions.sh"
source "${BASH_SOURCE%/*}/functions/functions_rpi.sh"

### INITIAL FUNCTIONS ####
check_root
check_os
check_network
check_internet


################################################################################
# USER INPUT
################################################################################

menu_welcome_message
menu_build_type
menu_hostname


################################################################################
# MAIN SCRIPT - Run Functions and Save to Log
################################################################################

# Run script and output to log file
(

### SET HOSTNAME ###
hostname $HOSTNAME

### SVXLINK FUNCTIONS ###
install_svxlink_source
fix_svxlink_gpio
install_svxlink_sounds
enable_i2c
config_ics_controllers

### OPEN REPEATER FUCNTIONS ###
if [ $INPUT_INSTALL_TYPE = "ORP" ]; then
	install_webserver
	install_orp_dependancies
	install_orp_from_github
	install_orp_modules
	update_versioning
	modify_sudoers
	
	### ENDING FUNCTIONS ###
	rpi_disables
fi

) | tee /root/orp_install.log


################################################################################
# POST INSTALL
################################################################################
menu_end_message