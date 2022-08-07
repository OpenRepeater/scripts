function otg_console () {
	echo "--------------------------------------------------------------"
	echo " Enable otg usb serial console "
	echo "--------------------------------------------------------------"
    #/boot/cmdline.txt
    #backup the orig cmnline.txt
    cp /boot/cmdline.txt /boot/cmdline.txt.bak
    
    #Disabe otg for serial console
    sed -i /boot/config.txt -e"s#otg_mode=1#\#otg_mode=1#"

    # Add overlat for boot
    echo "" >> /boot/config.txt
    echo "# Enable USB Serial Port Pi Zero, Zero W, A and A+ " >> /boot/config.txt
    echo "dtoverlay=dwc2" >> /boot/config.txt
   
    #Post end of line 
    sed -i 's/$/ modules-load=dwc2,g_serial/' /boot/cmdline.txt
 
    #Add the kernel module to load
    echo "g_serial" >> /etc/modules
 
    #enable otg serial service
    systemctl enable getty@ttyGS0.service
    
    #link service call for systemd 
    ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

}
