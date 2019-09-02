OpenRepeater Build Script
=======
This is the repository for the install/build script for the OpenRepeater project. With this script you can install OpenRepeater on your system or use it to build a complete system to image for download by others. The script will install the OpenRepeater UI, SVXLink, and other packages and dependancies required by OpenRepeater. It will also make some other system adjustments as well.

While this script is primarily created to run on a Raspberry Pi, it will most likely work on other Debian based systems, but will need modified accordingly or you may have to manually figure out and make these adjustments on your own. 

#### Requirements: 
* SD card of 4GB or Larger (8GB or larger recommended)
* You must be running Debian/Raspbian Buster OS (Ver 10) on your device
* You must run the install script as root
* Make sure that you device is connected to the internet as it will need to download files and packages to install.
* ***You should set a STATIC ip address*** for your device to prevent the IP changing during/after build. The simplest way to do this is in your router. Map and IP address to the MAC address of the ethernet adapter. 
* It's **HIGHLY RECOMMNED NOT TO BUILD OVER WIFI**. If your device does not have onboard ethernet, it is advised to use a USB to ethernet adapter during the build process.
* You should have a working knowledge of Linux. This guide/script is not intended for beginners.

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
* **utilities (folder)**
	* **prep4img.sh** - This is a script that is run on the an install prior to making an image intended for distribution. It cleans up any settings and common identifiable information. 
	* **shrink_img.sh** - (Experiemental script) This is a script that is intended to be run on on a Linux computer with the SD card in a card reader to shrink the image for ease of distribution. This script has not been fully tested and was written by others. 
	* **pi_version.sh** - Experiemental script to detect version of Pi that script is running on.

#### Prepare your OS to Install Headless:
These directions will be geared towards the Raspberry Pi and Raspbian, but you should be able to modify them accordingly for other Debian systems. These instructions are for doing a complete build on a headless (without a keyboard and monitor connected) system via SSH.

1. Start by downloading a fresh version of Debian / Raspbian Lite (desktop GUI not needed). For Raspbian that can be found [here](https://www.raspberrypi.org/downloads/raspbian/).

2. Write the IMG file that you downloaded to your SD card. (Instructions: [Windows](https://openrepeater.com/knowledgebase/topic/writing-img-file-on-windows) | [Mac](https://openrepeater.com/knowledgebase/topic/writing-img-file-on-a-mac))

3. With the card still mounted on your computer, create an empty text file and save it to the *"boot"* partition of the SD card as "**ssh**" (without an extension). *This will partially enable SSH for the default "pi" user so that it may be used to enable SSH fully for the root user below.*

4. Insert the SD card in the Pi and boot it up.

5. For now, log into the Pi using the default username and password. For Raspbian: **pi/raspberry**

6. Enable SSH
	* &#35; **sudo systemctl enable ssh**
	* &#35; **sudo systemctl start ssh**
7. Setup Root Password
	* &#35; **sudo passwd root**
	* Note: if you are creating a new image for a public build, use the password *OpenRepeater* as the default as that is what is documented in the ORP knowledge base, otherwise set this to something secure.
8. Enable Root on Raspbian for SSH
	* &#35; **sudo nano /etc/ssh/sshd_config**
	* Then find the entry in the Authentication section of the file that says ‘PermitRootLogin’ and change it's value to ‘yes’ and make sure the line is uncommented, save and exit the file.
9. Restart SSH
	* &#35; **sudo systemctl restart ssh**
	* You can now log out as the "pi" user and log back in as "root" user. Note when you run the script below, the "pi" user will be removed for security reasons.

10. **IMPORTANT: Expand File System.** This is a must as most distro images are compacted. If the file system is not expand it is very likely that you will run out of disk space on the partition in the middle of the build process. See minimum SD card requirements above. For instructions on how to expand the file system, read this [knowledge base article](https://openrepeater.com/knowledgebase/topic/expanding-the-file-system).

#### How to Use: 
* Change to the root folder
	* &#35; **cd /root**
* Download this script in it's entirety from GitHub directly to your board's root folder.
	* &#35; **wget https://github.com/OpenRepeater/scripts/archive/2.2.x.zip**
* Unzip the script archive
	* &#35; **unzip 2.2.x.zip**
* Change to the script folder
	* &#35; **cd scripts-2.2.x**
* Make the script executable
	* &#35; **chmod +x install_main.sh**
	* Note: when you run the install_main.sh script, it will set the function scripts as executable.
* Run the script
	* &#35; **./install_main.sh**
	* Please be patient, this process may take a while.
* Be sure to reboot when done
* Run "alsamixer" from the command prompt and make sure your input and output levels are properly set. You will need your hardware/sound card connected to set these levels.

#### Post Install Considerations:

* Remove the install script.
	* &#35; **rm /root/2.2.x.zip**
	* &#35; **rm /root/scripts-2.2.x -R**
* On the Raspberry Pi, the script will remove the "pi" user for security reasons.

* Be sure to set your time zone as required. On the raspberry Pi, the can be done by running "raspi-config"

* If you are building this for your own use, please change the root password to something that is more secure and not published.

* CAUTION: You are responsible for securing your own device and this will largely depend on your installation and particular needs. 



***Some common courtesies:*** This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capable, make the corrections and submit a pull request. We do this purely out of our desire to make ham radio Awesome. If you found this helpful, [consider supporting the project](https://openrepeater.com/donate)

Thanks & Enjoy,

~ The OpenRepeater Dev Team
