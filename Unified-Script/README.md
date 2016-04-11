####Debian Jessie Base Images:
Use the appropriate base Debian Jessie image for your device:

RASPBERRY PI (Official Raspbian Jesse Lite)
https://downloads.raspberrypi.org/raspbian_lite_latest

BEAGLEBONE BLACK
https://rcn-ee.com/rootfs/bb.org/testing/2016-01-10/console/bone-debian-8.2-console-armhf-2016-01-10-2gb.img.xz

ODROID C1/C1+
http://repo.openrepeater.com/odroid-imgs/odroid-c1-jessie-minimal.img.xz


####Procedure:
- Download the appropriate Base Debian/Raspbian Jessie Image (links above).
- Write OS Image to SD Card.
- Insert SD card into RPI, Connect Network, connect sound card, and Power to your device
- Obtain Dynamic IP Address
- Connect to your board using SSH.  Login as pi (password raspberry).
- sudo su to root
- Execute "apt-get update && apt-get dist-upgrade"
- Use raspi-config to configure Timezone, Locale, Check GPU Mem(0), and Expand FS
- Reboot Pi.
- Connect to Pi using SSH.  Login as pi (password raspberry).
- sudo su to root
- Transfer ORP install_script to Pi.  (wget or scp or flashdrive)
- Edit ORP install_script (nano install_script).   Set Callsign.
- Change permissions on install_script (chmod +x install_script)
- Execute install_script ( ./install_script )
- Perform final tasks.... (edit php ini file and stuff)
- Reboot
- Login to admin site:  https://ip_address/  user:admin password:openrepeater
- Follow the wizard for you first time setup. You can log in afterwards to change more settings.
