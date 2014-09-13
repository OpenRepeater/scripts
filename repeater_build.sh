#!/bin/sh

# ####################################################################################
# DEFINE GLOBAL FUNCTIONS 
# ####################################################################################

# FUNCTION USED TO UPDATE CONFIG FILE SETTING KEY/VALUES
# USAGE: edit_config FILE KEY VALUE ENABLED
edit_config() {
	if [ "$4" = "enabled" ]
	then
		# UNCOMMENT THE LINE IF IT IS COMMENTED OUT
		sed -i "/${2}/ s/# *//" $1
		# CHANGE THE VALUE
		sed -i "s/\($2 *= *\).*/\1$3/" $1
	else
		# COMMENT OUT THE LINE
		sed -i "/${2}/ s/^/# /" $1 
	fi
}

# ####################################################################################
# CHECK FOR ROOT PRIVILEGES and INTERNET CONNECTION, IF NOT EXIT 
# ####################################################################################

if [ "$(whoami)" != "root" ]; then
	echo "OPPS! Sorry, but you must run this script as root or using sudo."
	echo "Please Try Again...\n"
	exit 1
fi

echo "Please Wait...checking for internet connectivity."
if [ "$(ping -c 2 google.com | grep '100% packet loss' )" != "" ]; then
	echo "Internet Status: FAILED\n"
	echo "You device does not appear to be properly connected to the interent.\nPlease correct this and try again.\n"
    exit 1
else
	echo "Internet Status: OK\n"
fi

ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/{split($2,_," ");print "Current IP Address: " _[1]"\n"}'

# ####################################################################################
# WELCOME MESSAGE
# ####################################################################################

while true; do
    read -p "Are you ready to get stared? This can take a LONG time and you will be prompted with questions along the way. (Y or N): " yn
    case $yn in
        [Yy]* ) echo "On with the show..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# ####################################################################################
# CHANGE TIMEZONE
# ####################################################################################

set_timezone () {
	tzselect
	echo "\n\n"
}

# ####################################################################################
# UPDATE PACKAGES
# ####################################################################################

get_updates () {
	echo "Updating list of packages..."; apt-get update; 
}

# ####################################################################################
# DISABLE BEAGLEBONE 101 WEB SERVICES
# ####################################################################################

disable_bbb101 () {
	systemctl disable cloud9.service
	systemctl disable gateone.service
	systemctl disable bonescript.service
	systemctl disable bonescript.socket
	systemctl disable bonescript-autorun.service
	systemctl disable avahi-daemon.service
	systemctl disable gdm.service
	systemctl disable mpd.service

	systemctl stop cloud9.service
	systemctl stop gateone.service
	systemctl stop bonescript.service
	systemctl stop bonescript.socket
	systemctl stop bonescript-autorun.service
	systemctl stop avahi-daemon.service
	systemctl stop gdm.service
	systemctl stop mpd.service

	echo "Beaglebone 101 services Stopped and Disabled"
}

# ####################################################################################
# SETUP WEB SERVER
# ####################################################################################

install_webserver () {
	apt-get install mysql-server lighttpd php5-cgi php5-mysql

	# Edit the php.ini file:
	# nano /etc/php5/cgi/php.ini
	# And uncomment: 'cgi.fix_pathinfo = 1'       uses ; for comment

	# UNCOMMENT THE LINE IF IT IS COMMENTED OUT
	sed -i "cgi.fix_pathinfo = // s/; *//" /etc/php5/cgi/php.ini

#Replace contents of lighttpd.conf with this:
lighttpdConfig=$( cat <<EOF
		server.modules = (
			"mod_access",
			"mod_alias",
			"mod_compress",
			"mod_redirect",
			"mod_rewrite",
			"mod_accesslog",
			"mod_fastcgi",
		)

		server.document-root        = "/var/www"
		server.upload-dirs          = ( "/var/cache/lighttpd/uploads" )
		server.errorlog             = "/var/log/lighttpd/error.log"
		server.pid-file             = "/var/run/lighttpd.pid"
		server.username             = "www-data"
		server.groupname            = "www-data"
		server.port                 = 80
		server.tag                  = "Private Server"

		index-file.names            = ( "index.php", "index.html", "index.lighttpd.html" )
		url.access-deny             = ( "~", ".inc", ".htaccess", ".htpasswd", "password.txt", "username.txt", "login.txt" )
		static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )

		compress.cache-dir          = "/var/cache/lighttpd/compress/"
		compress.filetype           = ( "application/javascript", "text/css", "text/html", "text/plain" )

		# default listening port for IPv6 falls back to the IPv4 port
		include_shell "/usr/share/lighttpd/use-ipv6.pl " + server.port
		include_shell "/usr/share/lighttpd/create-mime.assign.pl"
		include_shell "/usr/share/lighttpd/include-conf-enabled.pl"

		fastcgi.server = ( ".php" => ((
							 "bin-path" => "/usr/bin/php5-cgi",
							 "socket" => "/tmp/php.socket",
				"max-procs" => 5,
				"bin-environment" => ( 
					"PHP_FCGI_CHILDREN" => "40",
					"PHP_FCGI_MAX_REQUESTS" => "10000"
				),
				"bin-copy-environment" => (
					"PATH", "SHELL", "USER"
				),
				"broken-scriptfilename" => "enable"
						 )))
EOF
)

	echo "$lighttpdConfig" > /etc/lighttpd/lighttpd.conf

	#Restart Lighttpd:
	/etc/init.d/lighttpd restart

#	All errors generated by Lighttpd are saved, by default, in this file:
#	/var/log/lighttpd/error.log

	# Make sure the path /var/www/ is owned by your web server user (www-data or lighttpd):
	chown -R www-data:www-data /var/www
}

# ####################################################################################
# GET OPEN REPEATER FILES
# ####################################################################################

get_OpenRepeater_files () {
	download_local () {
		cd /var/www
		rm Archive.zip
		wget http://192.168.1.74/Archive.zip
		unzip Archive.zip
		rm Archive.zip
		chmod 777 -R /var/www/
		chown -R www-data:www-data /var/www/
	}

	while true; do
		read -p "Files must be zipped up on BBB as Archive.zip. Are you ready to proceed? (Y or N): " yn
		case $yn in
			[Yy]* ) download_local; break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

# ####################################################################################
# SETUP EMPTY MYSQL DATABASE
# ####################################################################################

setup_MySQL_db () {
	rootpw="raspberry"
	dbname="repeater"
	dbuser="pi"
	dbpassword="raspberry"
	phpDB_SettingsFile="database.php"

	MYSQL=`which mysql`

	SQL="CREATE DATABASE IF NOT EXISTS $dbname;GRANT ALL ON *.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';FLUSH PRIVILEGES;SHOW DATABASES;"
 
	$MYSQL -uroot --password=$rootpw -e "$SQL"


	### BUILD NEW DATABASE CONNECTION FILE FOR PHP INTERFACE AND CHANGE PERMISSIONS

phpDB_Settings=$( cat <<EOF
<?php
// MySQL Connection
\$MySQLUsername = "$dbuser";
\$MySQLPassword = "$dbpassword";
\$MySQLHost = "localhost";
\$MySQLDB = "$dbname";
?>
EOF
)

	echo "$phpDB_Settings" > /var/www/admin/_includes/$phpDB_SettingsFile

	chmod 777 /var/www/admin/_includes/$phpDB_SettingsFile
	chown www-data:www-data /var/www/admin/_includes/$phpDB_SettingsFile


	
	# EXECUTE PHP SCRIPT TO POPULATE DATABASE WITH DEFAULT VALUES IN SQL FILE.
	php /var/www/admin/functions/config_db.php
}

# ####################################################################################
# INSTALL MEMCACHED
# ####################################################################################

install_memcached () {
	apt-get install memcached php5-memcache
	apt-get install php-pear php5-dev
	pecl install memcache
	apt-get install python-memcache
#	Add “extension=memcached.so” to php.ini (located at /etc/php5/cgi/php.ini and restart lighttpd web server)
#	nano /etc/php5/cgi/php.ini
	echo "You will still need to edit the PHP.ini file and add “extension=memcached.so” to php.ini (located at /etc/php5/cgi/php.ini and restart lighttpd web server)"

	#Restart Lighttpd:
	#/etc/init.d/lighttpd restart
}

# ####################################################################################
# INSTALL SOX AUDIO CONVERTER
# ####################################################################################

install_sox () {
	apt-get install sox
	apt-get install libsox-fmt-mp3

	#USAGE:
	#sox /var/www/admin/courtesy_tones/OLD/Nextel.mp3 -r16000 -b16 -esigned-integer -c1 /var/www/admin/courtesy_tones/outfile.wav
}

# ####################################################################################
# SVXLINK
# ####################################################################################

build_svxlink () {
	#sudo apt-get update
	apt-get install g++ make libsigc++-2.0-dev libgsm1-dev libpopt-dev tcl8.5-dev libgcrypt11-dev libspeex-dev libasound2-dev alsa-utils vorbis-tools
	mkdir /home/bbb/downloads/
	cd /home/bbb/downloads
	wget http://sourceforge.net/projects/svxlink/files/svxlink/13.12/svxlink-13.12.tar.gz
	tar xvzf svxlink-13.12.tar.gz
	cd svxlink-13.12
	make
	make install
	#(Delete svxlink-13.12.tar.gz for Downloads?)
	cd /home/bbb/downloads
	wget http://sourceforge.net/projects/svxlink/files/sounds/13.12/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
	cd /usr/share/svxlink/sounds
	tar -xvjpf /home/bbb/downloads/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
	ln -s en_US-heather-16k en_US
	rm /home/bbb/downloads/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
	rm /home/bbb/downloads/svxlink-13.12.tar.gz
	rm -rf /etc/svxlink
	ln -s /var/www/admin/svxlink /etc/svxlink
	
	#Comment out settings in ALSA conf file to allow USB audio device over built in audio out.
	#Move svxlink config files from /etc/svxlink to web root, create a symbolic link in its place.

	#  wget http://sourceforge.net/projects/svxlink/files/svxlink/13.12/README-13.12.md
	
	# Create Link to folder with override TCL files
	ln -s /var/www/admin/svxlink/local-events.d /usr/share/svxlink/events.d/local
	
	echo "Finished Installing SVXLink"
}


# ####################################################################################
# INSTALL FTP SERVER FOR DEVELOPMENT
# ####################################################################################

install_ftp () {
	apt-get install vsftpd
	
	FTP_CONFIG_PATH="/etc/vsftpd.conf"
	edit_config $FTP_CONFIG_PATH anonymous_enable NO enabled
	edit_config $FTP_CONFIG_PATH local_enable YES enabled
	edit_config $FTP_CONFIG_PATH write_enable YES enabled
	edit_config $FTP_CONFIG_PATH local_umask 022 enabled

	cat "force_dot_files=YES" >> "$FTP_CONFIG_PATH"

	/etc/init.d/vsftpd restart
}

# ####################################################################################
# ADD USER
# ####################################################################################

add_user () {
	adduser openrepeater
}


# ####################################################################################
# FINISH WITH A REBOOT
# ####################################################################################

system_shutdown () {
	shutdown -r now;
}



# ####################################################################################
# DISPLAY THE MENU SYSTEM
# ####################################################################################

while :
do
 clear
 echo "-----------------------------------------------------------------------"
 echo "Welcome to the OpenRepeater Project!"
 echo "-----------------------------------------------------------------------"
 echo "   M A I N - M E N U"
 echo "1. Update Timezone"
 echo "2. Get Updates"
 echo "3. Disable the Beaglebone 101 Web Services. This is only applicable to a new Beaglebone with a preinstalled distro."
 echo "4. Install the web server"
 echo "5. Get OpenRepeater files"
 echo "6. Setup MySQL database"
 echo "7. Install Memcache"
 echo "8. Install SOX package for converting audio"
 echo "9. Install Core SVXLink Files"
 echo "20. Install FTP Server (for Development Only)"
 echo "21. Add User (for FTP Use)"
 echo "99. System Restart"
 echo "0. Exit"
 echo ""
 echo -n "Please enter option above and press ENTER: "
 read opt
 case $opt in
  1) set_timezone; echo "Press [enter] key to continue. . ."; read enterKey;;
  2) get_updates; echo "Press [enter] key to continue. . ."; read enterKey;;
  3) disable_bbb101; echo "Press [enter] key to continue. . ."; read enterKey;;
  4) install_webserver; echo "Press [enter] key to continue. . ."; read enterKey;;
  5) get_OpenRepeater_files; echo "Press [enter] key to continue. . ."; read enterKey;;
  6) setup_MySQL_db; echo "Press [enter] key to continue. . ."; read enterKey;;
  7) install_memcached; echo "Press [enter] key to continue. . ."; read enterKey;;
  8) install_sox; echo "Press [enter] key to continue. . ."; read enterKey;;
  9) build_svxlink; echo "Press [enter] key to continue. . ."; read enterKey;;

  20) install_ftp; echo "Press [enter] key to continue. . ."; read enterKey;;
  21) add_user; echo "Press [enter] key to continue. . ."; read enterKey;;

  99) system_shutdown; echo "Press [enter] key to continue. . ."; read enterKey;;

  0) clear; echo "Quiting Script, Goodbye..."; exit 1;;
  *) echo "$opt is an invaild option. Please select one of the options above.";
     echo "Press [enter] key to continue. . .";
     read enterKey;;
esac
done













# ####################################################################################
# OTHER STUFF
# ####################################################################################

# JUST A BUNCH OF EXTRA JUNK, NOTES, THINGS I HAVEN'T GOTTEN TO...


# ####################################################################################
# CONFIGURE NETWORK
# ####################################################################################

#Set Static IP address on eth0
#sudo nano /etc/network/interfaces
#Change “iface eth0 inet dhcp” to “iface eth0 inet static”
#ADD THE FOLLOWING
#address 192.168.1.73
#netmask 255.255.255.0
#gateway 192.168.1.1

#sudo shutdown -r now
#OF COURSE THE LAST PART WON'T WORK WHILE RUNNING THIS SCRIPT

# ####################################################################################
# CONFIGURE WIFI ACCESS POINT
# ####################################################################################

# THIS IS IN THE FUTURE, THE PARAMETERS BELOW HAVE NOT BEEN TESTED
#Setup WiFi Adapter and Wireless Access Point
#sudo apt-get install hostapd dnsmasq
#sudo nano /etc/network/interfaces
#auto wlan0, iface wlan0 inet static
#address 10.0.0.1, netmask 255.255.255.0
#sudo nano /etc/dnsmasq.conf
#interface=wlan0
#dhcp-range=10.0.0.2,10.0.0.100,12h
#sudo nano /etc/hostapd/hostapd.conf (NEW FILE)
#interface=wlan0
#driver=nl80211
#ssid=repeater
#hw_mode=g
#channel=8
#wpa=2
#wpa_passphrase=raspberry
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=CCMP
#rsn_pairwise=CCMP
#sudo nano /etc/default/hostapd.conf
#DAEMON_CONF="/etc/hostapd/hostapd.conf"

# ####################################################################################
# SETUP FILE SHARING (OPTIONAL)
# ####################################################################################

#Setup Samba (File Sharing)
#sudo apt-get install samba
#sudo nano /etc/samba/smb.conf
#Global Settings (Modify/Add) workgroup = WORKGROUP netbios name = raspberrypi Authentication (Modify) security = share Share Definitions (Add) [html_root] comment = htmlRoot path = /var/www read only = no guest ok = yes ( 2nd Share for Scripts) sudo chmod -R 777 /var/www sudo /etc/init.d/samba restart