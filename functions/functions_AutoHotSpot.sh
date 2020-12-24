function AutoHotSpot_Autosetup () {
	echo "--------------------------------------------------------------"
	echo " Apply AutoHotSpot & Configure for ORP"
	echo "--------------------------------------------------------------"
	
	echo " --- Move files to destination"
	#move the files to the final location
	chmod +x /root/scripts/AutoHotSpot/Autohotspot/autohotspot-setup.sh
	mkdir /usr/share/Autohotspot/
	mv /root/scripts/AutoHotSpot/* /usr/share/Autohotspot/
	sleep 4
	rm -rf /root/scripts/AutoHotSpot
	
	# run the script to install
	echo " --- Install dependencies"
	apt-get install --assume-yes --fix-missing expect dnsmasq hostapd
	echo " --- Create ORP hotspot"	
	/usr/share/Autohotspot/Autohotspot/autohotspot-setup.sh -a

}
