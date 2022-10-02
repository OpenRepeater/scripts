#!/bin/bash
################################################################################
# DEFINE MOTD FUNCTION
################################################################################

function set_motd {
	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Setting OpenRepeater Message of the Day (MOTD)"
	echo "--------------------------------------------------------------"
	#####################################################################

	# Message of the Day filename
	MOTD="/etc/motd"

	# Text Color Variables
	BLK="\033[00;30m"    # BLACK
	R="\033[00;31m"      # RED
	BR="\033[00;33m"     # BROWN
	BL="\033[00;34m"     # BLUW
	P="\033[00;35m"      # PURPLE
	LtG="\033[00;37m"    # LIGHT GRAY
	DkG="\033[01;30m"    # DARK GRAY
	LtGRN="\033[01;32m"  # LIGHT GREEN
	Y="\033[01;33m"      # YELLOW
	LtBL="\033[01;34m"   # LIGHT BLUE
	LtP="\033[01;35m"    # LIGHT PURPLE
	LtC="\033[01;36m"    # LIGHT CYAN
	W="\033[01;37m"      # WHITE
	GRN="\033[00;32m"    # GREEN
	C="\033[00;36m"      # CYAN
	LtR="\033[01;31m"    # LIGHT RED
	RESET="\033[0m"

	clear > "$MOTD"        # removes all text from /etc/motd

	echo -e $GRN"╔═══════════════════════════════════════════════════════════════════════╗" >> "$MOTD"
	echo -e "║"$W"     ____                   ____                        __             "$GRN"║" >> "$MOTD"
	echo -e "║"$W"    / __ \____  ___  ____  / __ \___  ____  ___  ____  / /____  _____  "$GRN"║" >> "$MOTD"
	echo -e "║"$W"   / / / / __ \/ _ \/ __ \/ /_/ / _ \/ __ \/ _ \/ __ \/ __/ _ \/ ___/  "$GRN"║" >> "$MOTD"
	echo -e "║"$W"  / /_/ / /_/ /  __/ / / / _, _/  __/ /_/ /  __/ /_/ / /_/  __/ /      "$GRN"║" >> "$MOTD"
	echo -e "║"$W"  \____/ ____/\___/_/ /_/_/ |_|\___/ ____/\___/\__,_/\__/\___/_/       "$GRN"║" >> "$MOTD"
	echo -e "║"$W"      /_/                         /_/                                  "$GRN"║" >> "$MOTD"                                                                                          
	echo -e "╚═══════════════════════════════════════════════════════════════════════╝" >> "$MOTD"
	echo -e "" >> "$MOTD"

	echo -e "$C""OpenRepeater is offered free of charge. Help support the project." >> "$MOTD"
	echo -e "DONATE at: https://openrepeater.com/donate" >> "$MOTD"
	echo -e "" >> "$MOTD"

	echo -e "$LtR""WARNING: Do not run updates/upgrades on this system without first making" >> "$MOTD"
	echo -e "  a backup image of your card...just in case the updates break something." >> "$MOTD"
	echo -e "" >> "$MOTD"
	echo -e "$RESET" >> "$MOTD"
	
	echo "Complete"
}
