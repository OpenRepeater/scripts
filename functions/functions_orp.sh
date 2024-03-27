#!/bin/bash
################################################################################
# DEFINE INSTALL OPENREPEATER GUI FUNCTIONS
################################################################################

function install_orp_dependancies {
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Installing OpenRepeater/SVXLink Dependencies                 "
    echo "--------------------------------------------------------------"
    #####################################################################
    apt install --assume-yes --fix-missing alsa-utils bzip2 chrony cron dialog fail2ban flite gawk \
        git gpiod gpsd gpsd-clients i2c-tools inetutils-syslogd install-info libasound2 libasound2-plugin-equal \
        libgcrypt20 libgsm1 libopus0 libpopt0 libsigc++-2.0-0v5 libsox-fmt-mp3 libxml2 libxml2-dev \
        libxslt1-dev logrotate python3-configobj python3-cheetah python3-dev python3-pip python3-usb \
        python3-serial python3-serial  screen sox sqlite3 sudo tcl8.6 time tk8.6 usbutils uuid vim \
        vorbis-tools watchdog wvdial shellinabox libhamlib-utils neofetch neovim
        
        # resolvconf removed, it causes the DNS to stop working.
        
    echo "Completed"
}

function install_orp_from_github {
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Cloning OpenRepeater files from GitHub repo                  "
    echo "--------------------------------------------------------------"
	#####################################################################
	
    rm -rf "$WWW_PATH/$GUI_NAME"/*
    git clone -b "$ORP_GUI_VERSION" --single-branch https://github.com/OpenRepeater/openrepeater.git "$WWW_PATH/$GUI_NAME"
    
    echo "Complete"
    
	 	#####################################################################
        # DEVELOPER SETUP: LINK FILES INTO PLACE FOR GITHUB SYNC
        #####################################################################
	if [ "$ORP_FILE_LOCATIONS" == "dev" ]; then

		#####################################################################
        echo "--------------------------------------------------------------"
    	echo " OpenRepeater Dev Install                                     "
    	echo "--------------------------------------------------------------"
    	#####################################################################

    	#####################################################################
    	echo "--------------------------------------------------------------"
   		echo " DEV: Create OpenRepeater Directories                         "
   		echo "--------------------------------------------------------------"
    	#####################################################################

    	mkdir -p "/etc/openrepeater"
    	mkdir -p "/var/lib/openrepeater/db"
    	mkdir -p "/etc/openrepeater/svxlink/local-events.d"

	    echo "Complete"

	    #####################################################################
    	echo "--------------------------------------------------------------"
    	echo "  DEV LINKING: Database                                       "
    	echo "--------------------------------------------------------------"
	    #####################################################################

        ln -sf "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"

	    echo "Complete"
      
        #####################################################################
	    echo "--------------------------------------------------------------"
		echo " DEV LINKING: ORP Sounds (Courtesy Tones / Sample IDs)        "
		echo "--------------------------------------------------------------"
    	#####################################################################

        ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "$WWW_PATH/$GUI_NAME/sounds"
        ln -s "$WWW_PATH/$GUI_NAME/install/sounds" "/var/lib/openrepeater/sounds"

	    echo "Complete"
	           
        #####################################################################
	    echo "--------------------------------------------------------------"
	    echo " DEV LINKING: ORP Helper Bash Script                          "
	    echo "--------------------------------------------------------------"
	    #####################################################################
  
        ln -s "$WWW_PATH/$GUI_NAME/install/scripts/orp_helper" "/usr/sbin/orp_helper"

        echo "Complete"
              
        #####################################################################
	    echo "--------------------------------------------------------------"
	    echo " DEV LINKING: Link ORP into SVXLink directories               "
	    echo "--------------------------------------------------------------"
	    #####################################################################
    
        ln -s "/etc/svxlink" "/etc/openrepeater/svxlink"

        echo "Complete"

        #####################################################################
	    echo "--------------------------------------------------------------"
	    echo " DEV LINKING: Link ORP to SVXLink log                           "
	    echo "--------------------------------------------------------------"
	    ##################################################################### 
    
        ln -s "/var/log/svxlink" "/var/www/openrepeater/log"

        echo "Complete"       
        
        #####################################################################
	    echo "--------------------------------------------------------------"
	    echo " DEV LINKING: Dev Test Folder                           "
	    echo "--------------------------------------------------------------"
	    #####################################################################

        ln -s "$WWW_PATH/$GUI_NAME/install/dev" "$WWW_PATH/$GUI_NAME/dev"

        echo "Complete"        

	else
        #######################################################################
        # NORMAL SETUP: PLACE FILES WHERE THEY SHOULD BE 
        #######################################################################
        echo "--------------------------------------------------------------"
    	echo " OpenRepeater Default Install "
    	echo "--------------------------------------------------------------"
        #####################################################################  
        
        #####################################################################
    	echo "--------------------------------------------------------------"
    	echo " Create OpenRepeater Directories                             "
    	echo "--------------------------------------------------------------"
    	#####################################################################      
    	
    	mkdir -p "/etc/openrepeater"
    	mkdir -p "/var/lib/openrepeater/db"
    	mkdir -p "/etc/openrepeater/svxlink/local-events.d"
    	
    	echo "Complete"
    	
		#####################################################################
	    echo "--------------------------------------------------------------"
	    echo " Copy OpenRepeater Database INto Place                        "
	    echo "--------------------------------------------------------------"
	    #####################################################################
	    
        mv "$WWW_PATH/$GUI_NAME/install/sql/openrepeater.db" "/var/lib/openrepeater/db/openrepeater.db"

    	echo "Complete"
    	        
		#####################################################################
 		echo "--------------------------------------------------------------"
  		echo "  MOVE/LINK: ORP Sounds (Courtesy Tones / Sample IDs)         "
    	echo "--------------------------------------------------------------"
    	#####################################################################

        mv "$WWW_PATH/$GUI_NAME/install/sounds" "/var/lib/openrepeater/sounds"
        ln -s "/var/lib/openrepeater/sounds" "$WWW_PATH/$GUI_NAME/sounds"
        
    	echo "Complete"

		#####################################################################  	        
	    echo "--------------------------------------------------------------"
	    echo " Install ORP Helper Bash Script                               "
	    echo "--------------------------------------------------------------"
	    #####################################################################

        cp "$WWW_PATH/$GUI_NAME/install/scripts/orp_helper" "/usr/sbin/orp_helper"
        
    	echo "Complete"
        
        #####################################################################  	        
	    echo "--------------------------------------------------------------"
	    echo " Install boards_driver_loader Script                               "
	    echo "--------------------------------------------------------------"
	    #####################################################################

        cp "$WWW_PATH/$GUI_NAME"/install/scripts/board_drivers_loader "/usr/sbin/board_drivers_loader"
        
    	echo "Complete"
        
        
		#####################################################################
    	echo "--------------------------------------------------------------"
    	echo " LINKING: Link ORP into SVXLink directories                   "
    	echo "--------------------------------------------------------------"
    	#####################################################################
 
        ln -s "/etc/svxlink" "/etc/openrepeater/svxlink"

        echo "Complete"

		#####################################################################
    	echo "--------------------------------------------------------------"
    	echo " LINKING: Link ORP to SVXLink log                           "
    	echo "--------------------------------------------------------------"
    	#####################################################################        

        ln -s "/var/log/svxlink" "/var/www/openrepeater/log"

        echo "Complete"

        #####################################################################
    	echo "--------------------------------------------------------------"
    	echo " Cleanup Unused files/folders OpenRepeater Web                "
    	echo "--------------------------------------------------------------"
    	#####################################################################

        rm -rf "$WWW_PATH/$GUI_NAME/debian"
        rm -rf "$WWW_PATH/$GUI_NAME/install"
        rm "$WWW_PATH/$GUI_NAME/README.md"
        rm -rf "$WWW_PATH/$GUI_NAME/dev"
        rm -rf  "$WWW_PATH/$GUI_NAME/.git*"

        echo "Complete"
	fi

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " FIX PERMISSIONS/OWNERSHIP WWW Dir                            "
    echo "--------------------------------------------------------------"
    #####################################################################

    chown -R www-data:www-data "$WWW_PATH/$GUI_NAME"
    chown -R www-data:www-data "/etc/openrepeater"
    chown -R www-data:www-data "/etc/svxlink"
    chown -R www-data:www-data "/usr/share/svxlink/events.d/"
    chown -R www-data:www-data "/usr/share/svxlink/modules.d/"
    chown -R www-data:www-data "/usr/share/svxlink/sounds/"
    chown -R www-data:www-data "/var/lib/openrepeater/"
    chmod -R 777 "/var/lib/openrepeater/"

	echo "Completed"
	  
 	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Reset database...just in case it contains callsign info.     "
    echo "--------------------------------------------------------------"
    #####################################################################   

    sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE settings SET value='' WHERE keyID='callSign'"
    sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE modules SET moduleEnabled='0', moduleOptions='' WHERE svxlinkName='EchoLink'"
  
    echo "Completed"
}

function modify_www-data {
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Setting up sudoers permissions for OpenRepeater              "
    echo "--------------------------------------------------------------"
    #####################################################################
    cat >> "/etc/sudoers" <<- DELIM
			#####################################################################
			# OPENREPEATER: allow www-data to access orp_helper
			#####################################################################
			www-data    ALL=(ALL) NOPASSWD: /usr/sbin/orp_helper
			DELIM
			
	echo "Completed"
}

function update_versioning {
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Setting ORP Build Version                                    "
    echo "--------------------------------------------------------------"
    #####################################################################
    
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Update OpenRepeater Gui version in database                  "
    echo "--------------------------------------------------------------"
    #####################################################################

    sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE version_info SET version_num='$ORP_VERSION'"
    
    echo "Completed"
}
