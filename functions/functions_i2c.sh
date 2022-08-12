#!/bin/bash
################################################################################
# DEFINE ENABLE I2C FUNCTIONS
################################################################################
function enable_i2c {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
        echo "--------------------------------------------------------------"
        echo " Enable I2C bus and I2C Devices"
        echo "--------------------------------------------------------------"
        apt install --assume-yes --fix-missing i2c-tools
        
        echo "--------------------------------------------------------------"
        echo " Enable i2c overlay /boot/config.txt"
        echo "--------------------------------------------------------------"        
        sed -i /boot/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
        
        echo "--------------------------------------------------------------"
        echo " Enable i2c overlay /etc/modules"
        echo "--------------------------------------------------------------"  
        cat >> /etc/modules <<- DELIM
			#####################################################
			#Enable i2c-dev kernel module
			#####################################################
			i2c-dev
			DELIM
	fi
}
