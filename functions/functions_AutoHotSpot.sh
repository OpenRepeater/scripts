function AutoHotSpotScript_MoveAndExtract () {
	echo "--------------------------------------------------------------"
	echo " Apply AutoHotSpot & Configure for ORP"
	echo "--------------------------------------------------------------"
	
	#move the files to the final location
	chmod +x /root/scripts/AutoHotSpot/Autohotspot/autohotspot-setup.sh
	mkdir /usr/share/Autohotspot/
	mv /root/scripts/AutoHotSpot/* /usr/share/Autohotspot/
	sleep 4
	# run the script to install
	rm -rf /root/scripts/AutoHotSpot
	
}
function AutoHotSpot_Autosetup () {
	echo "--------------------------------------------------------------"
	echo " --- Move files to destination"
	AutoHotSpotScript_MoveAndExtract
	echo " --- Create hotspot"	
	expect /usr/share/Autohotspot/AutoConfigure_ORP.exp |grep 'SSID name \|WiFi password'
	echo " --- Configure hotspot"
	AutoHotSpot_SSID_PWD
}
function AutoHotSpot_AutoWithInternet () {
	expect /usr/share/Autohotspot/AutoHotSpot_1.exp |grep 'SSID name \|WiFi password'
}
function AutoHotSpot_AutoWithoutInternet  () {
	expect /usr/share/Autohotspot/AutoHotSpot_2.exp |grep 'SSID name \|WiFi password'
}
function AutoHotSpot_PermHotspotWithInternet () {
	expect /usr/share/Autohotspot/AutoHotSpot_3.exp |grep 'SSID name \|WiFi password'
}
function AutoHotSpot_uninstall () {
	expect /usr/share/Autohotspot/AutoHotSpot_4.exp
}
function AutoHotSpot_SSID_PWD {
	expect /usr/share/Autohotspot/AutoHotSpot_7.exp ORP_HotSpot OpenRepeater
}
