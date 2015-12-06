Use this base Debian Jessie image:
https://repo.xecdesign.com/tmp/2015-11-04-raspbian-jessie-noX.zip

Procedure:

- Write raspbian-jessie-noX image to SD Card.
- Connect Network, Video, and Power to Pi
- Boot Pi.   
- Connect to Pi using SSH.  Login as pi (password raspberry).
- sudo su to root
- Execute "apt-get update && apt-get dist-upgrade"
- Execute "apt-get install apt-utils nano raspi-config" (shouldn't be needed for raspbian)
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