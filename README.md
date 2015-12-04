OpenRepeater Build Scripts
=======
This is the repository for install scripts for the OpenRepeater project. With these scripts you can install OpenRepeater on your system or use it to build a complete system to image for download by others. The script will install Debian packages for OpenRepeater, SVXLink, and other packages dependancies required by OpenRepeater. It will also make some other system adjustments as well. Currently we support 3 boards:
* BeagleBone Black
* Raspiberry Pi 2 (quad core)
* Odroid C1/C1+

These scripts will most likly work on other systems, but will need modified accordinly.

####Requirements: 
* You must be running Debian Jessie OS on your device
* You must run the install script as root
* Make sure that you device is connected to the internet as it will need to download packages to install.

####How to Use: 
* Go the the folder for your supported board and copy the URL for the .sh script. You can do this by going into the script and copying the RAW link.
* Boot up your device and login as root
* Change to your home folder (cd ~)
* WGET the url you copied previously.
* Make the script executable (chmod +x script_name.sh)
* Run the script

*Some common courtesies:* This is a Work-In-Progress. If a script is broken, please report it via GitHub Issues but be polite about it. If you are capible, make the corrections and submit a pull request. This is an opensource project and the developers are unpaid. We do this purely out of our desire to make ham radio Awesome.

Thanks & Enjoy,
~ The OpenRepeater Dev Team
