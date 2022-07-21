OpenRepeater/SvxLink Build Script
=======
This is the repository for the install/build script for the OpenRepeater project. With this script you can install OpenRepeater on your system or use it to build a complete system to image for download by others. The script will install the OpenRepeater UI, SVXLink, and other packages and dependancies required by OpenRepeater. It will also make some other system adjustments as well.

While this script is primarily created to run on a Raspberry Pi, it will most likely work on other Debian based systems, but will need modified accordingly or you may have to manually figure out and make these adjustments on your own. 

#### Requirements: 
* SD card of 4GB or Larger (8GB or larger recommended)

* You must be running Debian/Raspbian Bullseye OS (Ver 11) on your device

* You must run the install script as sudo or root

* Make sure that you device is connected to the internet as it will need to download files and packages to install.

* **You should set a STATIC ip address**
    for your device to prevent the IP changing during/after build. The simplest way to do this is in your router. Map and IP address to the MAC address of the ethernet adapter.

* You should have a working knowledge of Linux. This guide/script is not intended for beginners.

#### Overview of the files:
* **README.md** - This file. You are reading it right now.

* **install_main.sh** - This is main script that you run. It contains some variables defined for install, and the main order of functions to be executed. It may prompt for some user input. It also requires and calls the external function scripts described below.

* **functions (folder)** - Contains any functions required by the main script. Board specific functions also live here.
	* **functions.sh** - This script contains the all the main functions required by all boards for building an ORP installation.
	* **functions_svxlink.sh** - This script contains the functions to install/compile SVXLink and it's related dependancies.
	* **functions_motd.sh** - This script contains the function to build the MOTD (Message of the Day) when logging in via SSH
	* **functions_rpi.sh** - This script contains functions specific to the Raspberry Pi.
	* **menus.sh** - Specific functions to display menus (using whiptail) to display information and request user input.
	* **functions_ics.sh** - This script contains functions releated to ICS Controllers support.
    * **functions_autohotspot.sh** - This script installs and configures a local hotspot Orp_Hotspot.
    
* **utilities (folder)**
	* **pi_version.sh** - Experimental script to detect version of Pi that script is running on.

#### Prepare your OS to Install Headless:
These directions will be geared towards the Raspberry Pi and Raspbian, but you should be able to modify them accordingly for other Debian systems. These instructions are for doing a complete build on a headless (without a keyboard and monitor connected) system via SSH.

1. Start by downloading a fresh version of Debian / Raspbian Lite (desktop GUI not needed). For Raspbian that can be found [here](https://www.raspberrypi.org/downloads/raspbian/).

2. Write the IMG file that you downloaded to your SD card. 

4. Insert the SD card in the Pi and boot it up.


#### How to Use: 
* Change to the root folder
	* &#35; **`cd /root`**
* Download this script in it's entirety from GitHub directly to your board's root folder.
	* &#35; **wget https://github.com/OpenRepeater/scripts/archive/2.2.x.zip**
* Unzip the script archive
	* &#35; **unzip 2.2.x.zip**
* Change to the script folder
	* &#35; **cd scripts-2.2.x**
* Make the script executable
	* &#35; **`chmod +x install_main.sh`**
	* Note: when you run the install_main.sh script, it will set the function scripts as executable.
* Run the script
	* &#35; **`./install_main.sh`**
	* Please be patient, this process may take a while.
* install the Automatic hotspot
    * &#35; **expect /usr/share/Autohotspot/AutoConfigure_ORP.exp**
* Be sure to reboot when done
* Run "alsamixer" from the command prompt and make sure your input and output levels are properly set. You will need your hardware/sound card connected to set these levels.

#### Post Install Considerations:

* CAUTION: You are responsible for securing your own device and this will largely depend on your installation and particular needs. 

***Some common courtesies:*** This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capable, make the corrections and submit a pull request. We do this purely out of our desire to make ham radio Awesome. If you found this helpful, [consider supporting the project](https://openrepeater.com/donate)

Thanks & Enjoy,

~ The OpenRepeater Dev Team
