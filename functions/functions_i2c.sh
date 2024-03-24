#!/bin/bash
################################################################################
# DEFINE ENABLE I2C FUNCTIONS
################################################################################

function enable_i2c {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
    
		######################################
        echo "-------------------------------"
        echo " Enable I2C bus and I2C Devices"
        echo "-------------------------------"
        ######################################
        
		##########################
        echo "-------------------"
        echo " Install i2c tools "
        echo "-------------------"
        ##########################
        
        apt install --assume-yes --fix-missing i2c-tools

		echo "Complete"   
   
        ###########################
        echo "--------------------"
        echo " Enable i2c overlay "
        echo "--------------------"
        ###########################

        sed -i $RPI_config_text_path -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"

		echo "Complete"

		###########################
        echo "--------------------"
        echo " Enable i2c overlay "
        echo "--------------------"
        ###########################

        cat >> /etc/modules <<- DELIM
			##############################
			# Enable i2c-dev kernel module
			##############################
			i2c-dev
			DELIM

		echo "Complete"
	fi
}
