#!/bin/bash
################################################################################
# DEFINE SERIAL UART FUNCTIONS
################################################################################

function enable_webssh () {
        
    	#####################################################################
        echo "--------------------------------------------------------------"
        echo " Enable shellinabox WEB SSH "
        echo "--------------------------------------------------------------"
        #####################################################################
                
		cat > /etc/default/shellinabox <<- DELIM
			# Should shellinaboxd start automatically
			SHELLINABOX_DAEMON_START=1

			# TCP port that shellinboxd's webserver listens on
			SHELLINABOX_PORT=4567

			# Parameters that are managed by the system and usually should not need
			# changing:
			SHELLINABOX_DATADIR=/var/lib/shellinabox
			# SHELLINABOX_USER=orp
			# SHELLINABOX_GROUP=orp

			# Any optional arguments (e.g. extra service definitions).  Make sure
			# that that argument is quoted.
			#
			#   Beeps are disabled because of reports of the VLC plugin crashing
			#   Firefox on Linux/x86_64.
			SHELLINABOX_ARGS="--no-beep"
			DELIM
			
			#Enable service
			systemctl enable shellinabox
			
		echo "Completed"
		
}
