function AutoHotSpotScript_MoveAndExtract () {
	mkdir /usr/share/AutoHotSpot/;
	tar -xzvf ./AutoHotSpot/AutoHotspot-Setup.tar.gz --directory /usr/share/;
	mv ./AutoHotSpot/*.exp /usr/share/Autohotspot/;
	rm ./AutoHotSpot/AutoHotspot-Setup.tar.gz;
	rmdir AutoHotSpot
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
