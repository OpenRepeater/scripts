#!/bin/bash

################################################################################
# DEFINE FUNCTIONS
################################################################################


function set_ics_asound {
	cat >> "/etc/asound.conf" <<- DELIM
		pcm.dmixed {
			type dmix
			ipc_key 1024
			ipc_key_add_uid 0
			slave.pcm "hw:0,0"
		}
		pcm.dsnooped {
			type dsnoop
			ipc_key 1025
			slave.pcm "hw:0,0"
		}
		pcm.duplex {
			type asym
			playback.pcm "dmixed"
			capture.pcm "dsnooped"
		}
		pcm.left {
			type asym
			playback.pcm "shared_left"
			capture.pcm "dsnooped"
		}
		pcm.right {
			type asym
			playback.pcm "shared_right"
			capture.pcm "dsnooped"
		}
		# Instruct ALSA to use pcm.duplex as the default device
		pcm.!default {
			type plug
			slave.pcm "duplex"
		}
		ctl.!default {
			type hw
			card 0
		}
		# split left channel off
		pcm.shared_left {
			type plug
			slave.pcm "hw:0"
			slave.channels 2
			ttable.0.0 1
		}
		# split right channel off
		pcm.shared_right {
			type plug
			slave.pcm "hw:0"
			slave.channels 2
			ttable.1.1 1
		}
		#dtparam=i2s=on
		Pcm_slave.hw_loopback {
			Pcm "hw: loopback, 1.2"
			Channels 2
			Format RAW
			Rate 16000
		}
		Pcm.plug_loopback {
			Type plug
			Slave hw_loopback
			Ttable {
				0.0 = 1
				0.1 = 1
			}
		}
		Ctl. Equal  {
			type equal ;
			Controls "/home/pi/.alsaequal.bin"
		}
	DELIM
}