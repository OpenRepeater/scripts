#!/usr/bin/bash
############################
#Sysem arch checking (New)
############################
system_arch="$(dpkg --print-architecture)"

############################
#Get rpi-board id (New)
############################
rpi_board="$(cat /proc/cpuinfo | grep -i Revision)"

############################
#set build work dir (New)
############################
wrk_dir="/usr/src/scripts"

############################
#set build log dir (New)
############################
log_dir="/usr/src"

# SCRIPT CONTRIBUTORS:
# Aaron Crawford (N3MBH), Richard Neese (N4CNR), Dan Loranger (KG7PAR),
# Dana Rawding (N1OFZ), John Tetreault (KC1KVT), Bob Ruddy (W3RCR)

################################################################################
# DEFINE VARIABLES (Scroll down for main script)
################################################################################
#Dispaled Version on Login Page
ORP_VERSION="2.2.x"

#ORP Gui Install Version (New)
ORP_GUI_VERSION="2.2.x"

#Set Debian OS Release
REQUIRED_OS_VER="11"
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

SCRIPT_DIR="$(dirname $(realpath "$0"))"

################################################################################
# PRE-INSTALL configuration
################################################################################
# Make sure function scripts are executable.
########################################################
chmod +x functions/*
########################################################
#Include ORP/SvxLink Build Menus file
########################################################
source "${BASH_SOURCE%/*}/functions/install_menus.sh"
########################################################
#Include Main Functions File & RPI functions
########################################################
source "${BASH_SOURCE%/*}/functions/functions_base.sh"
########################################################
#Install and configure SvxLink 
########################################################
source "${BASH_SOURCE%/*}/functions/functions_svxlink.sh"
########################################################
#Change the MOTD file output
########################################################
source "${BASH_SOURCE%/*}/functions/functions_motd.sh"
########################################################
#Disable un needed functions in OpenRepeater install
########################################################
source "${BASH_SOURCE%/*}/functions/functions_rpi.sh"
########################################################
#Enable ICS Cards and sound support
########################################################
source "${BASH_SOURCE%/*}/functions/functions_ics.sh"
########################################################
#Enable otg serial console zero/w/w2
########################################################
source "${BASH_SOURCE%/*}/functions/functions_otg.sh"
########################################################
#Enable UART for serial console 
########################################################
source "${BASH_SOURCE%/*}/functions/functions_uart.sh"
########################################################
#Include AutoHotSpot Functions
########################################################
source "${BASH_SOURCE%/*}/functions/functions_AutoHotSpot.sh"
########################################################
#Include X86 dummy sound driver Functions
########################################################
source "${BASH_SOURCE%/*}/functions/functions_dummysnd.sh"
########################################################
#Enable i2c on raspi
########################################################
source "${BASH_SOURCE%/*}/functions/functions_i2c.sh"
########################################################
#Install orp and deps
########################################################
source "${BASH_SOURCE%/*}/functions/functions_orp.sh"
########################################################
#Install Nginx and Php  
########################################################
source "${BASH_SOURCE%/*}/functions/functions_web.sh"

### INITIAL FUNCTIONS ####
check_root
check_os
check_filesystem
check_network
check_internet

# Start Time
START_TIME=$(date +%s)
################################################################################
# USER INPUT
################################################################################
menu_welcome_message
express_build_menu

if [ "$INPUT_EXPRESS_INSTALL" == "yes" ]; then
	HOSTNAME="openrepeater"
	INPUT_INSTALL_TYPE="ORP"
	INPUT_SVXLINK_CONTRIBS=""
	INPUT_SVXLINK_INSTALL_TYPE="svx_released"
else
	menu_hostname
	menu_build_type
	if [ "$INPUT_INSTALL_TYPE" == "ORP" ]; then
		menu_orp_file_loc
	fi
	menu_svxlink_build_type
	menu_contrib_modules
fi
################################################################################
# MAIN SCRIPT - Run Functions and Save to Log
################################################################################
(
    ########################################################
    # grab date for build date/start build time
    ########################################################
	date
    ########################################################
    # Update system hostname
    ########################################################
	set_hostname "$HOSTNAME"
	####################################################
    #add serial consile to allow access where no 
    #network avaible. Rpi zero/w/w2 (New)
    ####################################################
    otg_console        
    #################################################### 
    ########################################################
    ### SVXLINK FUNCTIONS 
    ########################################################
    install_svxlink_source "$INPUT_SVXLINK_INSTALL_TYPE" "$INPUT_SVXLINK_CONTRIBS"
    ########################################################
	# fixup the RepeaterLogic so IDs work correctly
    ########################################################
	logic_fixup '../../../usr/share/svxlink/events.d/RepeaterLogic.tcl' 'proc repeater_down' '/usr/share/svxlink/events.d/RepeaterLogic.tcl'
	### allow a few seconds for the file system to catch up since we are working on the same file as before
	sleep 5
	logic_fixup '../../../usr/share/svxlink/events.d/RepeaterLogic.tcl' 'proc repeater_up' '/usr/share/svxlink/events.d/RepeaterLogic.tcl'
    ########################################################
	# fixup a typo in the svxlink source that breaks the gpio service
    ########################################################
	fix_svxlink_gpio
    ########################################################    
	# install scripts to set device permissions (hidraw/serial)
    ########################################################
	install_device_permission_scripts
    ########################################################
	# Enable ALSA zerofill for svxlink
    ########################################################
	force_async_audio_zerfill
    ########################################################
	# install copy of repo with all the synthetic voice files
    ########################################################
	install_svxlink_sounds
    ########################################################
    # cards with gpio expanders will need to have the i2c bus enabled.
    ########################################################
    enable_i2c
    ########################################################
    # Need to add some settings to the config.txt file to enable 
    # interface card or they won't load up properly.
    ########################################################
    config_ics_controllers
    ########################################################
    # need some asound.conf tweaks to keep the channels seperated
    ########################################################
    set_ics_asound
    ####################################################
    #Enable dummy sound drive x86/amd64 (new)
    ####################################################
    dummysnd_setup        
    ####################################################
    #Enable raspi serial console uart pins
    #(moved to its own function)
    ####################################################
    enable_uart
    ########################################################
   	### OPEN REPEATER FUCNTIONS
    ########################################################
	if [ "$INPUT_INSTALL_TYPE" = "ORP" ]; then
        ####################################################
        #install Nginx and Dependencies
        ####################################################
 		install_webserver
        ####################################################
        #install Extra Dependencies
        ####################################################
		install_orp_dependancies
        ####################################################
        # wait for network to catch up
        ####################################################
		wait_for_network
        ####################################################
        #Install Gui from Github
        ####################################################
		install_orp_from_github
        ####################################################
        #Add ORP Release version to sqlite db
        ####################################################
		update_versioning
        ####################################################
        #update www-data used to sudo
        ####################################################
		modify_www-data
		####################################################
        #AutoHotSpot_Autosetup (New)
        ####################################################
        AutoHotSpot_Autosetup
		####################################################
		### ENDING FUNCTIONS ###
        ####################################################
        #Add orp user for ssh & sudo (depreciated)
        ####################################################
		#add_orp_user
        ####################################################
        #Disable functions on pi not needed by Repeater
        ####################################################
        rpi_disables      
        ####################################################
        #Change the motd file for ORP
        ####################################################
        set_motd
        ####################################################
    fi
    ####################################################
    #Cleanup
    ####################################################
	apt clean && apt autoclean
    ####################################################
    #Enable neofetch
    ####################################################	
	cat >> /etc/bash.bashrc <<- DELIM
		####################################################
		#Enable neofetch
		####################################################
		neofetch
		DELIM
    ########################################################
    #grab date for build date/finish build time
    ########################################################
    date
    #Reporting Output Log Files
) 2> >(tee "$log_dir"/orp_error.log) | tee "$log_dir"/orp_install.log
################################################################################
# POST INSTALL REPORT
################################################################################
# End Time & Build Time
################################################################################
END_TIME=$(date +%s)
BUILD_TIME="Build Time: $(((END_TIME-START_TIME)/60)) minutes"
menu_end_message "$BUILD_TIME"
