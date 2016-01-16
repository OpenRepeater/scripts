Use this base Debian Jessie image:
https://rcn-ee.com/rootfs/bb.org/testing/2016-01-10/console/bone-debian-8.2-console-armhf-2016-01-10-2gb.img.xz

- Write bone-debian-8.2-console-armhf-2015-11-21-2gb.img to SD Card.
- Connect Network, and Power to BBBlack
- Boot BBBlack.   
- Connect to BBBlack using SSH.  Login as root (password odroid).
- Execute "apt-get update && apt-get dist-upgrade"
- Transfer ORP install_script to BBBlack  (wget or scp or flashdrive)
- Edit ORP install_script (nano install_script).   Set Callsign.
- Change permissions on install_script (chmod +x install_script)
- Execute install_script ( ./install_script )
- Perform final tasks.... (edit php ini file and stuff)
- Login to admin site:  https://ip_address/  user:admin password:openrepeater
