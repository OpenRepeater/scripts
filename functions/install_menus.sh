#!/bin/bash
################################################################################
# define install type / version
################################################################################
DIALOG_TITLE="OpenRepeater $ORP_VERSION Setup"

################################################################################
# FILE SYSTEM RESIZE MESSAGE
################################################################################
function menu_expand_file_system {
	MESSAGE="WE'VE ENCOUNTERED A PROBLEM: Either you forgot to expand your file system or your card/disk is not large enough. OpenRepeater requires a card/disk of at least $1 or greater.\n\nYou may run this script again one you have expanded your file system and rebooted your system.\n\nNOTE FOR RASPBERRY PI USERS: You may choose the 'raspi-config' option to expand your file system. You can find the expand file system function under the 'Advanced' menu."
	
	if (whiptail --title "$DIALOG_TITLE" --yes-button "Abort & Fix Manually" --no-button "Run Raspi-Config"  --yesno "$MESSAGE" 15 120) then
	    echo "You must now expand your file system before you can proceed."; exit;
	else
	    raspi-config;
	fi
}

################################################################################
# WELCOME MESSAGE
################################################################################
function menu_welcome_message {
	WELCOME_MESSAGE="WELCOME TO OPENREPEATER\n\nThis script is meant to be run on a fresh install of Debian ($REQUIRED_OS_VER) ($REQUIRED_OS_NAME)\n\nTHIS SCRIPT IS NOT INTENDED TO BE RUN MORE THAN ONCE"
	
	whiptail --title "$DIALOG_TITLE" --msgbox "$WELCOME_MESSAGE" 15 60
}

################################################################################
# EXPRESS BUILD MENU
################################################################################
function express_build_menu {
	OPTION=$(whiptail --title "$DIALOG_TITLE" --menu "Would you like to run the express build options?" 15 60 4 \
	"1" "EXPRESS Build (Recommended)" \
	"2" "Custom/Advanced Build"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 0 ]; then
		case "$OPTION" in
			1) INPUT_EXPRESS_INSTALL="yes";;
			2) INPUT_EXPRESS_INSTALL="no";;
		esac
	else
	    exit;
	fi
}

################################################################################
# HOSTNAME MENU
################################################################################
function menu_hostname {
	HOSTNAME=$(whiptail --title "$DIALOG_TITLE" --inputbox "Please choose a hostname. Press <ENTER> to accept default." 10 60 openrepeater 3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 1 ]; then
	    exit;
	fi
}

################################################################################
# BUILD TYPE MENU
################################################################################
function menu_build_type {
	OPTION=$(whiptail --title "$DIALOG_TITLE" --menu "Choose the type of build you wish to perform" 15 60 4 \
	"1" "Full OpenRepeater Build (Recommended)" \
	"2" "SVXLink ONLY Build (Advanced)"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 0 ]; then
		case "$OPTION" in
			1) INPUT_INSTALL_TYPE="ORP";;
			2) INPUT_INSTALL_TYPE="SVXLink";;
		esac
	else
	    exit;
	fi
}

################################################################################
# HOW TO INSTALL ORP UI FILES
################################################################################
function menu_orp_file_loc {
	OPTION=$(whiptail --title "$DIALOG_TITLE" --menu "Choose where you would like the ORP UI files placed? A 'Proper Install' will place files where they should be within the file system. This must be used for builds intended to be distributed as IMGs. For developers, there is the option to keep all files within the cloned repo and create symlinks back to this location. This is useful for developers who wish to sync changes from the main GitHub repo." 18 70 4 \
	"1" "Proper Install (Recommended)" \
	"2" "Developer Install (Advanced)"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 0 ]; then
		case "$OPTION" in
			1) ORP_FILE_LOCATIONS="normal";;
			2) ORP_FILE_LOCATIONS="dev";;
		esac
	else
	    exit;
	fi
}

################################################################################
# INCLUDE USER CONTRIBUTED MODULES MESSAGE
################################################################################
function menu_contrib_modules {
	OPTION=$(whiptail --title "$DIALOG_TITLE" --menu "Choose to include optional user contributed modules. These may require you to use the trunk option of svxlink." 15 60 4 \
	"1" "Don't Use Contrib Modules (Stable)" \
	"2" "Use Contrib Modules (dev)"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 0 ]; then
		case "$OPTION" in
			1) INPUT_SVXLINK_CONTRIBS="DONT_USE_CONTRIBS";;
			2) INPUT_SVXLINK_CONTRIBS="USE_CONTRIBS";;
		esac
	else
	    exit;
	fi
}

################################################################################
# BUILD FROM TRUNK MESSAGE
################################################################################
function menu_svxlink_build_type {
	
	OPTION=$(whiptail --title "$DIALOG_TITLE" --menu "Choose the type of SVXLink build you wish to perform" 15 60 4 \
	"1" "Latest Release (Stable)" \
	"2" "Trunk (dev)"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ "$exitstatus" = 0 ]; then
		case "$OPTION" in
			1) INPUT_SVXLINK_INSTALL_TYPE="svx_released";;
			2) INPUT_SVXLINK_INSTALL_TYPE="svx_trunk";;
		esac
	else
	    exit;
	fi
}

################################################################################
# END MESSAGE
################################################################################
function menu_end_message {
	END_MESSAGE="The OpenRepeater Installation is now complete and your system is ready for use. Please go to https://$IP_ADDRESS in your browser and configure your OpenRepeater setup.\n\nNOTE: You may receive a security warning from your web browser. This is normal as the SSL certificate is self-signed.\n\nDON'T FORGET TO REBOOT FIRST!!!\n\n$1"
	
	if (whiptail --title "$DIALOG_TITLE" --yes-button "REBOOT NOW" --no-button "Cancel"  --yesno "$END_MESSAGE" 18 60) then
	    echo "REBOOTING NOW"; reboot;
	else
	    echo "Don't forget to reboot..."; exit;
	fi
}
