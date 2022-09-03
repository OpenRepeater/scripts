Developer OpenRepeater Build Script Debian (11) Bullseye
=======
*This is the repository for the install/build script for the OpenRepeater project. With this script you can install OpenRepeater on your system 
 or use it to build a complete system to image for download by others. The script will install the OpenRepeater UI, SVXLink, and other packages 
 and dependancies required by OpenRepeater. It will also make some other system adjustments as well.

*While this script is primarily created to run on a Raspberry Pi, it will most likely work on other Debian based systems, but will need modified 
 accordingly or you may have to manually figure out and make these adjustments on your own. 

#### Requirements: 
* SD card of 8GB or Larger (8GB or larger recommended)
* You must be running Debian/Raspbian Bullseye OS (Ver 11) on your device
* You must run the install script as root 
* Make sure that you device is connected to the internet as it will need to download files and packages to install.
* ***It is suggested you should set a STATIC ip address*** for your device to prevent the IP changing during/after build. 
    The simplest way to do this is in your router. Map and IP address to the MAC address of the ethernet adapter. 
* It's **HIGHLY RECOMMNED NOT TO BUILD OVER WIFI**. If your device does not have onboard ethernet, it is advised 
    to use a USB to ethernet adapter during the build process where possible.
* Developers and Users should have a basic working knowledge of Linux. This guide/script is not intended for beginners.

#### Overview of the files:
* **README.md** - This file. You are reading it right now.
* **install_main.sh** - This is main script that you run. It contains some variables defined for install, and the main order 
    of functions to be executed. It may prompt for some user input. It also requires and calls the external function scripts 
    described below.
* **functions (folder)** - Contains any functions required by the main script. Board specific functions also live here.
	* **functions.sh** - This script contains the all the main functions required by all boards for building an ORP installation.
	* **functions_svxlink.sh** - This script contains the functions to install/compile SVXLink and it's related dependancies.
	* **functions_motd.sh** - This script contains the function to build the MOTD (Message of the Day) when logging in via SSH
	* **functions_rpi.sh** - This script contains functions specific to the Raspberry Pi.
	* **menus.sh** - Specific functions to display menus (using whiptail) to display information and request user input.
	* **functions_ics.sh** - This script contains functions releated to ICS Controllers support.
    * **functions_AutohotSpot.sh*** This script install hotspot settings so you can login to the repeater gui when you have no local internet. (Post Install)
**utilities (folder)**
	* **pi_version.sh** - Experimental script to detect version of Pi that script is running on.
**AutoHotSpot (folder)** this dir contains the hotspot scripts and install files.

#### Prepare your OS to Install Headless:
These directions will be geared towards the Raspberry Pi and raspi-lite, but you should be able to modify them accordingly for other Debian systems. 
These instructions are for doing a complete build on a headless (without a keyboard and monitor connected) system via SSH.

1. Download the raspi img tool. (Mac/Linux/Windows) [Here] (https://www.raspberrypi.com/software/). Install it on your system. 

2. Launch the Raspberry pi imager. 
   1. Use the Choose OS and scroll to Raspberry PI OS (other). Select Raspberry Pi OS Light 32 or 64 bit . 
   2. Then select the sd card your going to write to. 
   3. Next select the gear in the lower right corner. If it ask you for a user/password ignore and hit escape. 
   4. Now select and enter following info : set hostname openrepeater. 
   5. Next select enable ssh, and select use password. 
   6. Nest select add user . Add a custom user/password used for first login. 
   7. Next if using wifi select the Configure wireless Lan, Enter your routers ssid and password. (if Ethernet dont use)
   8. Next select your country. 
   9. Next select set locale timezone and choose yours. Also choose your keyboard type. 
   10. Now hit save and flash the image to your sd card

4. Insert the SD card in the Pi and boot it up.
5. For now, log into the openrepeater via ssh using your user/password you set before flashing.
7. sudo su and you have root.

### Getting Scripts ######

8. Down load the scripts 1 of 2 ways:
    git:
    * First apt install git , Not installed on os image by default. Then:
    * &#35; **`git clone -b X.x.x https://github.com/OpenRepeater/scripts.git /usr/src/scripts`** X=2/3 x=x/0/1/2/3
    or
    wget: 
    * &#35; **`cd /usr/src && wget https://github.com/OpenRepeater/scripts/archive/X.x.x.zip `** X=2/3 x=x/0/1/2/3
* Unzip the script archive if you got the zip file.
	* &#35; **`unzip X.x.x.zip`**
* else    
* Change to the script folder
	* &#35; **`cd /usr/src/scripts dir`**
* Make the script executable
	* &#35; **`chmod +x install_orp.sh`** This will make the install script executable.
* Run the script
	* &#35; **`./install_orp.sh`**
	* Please be patient, this process may take a while.

* Remove the install script.
    * &#35; **`rm -rf /usr/src/*`**

* Be sure to reboot when done

#### Post Install Considerations:

* Run "alsamixer" from the command prompt and make sure your input and output levels are properly set. You will need your hardware/sound card connected to set these levels.
    sudo su : user/pwd alsamixer.

* HotSpot Login:
    HotSpot allows you to work on the repeater if there is no internet where its located. The HotSpot will not load if you have ethernet connected. or wpa_supplicant.conf installed on the /boot before boot up.

    Hotspot IP Address for HTTP,SSH and VNC: 192.168.50.5 or openrepeater.local
    Hotspot SSID: ORP_HOTSPOT
    Hotspot Password: OpenRepeater

    HotSpot allows you to work on the repeater if there is no internet where its located.
    You can still login via WebGui at 192.168.50.5 or openrepeater.local.

* Be sure to set your time zone as required. On the raspberry Pi, the can be done by running `raspi-config`

* CAUTION: You are responsible for securing your own device and this will largely depend on your installation and particular needs.

***Some common courtesies:*** This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capable, make the corrections 
    and submit a pull request. We do this purely out of our desire to make ham radio Awesome. If you found this helpful, [consider supporting the project](https://openrepeater.com/donate)

Thanks & Enjoy,

~ The OpenRepeater Dev Team
