#!/bin/bash
################################################################################
# DEFINE OTG SERIAL CONSOLE FUNCTIONS
################################################################################
function otg_console () {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
    	echo "--------------------------------------------------------------"
        echo " Enable otg usb serial console "
        echo "--------------------------------------------------------------"
        ##############################
        #backup the orig cmnline.txt
        ##############################
        cp /boot/cmdline.txt /boot/cmdline.txt.bak

		##############################   
        #Post end of line cmdline.txt
        ##############################
        sed -i 's/^/dwc_otg.lpm_enable=0 /' /boot/cmdline.txt
        sed -i 's/$/ modules-load=dwc2,g_serial/' /boot/cmdline.txt

		##############################
        #Disabe otg for serial console
        ##############################
        sed -i /boot/config.txt -e"s#otg_mode=1#\#otg_mode=1#"

		##############################
        # Add overlat for boot
        ##############################
		cat >> /boot/config.txt <<- DELIM
			#####################################################
			#Enable USB Serial Port Pi Zero, Zero W, A and A+ OTG
			#####################################################
			dtoverlay=dwc2
			DELIM
 
 		##############################
        #Add the kernel module to load
        ##############################
        modprobe g_serial
		cat >> /etc/modules <<- DELIM
			#####################################################
			#Enable USB Serial Port Pi Zero, Zero W, A and A+ OTG
			#####################################################
			g_serial
			DELIM
 
 		##############################
        #enable otg serial service
        ##############################
        systemctl enable getty@ttyGS0.service
    fi
}
