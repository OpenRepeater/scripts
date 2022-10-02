#!/bin/bash
################################################################################
# DEFINE DUMMY SOUND CARD SETUP FUNCTIONS
################################################################################

function dummysnd_setup () {
if [ "$system_arch" == "amd64" ] || [ "$system_arch" == "X86_64" ]; then

	###########################################
    echo "------------------------------------"
    echo " Enable Dummy Sound X86/AMD64 Server"
    echo "------------------------------------"
    ###########################################
    modprobe snd-dummy

	cat >> "/etc/modules" <<- DELIM
		snd-dummy
		DELIM
    
	touch /etc/asound.conf
 
	cat >> "/etc/asound.conf" <<- DELIM
		pcm.card0 {
			type hw
			card 0 
		}
		ctl.card0 {
			type hw
			card 0
		}
		DELIM
		
		echo "Completed"
fi
}
