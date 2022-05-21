#!/bin/bash

# SCRIPT CONTRIBUTORS:
# Aaron Crawford (N3MBH), Richard Neese (KB3VGW), Dan Loranger (KG7PAR),
# Dana Rawding (N1OFZ), John Tetreault (KC1KVT), Bob Ruddy (W3RCR)

################################################################################
# DEFINE VARIABLES (Scroll down for main script)
################################################################################
ORP_VERSION="3.0.0 (dev)"

REQUIRED_OS_VER="11.x"
REQUIRED_OS_NAME="Bullseye"

# File System Requirements
MIN_PARTITION_SIZE="3000"
MIN_DISK_SIZE="4GB"

# Upload size limit for php
UPLOAD_SIZE="25M"

WWW_PATH="/var/www"
GUI_NAME="openrepeater"

# PHP ini config file
PHP_INI="/etc/php/7.4/fpm/php.ini"

#SVXLink
SVXLINK_SOUNDS_DIR="/usr/share/svxlink/sounds"

# SVXLINK VERSION - Must match versioning at https://github.com/sm0svx/svxlink/releases
SVXLINK_VER="19.09.2"
ORP_RMT_RELAY_BRANCH="1.1" ### FOR DEPRECIATED FUNCTION

SCRIPT_DIR=$(dirname $(realpath $0))

################################################################################
# PRE-INSTALL
################################################################################

# Make sure function scripts are executable.
chmod +x functions/*

# Include Menus file
source "${BASH_SOURCE%/*}/functions/menus.sh"

# Include Main Functions File & RPI functions
source "${BASH_SOURCE%/*}/functions/functions.sh"
source "${BASH_SOURCE%/*}/functions/functions_svxlink.sh"
source "${BASH_SOURCE%/*}/functions/functions_rpi.sh"
source "${BASH_SOURCE%/*}/functions/functions_motd.sh"
source "${BASH_SOURCE%/*}/functions/functions_ics.sh"


### INITIAL FUNCTIONS ####
check_root
check_os
check_filesystem
check_network
check_internet

# Start Time
START_TIME=`date +%s`


################################################################################
# USER INPUT
################################################################################

menu_welcome_message
express_build_menu

if [ $INPUT_EXPRESS_INSTALL = "yes" ]; then
	HOSTNAME="openrepeater"
	INPUT_INSTALL_TYPE="ORP"
	INPUT_SVXLINK_CONTRIBS=""
	INPUT_SVXLINK_INSTALL_TYPE="svx_released"
	
	
else
	menu_hostname
	menu_build_type
	if [ $INPUT_INSTALL_TYPE = "ORP" ]; then
		menu_orp_file_loc
	fi
	menu_svxlink_build_type
	menu_contrib_modules
fi


################################################################################
# MAIN SCRIPT - Run Functions and Save to Log
################################################################################

# Run script and output to log file
(
	date
	
	set_hostname $HOSTNAME

	### SVXLINK FUNCTIONS ###
	install_svxlink_source $INPUT_SVXLINK_INSTALL_TYPE $INPUT_SVXLINK_CONTRIBS
	
	# fixup the RepeaterLogic so IDs work correctly
	logic_fixup '../../usr/share/svxlink/events.d/RepeaterLogic.tcl' 'proc repeater_down' '/usr/share/svxlink/events.d/RepeaterLogic.tcl'
	### allow a few seconds for the file system to catch up since we are working on the same file as before
	sleep 5s
	logic_fixup '../../usr/share/svxlink/events.d/RepeaterLogic.tcl' 'proc repeater_up' '/usr/share/svxlink/events.d/RepeaterLogic.tcl'
	
	# fixup a typo in the svxlink source that breaks the gpio service
	fix_svxlink_gpio

	# install scripts to set device permissions (hidraw/serial)
	install_device_permission_scripts
	
	# Enable ALSA zerofill for svxlink
	force_async_audio_zerfill
	
	# install copy of repo with all the synthetic voice files
	install_svxlink_sounds
	
	# cards with gpio expanders will need to have the i2c bus enabled.
	enable_i2c
	
	# Need to add some settings to the config.txt file to enable interface card
	# or they won't load up properly
	config_ics_controllers
	
	# need some asound.conf tweaks to keep the channels seperated
	set_ics_asound
	
	### OPEN REPEATER FUCNTIONS ###
	if [ $INPUT_INSTALL_TYPE = "ORP" ]; then
		install_webserver
		install_orp_dependancies
		wait_for_network
		install_orp_from_github
		update_versioning
		modify_sudoers
		
		### ENDING FUNCTIONS ###
		add_orp_user
		rpi_disables
		set_motd
	fi

	date

) 2> >(tee /root/orp_error.log) | tee /root/orp_install.log

################################################################################
# POST INSTALL
################################################################################

# End Time & Build Time
END_TIME=`date +%s`
BUILD_TIME="Build Time: $((($END_TIME-$START_TIME)/60)) minutes"

menu_end_message "$BUILD_TIME"
