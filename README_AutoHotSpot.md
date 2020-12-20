The Open Repeater installer will automatically configure the system to act as a hotspot
when wifi does not automatically connect to a known hotspot.  This helps to
allow the user to configure their personal wifi by connecting to this hotspot
and the running the <raspi-config> utility to connect to their own networks.

Once the raspi-config setup of wifi is completed, the next reboot the wireless
will connect to the configured network unless something is wrongly configured.  
If this happens, the hotspot will again be present.

If you want to disable the automatic hotspot, you can execute the following command

expect /usr/share/Autohotspot/AutoHotSpot_4.exp

which will uninstall the hotspot and revert the wifi to default raspberry pi behavior.