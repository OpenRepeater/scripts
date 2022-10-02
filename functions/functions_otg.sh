#!/bin/bash
################################################################################
# DEFINE OTG SERIAL Console / Ethernet FUNCTIONS
################################################################################

function otg_console () {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
    
    	#######################################
    	echo "-------------------------------"
        echo " Enable otg usb port           "
        echo "-------------------------------"
        #######################################

		######################################        
    	echo "-------------------------------"
        echo " Backup the orig cmdline.txt   "
    	echo "-------------------------------"
    	######################################
    	
        cp /boot/cmdline.txt /boot/cmdline.txt.bak
        
        echo "complete"

		############################################
    	echo "-------------------------------------"
        echo " Post dwc_otg.lpm_enable=0 begining  "
        echo " of line cmdline.txt for usb console "
    	echo "-------------------------------------"
    	############################################
    	
        sed -i 's/^/dwc_otg.lpm_enable=0 /' /boot/cmdline.txt
        
        echo "complete"
        
        
        if [ otg_gcdc_enable == yes ]; then
			##############################################
    		echo "---------------------------------------"
        	echo " Enable g_cdc end of line cmdline.txt  "
        	echo " for usb network/console               "
    		echo "---------------------------------------"
    		##############################################
    		
	       	sed -i 's/$/ modules-load=dwc2,g_cdc/' /boot/cmdline.txt
	       	
	       	echo "complete"
		else
			############################################
    		echo "-------------------------------------"
        	echo " Enable g_serial cmdline.txt end of  "
        	echo " line cmdline.txt for usb console    "
    		echo "-------------------------------------"
    		############################################
    		
			sed -i 's/$/ modules-load=dwc2,g_serial/' /boot/cmdline.txt
			
			echo "complete"
		fi

		##########################################
    	echo "-----------------------------------"
        echo " Disabe otg_mode=1 for usb console "
    	echo "-----------------------------------"
    	##########################################
    	
        sed -i /boot/config.txt -e"s#otg_mode=1#\#otg_mode=1#"
        
        echo "complete"

		############################################
    	echo "-------------------------------"
        echo " Add overlay for boot dwc2 for "
        echo " usb console"
    	echo "-------------------------------"
    	############################################
    	
		cat >> /boot/config.txt <<- DELIM
			#################################
			# Enable USB Serial Port Pi Zero,
			# Zero W, A and A+ OTG
			#################################
			dtoverlay=dwc2
			DELIM
			
		echo "complete"
			
		 if [ otg_gcdc_enable == yes ]; then
		 	############################################
    		echo "--------------------------------------"
   	 		echo " Add the kernel module to load g_cdc  "
    		echo "--------------------------------------"
			############################################

    	    modprobe g_cdc
			cat >> /etc/modules <<- DELIM
				############################################
				# Enable USB Serial / Ethernet Port Pi Zero, 
				# Zero W, Zero W2, A and A+ OTG , 4B
				############################################
				g_cdc
				DELIM
				
				echo "complete"
				
			######################################
    		echo "-------------------------------"
 			echo " Add usb interface for boot    "
 			echo " 172.16.0.1                    "
    		echo "-------------------------------"
    		######################################
    		
			cat >> /etc/network/interfaces.d/usb0 <<- DELIM
				auto usb0
				iface usb0 inet static
				address 172.16.0.1
				netmask 255.255.0.0
				gateway 172.16.0.1
				DELIM
				
			echo "complete"
 		else
 		
 			###############################################	
    		echo "----------------------------------------"
   	 		echo " Add the kernel module to load g_serial "
    		echo "----------------------------------------"
    		###############################################
    	    modprobe g_serial
			cat >> /etc/modules <<- DELIM
				############################################
				# Enable USB Serial / Ethernet Port Pi Zero, 
				# Zero W, Zero W2, A and A+ OTG , 4B
				############################################
				g_serial
				DELIM
				
			echo "complete"
 		fi

		####################################### 		
    	echo "--------------------------------"
        echo "#enable otg serial getty service"
    	echo "--------------------------------"
    	#######################################
        systemctl enable getty@ttyGS0.service
        
        echo "complete"
    fi
}
