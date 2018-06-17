OpenRepeater Build Script
=======
This is the repository for the install/build script for the OpenRepeater project. With this script you can install OpenRepeater on your system or use it to build a complete system to image for download by others. The script will install the OpenRepeater UI, SVXLink, and other packages and dependancies required by OpenRepeater. It will also make some other system adjustments as well.

While this script is primarily created to run on a Raspberry Pi, it will most likely work on other Debian based systems, but will need modified accordingly or you may have to manually figure out and make these adjustments on your own. 

#### Requirements: 
* SD card of 4GB or Larger (8GB or larger recommended)
* You must be running Debian/Raspbian Stretch OS (Ver 9) on your device
* You must run the install script as root
* Make sure that you device is connected to the internet as it will need to download files and packages to install.
* You should have a working knowledge of Linux. This guide/script is not intended for beginners.

#### Overview of the files:
* **README.md** - This file. You are reading it right now.
* **install_main.sh** - This is main script that you run. It contains some variables defined for install, and the main order of functions to be executed. It may prompt for some user input. It also requires and calls the external function scripts described below.
* **functions (folder)** - Contains any functions required by the main script. Board specific functions also live here.
	* **functions.sh** - This script contains the all the main functions required by all boards for building an ORP installation.
	* **functions_rpi.sh** - This script contains functions specific to the Raspberry Pi.

#### Prepare your OS:
These directions will be geared a little more towards the Raspberry Pi and Raspbian, but you should be able to modify them accordingly for other Debian systems.

1. Start by downloading a fresh version of Debian / Raspbian Lite (desktop GUI not needed). For Raspbian that can be found [here](https://www.raspberrypi.org/downloads/raspbian/).

2. Write the IMG file that you downloaded to your SD card. (Instructions: [Windows](https://openrepeater.com/knowledgebase/topic/writing-img-file-on-windows) | [Mac](https://openrepeater.com/knowledgebase/topic/writing-img-file-on-a-mac))

3. Boot and log into using default username and password. For Raspbian: pi/raspberry

4. Enable SSH (via keyboard/console)
	* $ sudo systemctl enable ssh
	* $ sudo systemctl start ssh
5. Setup Root Password (via keyboard/console)
	* $ sudo passwd root
	* Note: if you are creating a new image for a public build, use the password *OpenRepeater* as the default as that is what is documented in the ORP knowledge base.
6. Enable Root on Raspbian for SSH
	* $ sudo nano /etc/ssh/sshd_config
	* Then find the entry in the Authentication section of the file that says ‘PermitRootLogin’ and change to ‘yes’ and make sure the line is uncommented, save and exit the file.
7. Restart SSH
	* $ sudo systemctl restart ssh
	* You should now be able to use the board headless, You can disconnect the keyboard and monitor and SSH in as root

8. **IMPORTANT: Expand File System.** This is a must as most distro images are compacted. If the file system is not expand it is very likely that you will run out of disk space on the partition in the middle of the build process. See minimum SD card requirements above. For instructions on how to expand the file system, read this [knowledge base article](https://openrepeater.com/knowledgebase/topic/expanding-the-file-system).

#### How to Use: 
* Boot up your board and login as root

* Change to the root folder
	* $ cd /root
* Download this script in it's entirety from GitHub directly to your board's root folder.
	* $ wget https://github.com/OpenRepeater/scripts/archive/2.x.x.zip
* Unzip the script archive
	* $ unzip 2.x.x.zip
* Change to the script folder
	* $ cd scripts-2.x.x
* Make the script executable
	* $ chmod +x install_main.sh
	* Note: when you run the install_main.sh script, it will set the function scripts as executable.
* Run the script
	* $ ./install_main.sh
	* Please be patient, this process may take a while.

#### Post Install Considerations:
* Remove the install script.
	* $ rm /root/2.x.x.zip
	* $ rm /root/scripts-2.x.x -R
* On the Raspberry Pi, you may want to disable, remove, or change the default password for the default user (pi) to something more secure.

* If you are building this for your own use, please change the root password to something that is more secure and not published.
* CAUTION: You are responsible for securing your own device and this will largely depend on your installation and particular needs. 



***Some common courtesies:*** This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capable, make the corrections and submit a pull request. This is an open source project and the developers are unpaid. We do this purely out of our desire to make ham radio Awesome.

Thanks & Enjoy,

~ The OpenRepeater Dev Team