#!/bin/bash
# Part of raspi-openrepeater-config http://github.com//raspi-openrepeater-config
#
# See LICENSE file for copyright and license details
################################################################################
set -eu
##############################################################
# Disacle CTL C (Disable CTL-C so you can not escape the menu)
##############################################################
trap "" SIGTSTP
trap "" 2 20

#########################
# Reassign ctl+d to ctl+_
#########################
stty eof  '^_'

################################################################################

INTERACTIVE=True
ASK_TO_REBOOT=0
BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
CONFIG=/boot/config.txt

get_init_sys() {
  if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
    SYSTEMD=1
  elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
    SYSTEMD=0
  else
    echo "Unrecognised init system"
    return 1
  fi
}

calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

################################################################################
do_VALIDATEIP () {
CONTINUE=N
if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
then
# Then the format looks right - check that each octect is less
# than or equal to 255:
	VALID_IP_ADDRESS="$(echo "$IP_ADDRESS" | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
	if [ -z "$VALID_IP_ADDRESS" ]
	then
		echo "The IP address wasn't valid; octets must be less than 256"
		echo -n "Please start over, press any key to continue"
	else
		CONTINUE=Y
		echo -n "Press any key to continue"
	fi
else
	echo "The IP address was malformed"
	echo -n "Please start over, press any key to continue"
fi
}

############################################
# Configure network interface
############################################
do_set_interface(){
read -r -p "Are you sure you wish to configure $device interface ? (y/Y/n/N)"
if [[ $REPLY =~ ^[N/n]$ ]];
then
	exit 0
else
	if [[ $REPLY =~ ^[Yy]$ ]];
	then
		read -r -p 'Please enter the IP address you wish to assign to the PBX (eg. 10.x.x.x/172.x.x.x/192.168.x.x) : ' ip
		IP_ADDRESS=$ip
		VALIDATEIP
		IP_ADDRESS=null
	fi

	if [ "$CONTINUE" = "Y" ]
	then
		read -r -p 'Please enter the subnet mask for the network (eg. 255.x.x.x) : ' nm
		IP_ADDRESS=$nm
		VALIDATEIP
		IP_ADDRESS=null
	fi

	if [ "$CONTINUE" = "Y" ]
	then
		read -r -p 'Please enter the gateway IP for the network (eg. 10.x.x.x/172.x.x.x/192.168.x.x ) : ' gw
		IP_ADDRESS=$gw
		VALIDATEIP
		IP_ADDRESS=null
	fi

	if [ "$CONTINUE" = "Y" ]
	then
		CHECK1="$(echo "$IP" | cut -d '.' -f1,2,3)"
		CHECK2="$(echo "$GW" | cut -d '.' -f1,2,3)"
		if [ "$CHECK1" != "$CHECK2" ]; then
  		echo -n "IP subnet and gateway subnet do not match, please start over. Press any key to continue"
			read -r null
		else
			echo "Your system will be programmed as IP=$IP , Subnet = $NM and Gateway = $GW, "
			echo -n "Press 1 if this is correct? Press 2 to go back to menu : "
			read -r YN1
			if [ "$YN1" = "1" ]
				then
					echo
					echo -n "If this is correct press 1 to commit changes. Or press 2 to cancel and go back to the main menu : "
					read -r CHANGE
			else
				CHANGE=2
			fi

			if [ "$CHANGE" -eq "1" ]
			then
				cat > /etc/network/interfaces.d/eth0 << DELIM
				###############################
				# The primary network interface
				###############################
				auto "$device"
				allow-hotplus
				iface "$device" inet static
				address "$ip"
				netmask "$nm"
				gateway "$gw"
DELIM
			fi
		fi
	fi
fi
}

do_set_hosts(){
if [ "$CONTINUE" = "Y" ]
then
######################
# Configure hostename
######################
read -r -p 'Please set your system hostname (callsign):' hn
#Configure domain
read -r -p 'Please set your system domainname (mydomain.com):' dn
read -r -p 'Please ReEnter the ip you set for  eth0/wan interface (eg. 10.0.0.5) : ' ip
IP_ADDRESS=$ip
VALIDATEIP
IP_ADDRESS=null
fi

cat > /etc/hosts << DELIM
127.0.0.1       localhost 
127.0.0.1       $hn-repeater
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
$ip     $hn-repeater.$dn $hn
DELIM

cat > /etc/hostname << DELIM
$hn-repeater
DELIM
}

######################
# Set system hostname
###################### 
do_change_hostname() {
  whiptail --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive), 
the digits '0' through '9', and the hyphen.
Hostname labels cannot begin or end with a hyphen. 
No other symbols, punctuation characters, or blank spaces are permitted.\
" 20 70 1

  CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
  NEW_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    ASK_TO_REBOOT=1
  fi
}

############################
# Configure /etc/resolv.conf
############################
do_set_resolv(){
if [ "$CONTINUE" = "Y" ]
then
read -r -p 'Please enter the host/provider domain  (eg. att.com) : ' dmn
echo "$dmn"
read -r -p 'Please enter the host/provider search domain (eg. att.com) : ' srch
echo "$srch" 
read -r -p 'Please enter the primary domain name server ip (eg. 4.2.2.2) : ' ns1
echo "$ns1"
read -r -p 'Please enter the secondary domain name server ip (eg. 4.2.2.3) : ' ns2
echo "$ns2"
fi

cat > /etc/resolv.conf << DELIM
domain "$dmn"
search "$srch"
nameserver "$ns1"
nameserver "$ns2"
DELIM
}


###################################
# Wireless Security (future Option)
###################################
do_wireless_security(){
while : ;do
#configuring wpa security
read -r -p "Please set your wireless network Security System ID (SSID) : " MYSSID
read -r -p "Please set your wireless network key management key type (WPA_PSK) : "KMGMT
read -r -p "Please enter your wireless security password/phrase : " PHRASE

cat << DELIM
 Here is the wifi security information you entered :

 "$MYSSID"
 "$KMGMT"
 "$PHRASE"

DELIM
read -rp "Is this information correct and ready to apply it to the system ? (y/Y/n/N)"; 
case "$REPLY" in 
n|N) echo 'Please start over';  break;; 
y|Y)
cat >> /etc/network/interfaces << DELIM
	wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
DELIM

cat > /etc/wpa_supplicant/wpa_supplicant.conf << DELIM
network={
        ssid="$MYSSID"
        scan_ssid=1
        key_mgmt="$KMGMT"
        psk="$PHRASE"
}
DELIM
esac ;
done
}

##########################
# Configure Wan Interface
##########################
do_set_wan(){
device=eth0
do_set_interface
do_set_resolv
}

###############################
# Configure Wireless Interface
###############################
do_set_wlan(){
device=eth0
do_set_interface
do_set_resolv
}

do_net_default() {
#################
#Reset Hosts file
#################
echo 'resetting hosts file'
cat > /etc/hosts << DELIM
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
DELIM

################
#Reset hostname 
################
echo 'resetting hostname to default'
cat > /etc/hostname << DELIM
Set-This-Repeater
DELIM

#################
#Reset interfaces
#################
echo "Resetting /etc/network/interfaces"
cat > /etc/network/interfaces << DELIM
auto lo

iface lo inet loopback
iface eth0 inet dhcp

DELIM
}

#######################################
# Restore svxlink default config files
#######################################
do_svxlink_default() {
rm -rf /etc/svxlink/*
cp -rp /usr/share/examples/svxlink/conf/svxlink/* /etc/svxlink
}

##############################
# French Sounds Install Option
##############################
do_svxlink_fr_sounds() {
wget https://www.dropbox.com/s/uho1lryuk8fj43c/svxlink_13.99_armhf_avec_sons8kfr.deb
dpkg -i svxlink_13.99_armhf_avec_sons8kfr.deb
rm svxlink_13.99_armhf_avec_sons8kfr.deb
}

####################
# Rotate/Clean logs
####################
do_rotate_logs(){
cat << DELIM
 This will halt the running services and sync the system rotate the logs
 and then restart the services for the Repeater system.
DELIM
while : ;do
read -r -p "Are you sure you wish to rotate you system and svxlink logs? (y/Y/n/N)"
case "$REPLY" in
n|N) break ;;
y|Y)

#######################
# stop system services
######################
for i in monit svxlink
do service "${i}" stop 
done

for i in inetutils-syslogd
do service "${i}" start
done

logrotate -f /etc/logrotate.conf
for i in *.0 *.1 *.gz */*
do rm -f /var/log/"${i}"
done

for i in fail2ban inetutils-syslogd
do service "${i}" stop
done

##################
#restart services
##################
for i in svxlink monit
do service "${i}" start
done
break ;;

*) echo "Answer must be a y/Y or n/N" ;;
esac
done
}

#######################
# Disable Root via ssh
#######################
do_root_ssh() {
read -r -p "Are you sure you wish to enable/disable ssh root login e/E=enable d/D=disable (e/E/d/D) "
if [[ $REPLY =~ ^[Dd]$ ]];
then
	sed -i /etc/ssh/sshd_config -e s,'^#PermitRootLogin no','PermitRootLogin no',
else
	if [[ $REPLY =~ ^[Ee]$ ]]; 
	then
		sed -i /etc/ssh/sshd_config -e s,'^PermitRootLogin no','#PermitRootLogin no',
	fi
fi
}

##########################
#Install personal ssh key
##########################
do_ssh_keys() {
read -r -p "Are you sure you wish to add/remove ssh key for root login a/A=add r/R=dremove (a/A/r/R) "
if [[ $REPLY =~ ^[Aa]$ ]]; then
	read -r -p "Please paste the ssh key you wish to add here and hit enter:" key
	cat >> /root/.ssh/authorized_keys << DELIM
	$key
DELIM
	else
	if [[ $REPLY =~ ^[Rr]$ ]]; then
		read -r -p "Please paste the ssh key you wish to remove here and hit enter:" key1
		sed -i /root/.ssh/authorized_keys -e s,"^$key1",'',
	fi
fi
}

########################
# Disable ssh
########################
do_ssh_service() {
  if [ -e /var/log/regen_ssh_keys.log ] && ! grep -q "^finished" /var/log/regen_ssh_keys.log; then
    whiptail --msgbox "Initial ssh key generation still running. Please wait and try again." 20 60 2
    return 1
  fi
  whiptail --yesno "Would you like the SSH server enabled or disabled?" 20 60 2 \
    --yes-button Enable --no-button Disable
  RET=$?
  if [ $RET -eq 0 ]; then
    update-rc.d ssh enable &&
    service ssh start &&
    whiptail --msgbox "SSH server enabled & started" 20 60 1
  elif [ $RET -eq 1 ]; then
    update-rc.d ssh disable &&
    service ssh stop &&
    whiptail --msgbox "SSH server disabled & stopped" 20 60 1
  else
    return $RET
  fi
}

###################
# Set user passwd
###################
do_set_pwd() {
  whiptail --msgbox "You will now be asked to enter a new password for the pi user" 20 60 1
  passwd pi &&
  whiptail --msgbox "Password changed successfully" 20 60 1
}

###################
# Set Root passwd
###################
do_set_pwd_root() {
  whiptail --msgbox "You will now be asked to enter a new password for the root user" 20 60 1
  passwd &&
  whiptail --msgbox "Password changed successfully" 20 60 1
}

###########################
# Configure keyboard Layout
###########################
do_configure_keyboard() {
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  service keyboard-setup start || return $?
  udevadm trigger --subsystem-match=input --action=change
  return 0
}

########################
# Configue system locale
########################
do_change_locale() {
  dpkg-reconfigure locales
}

###########################
# Configure Local TimeZone
###########################
do_change_timezone() {
  dpkg-reconfigure tzdata
}

###################
# Update this Menu 
###################
do_update() {
  apt-get update &&
  apt-get install odroid-openrepeater-config &&
  printf "Sleeping 5 seconds before reloading odroid-openrepeater-config\n" &&
  sleep 5 &&
  exec odroid-openrepeater-config
}

#######################
# Reboot after Changes
#######################
do_finish() {
  disable_raspi_config_at_boot
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}

# $1 = filename, $2 = key name
get_json_string_val() {
  sed -n -e "s/^[[:space:]]*\"$2\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*,$/\1/p" $1
}

##################
# Info About Menu
##################
do_about() {
  whiptail --msgbox "\
This tool provides a straight-forward way of doing initial
configuration of the Odroid/Svxlink Repeater. This is 
a always on Shell menu that will display everytime you login 
as the root user. I will make it a option for it to display 
for other users inthe future. \
" 20 70 1
}

##################
# NTP with gps
##################
do_ntpd_gpsd() {
#install gpsd and gpsd-clients
apt-get install gpsd gpsd-clients

################################
# Back up the origianl ntp.conf
################################
cp /etc/ntp.conf /etc/ntp.conf.orig

#######################################
# Configure nptd to use gps/npt servers
# for getting and setting time
########################################
cat > /etc/ntp.conf << DELIM
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help
driftfile       /var/lib/ntp/ntp.drift
# Enable this if you want statistics to be logged.
# statsdir /var/log/ntpstats/
statistics      loopstats       peerstats       clockstats
filegen loopstats       file    loopstats       type    day     enable
filegen peerstats       file    peerstats       type    day     enable
filegen clockstats      file    clockstats      type    day     enable
# Access control configuration; see /usr/share/doc/ntp-doc/html/accopt.html for
# details.  The web page <http://support.ntp.org/bin/view/Support/AccessRestrictions>
# might also be helpful.
#
# Note that "restrict" applies to both servers and clients, so a configuration
# that might be intended to block requests from certain clients could also end
# up blocking replies from your own upstream servers.
# By default, exchange time with everybody, but don't allow configuration.
restrict        -4      default kod     notrap  nomodify        nopeer  noquery
restrict        -6      default kod     notrap  nomodify        nopeer  noquery
restrict        127.0.0.1 # Local users may interrogate the ntp server more closely.
restrict        ::1
# Read the rough GPS time from device 127.127.28.0
# Read the accurate PPS time from device 127.127.28.1
server 127.127.28.0 minpoll 4 maxpoll 4
fudge 127.127.28.0 time1 0.535 refid GPS
server 127.127.28.1 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.1 refid PPS
# Use servers from the ntp pool for the first synchronization,
# or as a backup if the GPS is disconnected
server	0.pool.ntp.org
server  1.pool.ntp.org
server  2.pool.ntp.org
server  3.pool.ntp.org
DELIM

#################################
#Configure gpsd to setup the gps
#################################
#back up the orig default conf file
cp /etc/default/gpsd .etc/default/gpsd.orig

#cp new /etc/default/gpsd config into place
cat > /etc/default/gpsd << DELIM
# Default settings for the gpsd init script and the hotplug wrapper.

# Start the gpsd daemon automatically at boot time
START_DAEMON="true"

# Use USB hotplugging to add new USB devices automatically to the daemon
USBAUTO="true"

# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES=""

# Other options you want to pass to gpsd
GPSD_OPTIONS=""

DELIM
}

###############
# Password Menu
###############
do_passwd_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Password Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "PWD1 Change User Password" "Change password for the default user (odroid)" \
    "PWD2 Change User Password" "Change password for the default user (root)" \    
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      PWD1\ *) do_set_pwd;;
      PWD2\ *) do_set_pwd_root ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###################
# overclocking menu
###################
do_overclock_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Overclock Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "OC1 OverClocking" "Overclock the cpu for performance" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      OC1\ *) do_overclock ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

#########################
# web server Options menu
#########################
do_web_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Web Services Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "W1 Start Web " "Start Web Services"\
    "W2 Stop Web" "Stop Web Services" \
    "W2 Restart Web" "Restart Web Services" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      W1\ *) service nginx start; service php5-fpm start ;;
      W2\ *) service nginx stop; service php5-fpm stop ;;
      W3\ *) service nginx restart; service php5-fpm restart ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###########################
# Internationalisation menu
###########################
do_internationalisation_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Internationalisation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "I1 Change Locale" "Set up language and regional settings to match your location" \
    "I2 Change Timezone" "Set up timezone to match your location" \
    "I3 Change Keyboard Layout" "Set the keyboard layout to match your keyboard" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      I1\ *) do_change_locale ;;
      I2\ *) do_change_timezone ;;
      I3\ *) do_configure_keyboard ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

############################
# Network Configuration Menu
############################
do_networking_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Networking Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "N1 Configure Host" "Set Host Name for network" \
    "N2 Configure wan" "Configure wide area networking eth0/wan interface" \
    "N3 Configure wlan" "Configure wireless networking wlan0/wlan interface" \
    "N4 Wlan Security" "Set up basic wireless security ssid/passwd" \
    "N5 Network Reset" "Set netwoking interface back to defaults" \
    "N6 SSH Menu" "SSH Enable/Disable Service / Disable Root / Add/remove Keys" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      N1\ *) do_change_hostname ;;
      N2\ *) do_set_wan ;;
      N3\ *) do_set_wlan ;;
      N4\ *) do_wirless_security ;;
      N5\ *) do_net_default ;;
      N6\ *) do_ssh_menu ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

##############################
# SSH Menu enable/disable/keys
##############################
do_ssh_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "SSH Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "SSH1 SSH" "Start & Stop ssh service" \
    "SSH2 SSH" "Enable & Disable ssh root" \
    "SSH3 SSH" "Add & Remove ssh keys for access" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      SSH1\ *) do_ssh_service ;;
      SSS2\ *) do_ssh_root ;;
      SSH3\ *) do_ssh_keys ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###########################
# Power Options menu
###########################
do_power_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Networking Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "P1 Reboot " "Reboot System"\
    "P2 Power Off" "Power Off System" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      P1\ *) reboot; kill -HUP "$(pgrep -s 0 -o)";;
      P2\ *) poweroff; kill -HUP "$(pgrep -s 0 -o)";;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###########################
# OpenRepeater Menus 
###########################

do_openrepeater_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "OpenRepeater Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "OR1 OpenRepeater Basic" "OpenRepeater Basic Options Menu" \
    "OR2 OpenRepeater Advanced" "OpenRepeater Advanced Options Menu" \
    "OR3 OpenRepeater Hat" "Enable/Disable the OpenRepeater Hat" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      OR1\ *) do_openrepeater_basic_menu ;;
      OR2\ *) do_openrepeater_advanced_menu ;;
      OR3\ *) do_hats_menu ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

do_openrepeater_basic_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "OpenRepeater Basic Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "ORB1 Start SvxLink" "Start svxlink via systemd service" \
    "ORB2 Stop SvxLink" "Stop svxlink via systemd service" \
    "ORB3 Start SvxLink" "Restart svxlink via systemd service" \
    "ORB4 Reload SvxLink" "restart svxlink via systemd service" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      ORB1\ *) service svxlink start ;;
      ORB2\ *) service svxlink stop ;;
      ORB3\ *) service svxlink try-restart ;;
      ORB4\ *) service svxlink force-reload ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

do_openrepeater_advanced_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "OpenRepeater Advanced Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "ORA1 Reset svxlink" "Reset svxlink/openreater config files back default" \
    "ORA2 French FR Sounds" "Install French FR Sounds for SvxLink" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      ORA1\ *) do_svxlink_default ;;
      ORA2\ *) do_svxlink_fr_sounds ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###########################
# Advanced system options
###########################
do_advanced_menu() {
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Advanced Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "A1 Overclock Menu " "Overclocking for your Pi" \
    "A2 Update" "Update this tool to the latest version" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      A1\ *) do_overclock_menu ;;
      A2\ *) do_update ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###########################
#Main Menu
###########################
get_init_sys
calc_wt_size
while true; do
  FUN=$(whiptail --title "Odroid OpenRepeater Configuration Tool" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Internationalisation Options" "Set up language and regional settings to match your location" \
    "2 Networking" "Configure Network Ineterface WAN/WLAN/Wireless Security" \
    "3 OpenRepeater Options" "Configure OpenRepeater settings" \
    "4 Advanced Options" "Configure advanced settings" \
    "5 Web Options" "Start/Stop/Restart Nginx/php5-fpm" \
    "6 Power Options" "PowerOff/Reboot system" \
    "7 Drop To Shell" "Drop to system command shell Bash" \
    "8 Logout of terminal" "Logout Of System & Clear Terminal Session" \
    "9 Repeater Boards" "How to enable the repeater boardson the pi-2 "\
    "10 About Menu" "Information about this configuration tool" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_internationalisation_menu ;;
      2\ *) do_networking_menu ;;
      3\ *) do_openrepeater_menu ;;
      4\ *) do_advanced_menu ;;
      5\ *) do_web_menu ;;
      6\ *) do_power_menu ;;
      7\ *) /bin/bash ;;
      8\ *) clear; kill -HUP "$(pgrep -s 0 -o)";;
      9\ *) do_repeater_hats ;;
      10\ *) do_about ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done
