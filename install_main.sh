#!/bin/bash

# SCRIPT CONTRIBUTORS:
# Aaron Crawford (N3MBH), Richard Neese (KB3VGW), Dan Loranger (KG7PAR),
# Dana Rawding (N1OFZ)

################################################################################
#
# DEFINE VARIABLES (Scroll down for main script)
#
################################################################################
ORP_VERSION="ionosphere"

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
#
# MAIN SCRIPT
#
################################################################################

# NOTE: This is the main script that calls the appropriate functions from an
# external script. The plan is to add the user prompts back in, but for now 
# just the require functions for the RPI are called below. If you don't want to
# run a specific function, simply comment it out (#).

# run: /root/scripts/install_main.sh

# Make sure function scripts are executable.
chmod +x functions/*

# Include Main Functions File & RPI functions
source "${BASH_SOURCE%/*}/functions/functions.sh"
source "${BASH_SOURCE%/*}/functions/functions_rpi.sh"

# Run script and output to log file
(
check_root
check_os
check_network

message_start
# check_internet

# install_svxlink_packge
# install_svxlink_source
# install_svxlink_sounds
# enable_i2c
# config_ics_controllers
# install_webserver

# install_orp_dependancies
# install_orp_from_github
# install_orp_from_package
# install_orp_modules
# update_versioning
# modify_sudoers
# rpi_disables
# message_end

) | tee /root/orp_install.log