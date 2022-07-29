Developer OpenRepeater Build Script
=======
This is the repository for the install/build script for the OpenRepeater project. With this script you can install OpenRepeater on your system or use it to build a complete system to image for download by others. The script will install the OpenRepeater UI, SVXLink, and other packages and dependancies required by OpenRepeater. It will also make some other system adjustments as well.

While this script is primarily created to run on a Raspberry Pi, it will most likely work on other Debian based systems, but will need modified accordingly or you may have to manually figure out and make these adjustments on your own. 

#### Requirements: 
* SD card of 8GB or Larger (8GB or larger recommended)
* You must be running Debian/Raspbian Bullseye OS (Ver 11) on your device
* You must run the install script as root 
* Make sure that you device is connected to the internet as it will need to download files and packages to install.
* ***It is suggested you should set a STATIC ip address*** for your device to prevent the IP changing during/after build. The simplest way to do this is in your router. Map and IP address to the MAC address of the ethernet adapter. 
* It's **HIGHLY RECOMMNED NOT TO BUILD OVER WIFI**. If your device does not have onboard ethernet, it is advised to use a USB to ethernet adapter during the build process where possible.
* Developers and Users should have a basic working knowledge of Linux. This guide/script is not intended for beginners.

#### Overview of the files:
* **README.md** - This file. You are reading it right now.
* **install_main.sh** - This is main script that you run. It contains some variables defined for install, and the main order of functions to be executed. It may prompt for some user input. It also requires and calls the external function scripts described below.
* **functions (folder)** - Contains any functions required by the main script. Board specific functions also live here.
	* **functions.sh** - This script contains the all the main functions required by all boards for building an ORP installation.
	*  **functions_svxlink.sh** - This script contains the functions to install/compile SVXLink and it's related dependancies.
	*  **functions_motd.sh** - This script contains the function to build the MOTD (Message of the Day) when logging in via SSH
	* **functions_rpi.sh** - This script contains functions specific to the Raspberry Pi.
	* **menus.sh** - Specific functions to display menus (using whiptail) to display information and request user input.
	* **functions_ics.sh** - This script contains functions releated to ICS Controllers support.
    * **functions_AutohotSpot.sh*** This script install hotspot settings so you can login to the repeater gui when you have no local internet. (Post Install)
**utilities (folder)**
	* **pi_version.sh** - Experimental script to detect version of Pi that script is running on.
**AutoHotSpot (folder)** this dir contains the hotspot scripts and install files.

#### Prepare your OS to Install Headless:
These directions will be geared towards the Raspberry Pi and Raspbian, but you should be able to modify them accordingly for other Debian systems. These instructions are for doing a complete build on a headless (without a keyboard and monitor connected) system via SSH.

1. Start by downloading a fresh version of Debian / Raspbian Lite (desktop GUI not needed). For Raspbian that can be found
    32bit (pi3b/pi-zero/pi-w)[Here](https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf-lite.img.xz). 
    64Bit (pi4/pi-w2)[Here]https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64-lite.img.xz
    
2. Download the raspi img tool. (Mac/Linux/Windows) [Here] (https://www.raspberrypi.com/software/). Install it on your system. 

3. Launch the Raspberry pi imager. 
   1. Use the Choose OS and scroll to use custom. Select the image file you downloaded in the downloads directory. 
   2. Then select the sd card your going to write to. 
   3. Next select the gear in the lower right corner. If it ask you for a user/password ignore and hit escape. 
   4. Now select and enter folling info : set hostname openrepeater. 
   5. Next select enable ssh, and select use password. 
   6. Nest select add user . Add a custom user/password used for first login. 
   7. Next if using wifi select the Configure wireless Lan, Enter your routers ssid and password. (if Ethernet dont use)
   8. Next select your country. 
   9. Next select set locale timezone and choose yours. Also choose your keyboard type. 
   10. Now hit save and flash the image to your sd card

4. Insert the SD card in the Pi and boot it up.

5. For now, log into the Pi using your user/password you set before flashing.

7. sudo su. enter your password for the user.

### Getting Scripts ######
8. Down load the scripts 1 of 2 ways:
   * &#35; **`wget https://github.com/OpenRepeater/scripts/archive/X.0.x.zip`** X=2/3 x=0/1/2/3
    or
   * &#35; **`git clone -b X.x.x https://github.com/OpenRepeater/scripts.git`** X=2/3 x= 0/1/2/3
* Unzip the script archive if you got the zip file.
	* &#35; **`unzip 3.0.x.zip`**
* else    
* Change to the script folder
	* &#35; **`cd scripts dir`**
* Make the script executable
	* &#35; **`chmod +x install_main.sh`** This will make the install script executable.
* Run the script
	* &#35; **`./install_main.sh`**
	* Please be patient, this process may take a while.
* Be sure to reboot when done
* Run "alsamixer" from the command prompt and make sure your input and output levels are properly set. You will need your hardware/sound card connected to set these levels.

#### Post Install Considerations:

* Remove the install script.
	* &#35; **`rm /root/3.0.x.zip`**
	* &#35; **`rm /root/scripts-3.0.x -R`**


* Be sure to set your time zone as required. On the raspberry Pi, the can be done by running `raspi-config`

* If you are building this for your own use, please change the root password to something that is more secure and not published.

* CAUTION: You are responsible for securing your own device and this will largely depend on your installation and particular needs. 



***Some common courtesies:*** This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capable, make the corrections and submit a pull request. We do this purely out of our desire to make ham radio Awesome. If you found this helpful, [consider supporting the project](https://openrepeater.com/donate)

Thanks & Enjoy,

~ The OpenRepeater Dev Team
