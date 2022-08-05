function otg_console () {
	echo "--------------------------------------------------------------"
	echo " Enable otg usb serial console "
	echo "--------------------------------------------------------------"
    # Add overlat for boot
	echo "dtoverlay=dwc2" >> /boot/config.txt
 
    #/boot/cmdline.txt
    #backup the orig cmnline.txt
    cp /boot/cmdline.txt /boot/cmdline.txt.bak
    #Prefix
    sed -i 's/^/dwc_otg.lpm_enable=0 /' cmdline.txt
    #PostFix
    sed -i 's/$/ modules-load=dwc2,g_serial/' cmdline.txt
 
    #enable otg serial service
    systemctl enable getty@ttyGS0.service
    
    #link service call for systemd 
    ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

}
