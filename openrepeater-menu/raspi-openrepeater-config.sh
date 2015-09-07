#!/bin/bash
###############################################################################
do_license() {
cat << DELIM
################################################################################
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.
#
#    If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>
#
################################################################################
DELIM
}

####################
# Set error watch
###################
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
  WT_MENU_HEIGHT=$((WT_HEIGHT-7))
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
				cat > /etc/network/interfaces<< DELIM
				###############################
				# The primary network interface
				###############################
				auto lo "$device"
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
auto lo eth0

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

service inetutils-syslogd start

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

########################
# Expand File System
########################
do_expand_rootfs() {
  if [ $SYSTEMD -eq 1 ]; then
    ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
  else
    if ! [ -h /dev/root ]; then
      whiptail --msgbox "/dev/root does not exist or is not a symlink. Don't know how to expand" 20 60 2
      return 0
    fi
    ROOT_PART=$(readlink /dev/root)
  fi

  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    whiptail --msgbox "$ROOT_PART is not an SD card. Don't know how to expand" 20 60 2
    return 0
  fi

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only 
  # agree to work with a sufficiently simple partition layout
  if [ "$PART_NUM" -ne 2 ]; then
    whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
    return 0
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ "$LAST_PART_NUM" -ne "$PART_NUM" ]; then
    whiptail --msgbox "$ROOT_PART is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF
  ASK_TO_REBOOT=1

  # now set up an init.d script
cat <<EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/$ROOT_PART &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&
  if [ "$INTERACTIVE" = True ]; then
    whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
  fi
}

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  local val = line:match("^#?%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    break
  end
end
EOF
}

# $1 is 0 to disable overscan, 1 to disable it
set_overscan() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi

  [ -e $CONFIG ] || touch $CONFIG

  if [ "$1" -eq 0 ]; then # disable overscan
    sed $CONFIG -i -e "s/^overscan_/#overscan_/"
    set_config_var disable_overscan 1 $CONFIG
  else # enable overscan
    set_config_var disable_overscan 0 $CONFIG
  fi
}

###########################
# Configure video overscan
###########################
do_overscan() {
  whiptail --yesno "What would you like to do with overscan" 20 60 2 \
    --yes-button Disable --no-button Enable
  RET=$?
  if [ $RET -eq 0 ] || [ $RET -eq 1 ]; then
    ASK_TO_REBOOT=1
    set_overscan $RET;
  else
    return 1
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

  CURRENT_HOSTNAME=$(hostname | tr -d " \t\n\r")
  NEW_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    echo "$NEW_HOSTNAME" > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    ASK_TO_REBOOT=1
  fi
}

########################
# Split mem for gpu/cpu 
########################
do_memory_split() { # Memory Split
  if [ -e /boot/start_cd.elf ]; then
    # New-style memory split setting
    if ! mountpoint -q /boot; then
      return 1
    fi
    ## get current memory split from /boot/config.txt
    CUR_GPU_MEM=$(get_config_var gpu_mem $CONFIG)
    [ -z "$CUR_GPU_MEM" ] && CUR_GPU_MEM=64
    ## ask users what gpu_mem they want
    NEW_GPU_MEM=$(whiptail --inputbox "How much memory should the GPU have?  e.g. 16/32/64/128/256" \
      20 70 -- "$CUR_GPU_MEM" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
      set_config_var gpu_mem "$NEW_GPU_MEM" $CONFIG
      ASK_TO_REBOOT=1
    fi
  else # Old firmware so do start.elf renaming
    get_current_memory_split
    MEMSPLIT=$(whiptail --menu "Set memory split.\n$MEMSPLIT_DESCRIPTION" 20 60 10 \
      "240" "240MiB for ARM, 16MiB for VideoCore" \
      "224" "224MiB for ARM, 32MiB for VideoCore" \
      "192" "192MiB for ARM, 64MiB for VideoCore" \
      "128" "128MiB for ARM, 128MiB for VideoCore" \
      3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
      set_memory_split "${MEMSPLIT}"
      ASK_TO_REBOOT=1
    fi
  fi
}

get_current_memory_split() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi
  AVAILABLE_SPLITS="128 192 224 240"
  MEMSPLIT_DESCRIPTION=""
  for SPLIT in $AVAILABLE_SPLITS;do
    if [ -e /boot/arm"${SPLIT}"_start.elf ] && cmp /boot/arm"${SPLIT}"_start.elf /boot/start.elf >/dev/null 2>&1;then
      CURRENT_MEMSPLIT=$SPLIT
      MEMSPLIT_DESCRIPTION="Current: ${CURRENT_MEMSPLIT}MiB for ARM, $((256 - CURRENT_MEMSPLIT))MiB for VideoCore"
      break
    fi
  done
}

set_memory_split() {
  cp -a /boot/arm"${1}"_start.elf /boot/start.elf
  sync
}

#############################
# Over clock Board cpu speed
#############################
do_overclock() {
  whiptail --msgbox "\
Be aware that overclocking may reduce the lifetime of your
Raspberry Pi. If overclocking at a certain level causes
system instability, try a more modest overclock. Hold down
shift during boot to temporarily disable overclock.
See http://elinux.org/RPi_Overclocking for more information.\
" 20 70 1
  OVERCLOCK=$(whiptail --menu "Chose overclock preset" 20 60 10 \
    "None" "700MHz ARM, 250MHz core, 400MHz SDRAM, 0 overvolt" \
    "Modest" "800MHz ARM, 250MHz core, 400MHz SDRAM, 0 overvolt" \
    "Medium" "900MHz ARM, 250MHz core, 450MHz SDRAM, 2 overvolt" \
    "High" "950MHz ARM, 250MHz core, 450MHz SDRAM, 6 overvolt" \
    "Turbo" "1000MHz ARM, 500MHz core, 600MHz SDRAM, 6 overvolt" \
    "Pi2" "1000MHz ARM, 500MHz core, 500MHz SDRAM, 2 overvolt" \
    3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    case "$OVERCLOCK" in
      None)
        set_overclock None 700 250 400 0
        ;;
      Modest)
        set_overclock Modest 800 250 400 0
        ;;
      Medium)
        set_overclock Medium 900 250 450 2
        ;;
      High)
        set_overclock High 950 250 450 6
        ;;
      Turbo)
        set_overclock Turbo 1000 500 600 6
        ;;
      Pi2)
        set_overclock Pi2 1000 500 500 2
        ;;
      *)
        whiptail --msgbox "Programmer error, unrecognised overclock preset" 20 60 2
        return 1
        ;;
    esac
    ASK_TO_REBOOT=1
  fi
}

set_overclock() {
  set_config_var arm_freq "$2" $CONFIG &&
  set_config_var core_freq "$3" $CONFIG &&
  set_config_var sdram_freq "$4" $CONFIG &&
  set_config_var over_voltage "$5" $CONFIG &&
  whiptail --msgbox "Set overclock to preset '$1'" 20 60 2
}

###############################
#Set System to use device tree
###############################
do_devicetree() {
  CURRENT_SETTING="enabled" # assume not disabled
  DEFAULT=
  if [ -e $CONFIG ] && grep -q "^device_tree=$" $CONFIG; then
    CURRENT_SETTING="disabled"
    DEFAULT=--defaultno
  fi

  whiptail --yesno "Would you like the kernel to use Device Tree?" $DEFAULT 20 60 2
  RET=$?
  if [ $RET -eq 0 ]; then
    sed $CONFIG -i -e "s/^\(device_tree=\)$/#\1/"
    sed $CONFIG -i -e "s/^#\(device_tree=.\)/\1/"
    SETTING=enabled
  elif [ $RET -eq 1 ]; then
    sed $CONFIG -i -e "s/^#\(device_tree=\)$/\1/"
    sed $CONFIG -i -e "s/^\(device_tree=.\)/#\1/"
    if ! grep -q "^device_tree=$" $CONFIG; then
      printf "device_tree=\n" >> $CONFIG
    fi
    SETTING=disabled
  else
    return 0
  fi
  TENSE=is
  REBOOT=
  if [ $SETTING != $CURRENT_SETTING ]; then
    TENSE="will be"
    REBOOT=" after a reboot"
    ASK_TO_REBOOT=1
  fi
  whiptail --msgbox "Device Tree $TENSE $SETTING$REBOOT" 20 60 1
}

########################
# Enable/Disable spi
# Disabled By Default
########################
do_spi() {
  DEVICE_TREE="yes" # assume not disabled
  DEFAULT=
  if [ -e $CONFIG ] && grep -q "^device_tree=$" $CONFIG; then
    DEVICE_TREE="no"
  fi

  CURRENT_SETTING="off" # assume disabled
  DEFAULT=--defaultno
  if [ -e $CONFIG ] && grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*spi(=(on|true|yes|1))?(,.*)?$" $CONFIG; then
    CURRENT_SETTING="on"
    DEFAULT=
  fi

  if [ $DEVICE_TREE = "yes" ]; then
    whiptail --yesno "Would you like the SPI interface to be enabled?" $DEFAULT 20 60 2
    RET=$?
    if [ $RET -eq 0 ]; then
      SETTING=on
      STATUS=enabled
    elif [ $RET -eq 1 ]; then
      SETTING=off
      STATUS=disabled
    else
      return 0
    fi
    TENSE=is
    REBOOT=
    if [ $SETTING != $CURRENT_SETTING ]; then
      TENSE="will be"
      REBOOT=" after a reboot"
      ASK_TO_REBOOT=1
    fi
    sed $CONFIG -i -r -e "s/^((device_tree_param|dtparam)=([^,]*,)*spi)(=[^,]*)?/\1=$SETTING/"
    if ! grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*spi=[^,]*" $CONFIG; then
     cat "dtparam=spi=$SETTING\n" >> $CONFIG
    fi
    whiptail --msgbox "The SPI interface $TENSE $STATUS$REBOOT" 20 60 1
    if [ $SETTING = "off" ]; then
      return 0
    fi
  fi

  CURRENT_STATUS="yes" # assume not blacklisted
  DEFAULT=
  if [ -e $BLACKLIST ] && grep -q "^blacklist[[:space:]]*spi[-_]bcm2708" $BLACKLIST; then
    CURRENT_STATUS="no"
    DEFAULT=--defaultno
  fi

  if ! [ -e $BLACKLIST ]; then
    touch $BLACKLIST
  fi

  whiptail --yesno "Would you like the SPI kernel module to be loaded by default?" $DEFAULT 20 60 2
  RET=$?
  if [ $RET -eq 0 ]; then
    sed $BLACKLIST -i -e "s/^\(blacklist[[:space:]]*spi[-_]bcm2708\)/#\1/"
    modprobe spi-bcm2708
    whiptail --msgbox "SPI kernel module will now be loaded by default" 20 60 1
  elif [ $RET -eq 1 ]; then
    sed $BLACKLIST -i -e "s/^#\(blacklist[[:space:]]*spi[-_]bcm2708\)/\1/"
    if ! grep -q "^blacklist spi[-_]bcm2708" $BLACKLIST; then
      printf "blacklist spi-bcm2708\n" >> $BLACKLIST
    fi
    whiptail --msgbox "SPI kernel module will no longer be loaded by default" 20 60 1
  else
    return 0
  fi
}

##############################
# Enable/disable i2c
# Disabled by default
##############################
do_i2c() {
  DEVICE_TREE="yes" # assume not disabled
  DEFAULT=
  if [ -e $CONFIG ] && grep -q "^device_tree=$" $CONFIG; then
    DEVICE_TREE="no"
  fi

  CURRENT_SETTING="off" # assume disabled
  DEFAULT=--defaultno
  if [ -e $CONFIG ] && grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*i2c(_arm)?(=(on|true|yes|1))?(,.*)?$" $CONFIG; then
    CURRENT_SETTING="on"
    DEFAULT=
  fi

  if [ $DEVICE_TREE = "yes" ]; then
    whiptail --yesno "Would you like the ARM I2C interface to be enabled?" $DEFAULT 20 60 2
    RET=$?
    if [ $RET -eq 0 ]; then
      SETTING=on
      STATUS=enabled
    elif [ $RET -eq 1 ]; then
      SETTING=off
      STATUS=disabled
    else
      return 0
    fi
    TENSE=is
    REBOOT=
    if [ $SETTING != $CURRENT_SETTING ]; then
      TENSE="will be"
      REBOOT=" after a reboot"
      ASK_TO_REBOOT=1
    fi
    sed $CONFIG -i -r -e "s/^((device_tree_param|dtparam)=([^,]*,)*i2c(_arm)?)(=[^,]*)?/\1=$SETTING/"
    if ! grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*i2c(_arm)?=[^,]*" $CONFIG; then
      cat "dtparam=i2c_arm=$SETTING\n" >> $CONFIG
    fi
    whiptail --msgbox "The ARM I2C interface $TENSE $STATUS$REBOOT" 20 60 1
    if [ $SETTING = "off" ]; then
      return 0
    fi
  fi

  CURRENT_STATUS="yes" # assume not blacklisted
  DEFAULT=
  if [ -e $BLACKLIST ] && grep -q "^blacklist[[:space:]]*i2c[-_]bcm2708" $BLACKLIST; then
    CURRENT_STATUS="no"
    DEFAULT=--defaultno
  fi

  if ! [ -e $BLACKLIST ]; then
    touch $BLACKLIST
  fi

  whiptail --yesno "Would you like the I2C kernel module to be loaded by default?" $DEFAULT 20 60 2
  RET=$?
  if [ $RET -eq 0 ]; then
    sed $BLACKLIST -i -e "s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/"
    sed /etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"
    if ! grep -q "^i2c[-_]dev" /etc/modules; then
      printf "i2c-dev\n" >> /etc/modules
    fi
    modprobe i2c-bcm2708
    modprobe i2c-dev
    whiptail --msgbox "I2C kernel module will now be loaded by default" 20 60 1
  elif [ $RET -eq 1 ]; then
    sed $BLACKLIST -i -e "s/^#\(blacklist[[:space:]]*i2c[-_]bcm2708\)/\1/"
    if ! grep -q "^blacklist i2c[-_]bcm2708" $BLACKLIST; then
      printf "blacklist i2c-bcm2708\n" >> $BLACKLIST
    fi
    sed /etc/modules -i -e "s/^\(i2c[-_]dev\)/#\1/"
    whiptail --msgbox "I2C kernel module will no longer be loaded by default" 20 60 1
  else
    return 0
  fi
}

#################################
# Enable/Disable serial terminal
# Enabled by default
#################################
do_serial() {
  DEFAULT=
  if ! grep -q "console=ttyAMA0" /boot/cmdline.txt; then
      DEFAULT=--defaultno
  fi

  whiptail --yesno "Would you like a login shell to be accessible over serial?" $DEFAULT 20 60 2
  RET=$?
  if [ $RET -eq 1 ]; then
    if [ $SYSTEMD -eq 0 ]; then
      sed -i /etc/inittab -e "s|^.*:.*:respawn:.*ttyAMA0|#&|"
    fi
    sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"
    whiptail --msgbox "Serial is now disabled" 20 60 1
  elif [ $RET -eq 0 ]; then
    if [ $SYSTEMD -eq 0 ]; then
      sed -i /etc/inittab -e "s|^#\(.*:.*:respawn:.*ttyAMA0\)|\1|"
      if ! grep -q "^T.*:.*:respawn:.*ttyAMA0" /etc/inittab; then
        printf "T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100\n" >> /etc/inittab
      fi
    fi
    if ! grep -q "console=ttyAMA0" /boot/cmdline.txt; then
        sed -i /boot/cmdline.txt -e "s/root=/console=ttyAMA0,115200 root=/"
    fi
    whiptail --msgbox "Serial is now enabled" 20 60 1
  else
    return $RET
  fi
  ASK_TO_REBOOT=1
}

#############################
# disables the tty and 
# other boot options selected
#############################
disable_raspi_config_at_boot() {
  if [ -e /etc/profile.d/raspi-config.sh ]; then
    rm -f /etc/profile.d/raspi-config.sh
    if [ $SYSTEMD -eq 1 ]; then
      if [ -e /etc/systemd/system/getty@tty1.service.d/raspi-config-override.conf ]; then
        rm /etc/systemd/system/getty@tty1.service.d/raspi-config-override.conf
      fi
    else
      sed -i /etc/inittab \
        -e "s/^#\(.*\)#\s*RPICFG_TO_ENABLE\s*/\1/" \
        -e "/#\s*RPICFG_TO_DISABLE/d"
    fi
    telinit q
  fi
}

##########################
# Add pi to internet list 
# location of your of your 
# pi
##########################
do_rastrack() {
  whiptail --msgbox "\
Rastrack (http://rastrack.co.uk) is a website run by Ryan Walmsley
for tracking where people are using Raspberry Pis around the world.
If you have an internet connection, you can add yourself directly
using this tool. This is just a bit of fun, not any sort of official
registration.\
" 20 70 1
  if [ $? -ne 0 ]; then
    return 0;
  fi
  UNAME=$(whiptail --inputbox "Username / Nickname For Rastrack Addition" 20 70 3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    return 1;
  fi
  EMAIL=$(whiptail --inputbox "Email Address For Rastrack Addition" 20 70 3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    return 1;
  fi
  curl --data "name=$UNAME&email=$EMAIL" http://rastrack.co.uk/api.php
  printf "Hit enter to continue\n"
  read -r TMP
}

##################################
# camaera port configuration
##################################
# $1 is 0 to disable camera, 1 to enable it
set_camera() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi

  [ -e $CONFIG ] || touch $CONFIG

  if [ "$1" -eq 0 ]; then # disable camera
    set_config_var start_x 0 $CONFIG
    sed $CONFIG -i -e "s/^startx/#startx/"
    sed $CONFIG -i -e "s/^start_file/#start_file/"
    sed $CONFIG -i -e "s/^fixup_file/#fixup_file/"
  else # enable camera
    set_config_var start_x 1 $CONFIG
    CUR_GPU_MEM=$(get_config_var gpu_mem $CONFIG)
    if [ -z "$CUR_GPU_MEM" ] || [ "$CUR_GPU_MEM" -lt 128 ]; then
      set_config_var gpu_mem 128 $CONFIG
    fi
    sed $CONFIG -i -e "s/^startx/#startx/"
    sed $CONFIG -i -e "s/^fixup_file/#fixup_file/"
  fi
}

#####################################
# Enable camera support onboard port
#####################################
do_camera() {
  if [ ! -e /boot/start_x.elf ]; then
    whiptail --msgbox "Your firmware appears to be out of date (no start_x.elf). Please update" 20 60 2
    return 1
  fi
  whiptail --yesno "Enable support for Raspberry Pi camera?" 20 60 2 \
    --yes-button Disable --no-button Enable
  RET=$?
  if [ $RET -eq 0 ] || [ $RET -eq 1 ]; then
    ASK_TO_REBOOT=1
    set_camera $RET;
  else
    return 1
  fi
}

###################
# Update this Menu 
###################
do_update() {
  apt-get update &&
  apt-get install raspi-openrepeater-config &&
  printf "Sleeping 5 seconds before reloading raspi-config\n" &&
  sleep 5 &&
  exec raspi-openrepeater-config
}

#########################
# Configure audio output
#########################
do_audio() {
  AUDIO_OUT=$(whiptail --menu "Choose the audio output" 20 60 10 \
    "0" "Auto" \
    "1" "Force 3.5mm ('headphone') jack" \
    "2" "Force HDMI" \
    3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    amixer cset numid=3 "$AUDIO_OUT"
  fi
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
  sed -n -e "s/^[[:space:]]*\"$2\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*,$/\1/p" "$1"
}

# TODO: This is probably broken
do_apply_os_config() {
  [ -e /boot/os_config.json ] || return 0
  NOOBSFLAVOUR=$(get_json_string_val /boot/os_config.json flavour)
  NOOBSLANGUAGE=$(get_json_string_val /boot/os_config.json language)
  NOOBSKEYBOARD=$(get_json_string_val /boot/os_config.json keyboard)

  if [ -n "$NOOBSFLAVOUR" ]; then
    printf "Setting flavour to %s based on os_config.json from NOOBS. May take a while\n" "$NOOBSFLAVOUR"

    printf "Unrecognised flavour. Ignoring\n"
  fi

  # TODO: currently ignores en_gb settings as we assume we are running in a 
  # first boot context, where UK English settings are default
  case "$NOOBSLANGUAGE" in
    "en")
      if [ "$NOOBSKEYBOARD" = "gb" ]; then
        DEBLANGUAGE="" # UK english is the default, so ignore
      else
        DEBLANGUAGE="en_US.UTF-8"
      fi
      ;;
    "de")
      DEBLANGUAGE="de_DE.UTF-8"
      ;;
    "fi")
      DEBLANGUAGE="fi_FI.UTF-8"
      ;;
    "fr")
      DEBLANGUAGE="fr_FR.UTF-8"
      ;;
    "hu")
      DEBLANGUAGE="hu_HU.UTF-8"
      ;;
    "ja")
      DEBLANGUAGE="ja_JP.UTF-8"
      ;;
    "nl")
      DEBLANGUAGE="nl_NL.UTF-8"
      ;;
    "pt")
      DEBLANGUAGE="pt_PT.UTF-8"
      ;;
    "ru")
      DEBLANGUAGE="ru_RU.UTF-8"
      ;;
    "zh_CN")
      DEBLANGUAGE="zh_CN.UTF-8"
      ;;
    *)
      printf "Language '%s' not handled currently. Run sudo raspi-openrepeater-config to set up" "$NOOBSLANGUAGE"
      ;;
  esac

  if [ -n "$DEBLANGUAGE" ]; then
    printf "Setting language to %s based on os_config.json from NOOBS. May take a while\n" "$DEBLANGUAGE"
    cat << EOF | debconf-set-selections
locales   locales/locales_to_be_generated multiselect     $DEBLANGUAGE UTF-8
EOF
    rm /etc/locale.gen
    dpkg-reconfigure -f noninteractive locales
    update-locale LANG="$DEBLANGUAGE"
    cat << EOF | debconf-set-selections
locales   locales/default_environment_locale select       $DEBLANGUAGE
EOF
  fi

  if [ -n "$NOOBSKEYBOARD" ] && [ "$NOOBSKEYBOARD" != "gb" ]; then
    printf "Setting keyboard layout to %s based on os_config.json from NOOBS. May take a while\n" "$NOOBSKEYBOARD"
    sed -i /etc/default/keyboard -e "s/^XKBLAYOUT.*/XKBLAYOUT=\"$NOOBSKEYBOARD\"/"
    dpkg-reconfigure -f noninteractive keyboard-configuration
    invoke-rc.d keyboard-setup start
  fi
  return 0
}


# Everything else needs to be run as root
if [ "$(id -u)" -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo raspi-openrepeater-config'\n"
  exit 1
fi

if [ -n "${OPT_MEMORY_SPLIT:-}" ]; then
  set -e # Fail when a command errors
  set_memory_split "${OPT_MEMORY_SPLIT}"
  exit 0
fi

##################
# Info About Menu
##################
do_about() {
  whiptail --msgbox "\
This tool provides a straight-forward way of doing initial
configuration of the Raspberry Pi/Svxlink Repeater. This is 
a always on Shell menu that will display everytime you login 
as the root user. I will make it a option for it to display 
for other users inthe future. \
" 20 70 1
}

#####################################
# Info About Enabling Repeater hats
######################################
do_repeater_hats() {
  whiptail --msgbox "\
How To enablle repeater hats: 

To enable the repeater hats / plug on boards you must enable the 
i2c, spi and the wm8731 spi sound card driver interface under 
OpenRepeater menu. This will require a reboot when completed. 

Once you have completed these steps power down your board and 
plug on the repeater hat onto the raspi board. Then power your
system up. Login to the gui and configure your system. \
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

#######################
# Put Logs into tmp fs
#######################
do_log_tmpfs() {
#################
#configure fstab
#################
cat >>/etc/fstab << DELIM
tmpfs   /var/cache/apt/archives tmpfs   size=100M,defaults,noexec,nosuid,nodev,mode=0755 0 0
DELIM

#######################################
# Configure /var/log dir's on reboots
#######################################
cat > /etc/init.d/preplog-dirs << DELIM
#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          prepare-dirs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Required-Start:
# Required-Stop:
# Short-Description: Create needed directories on /var/log/ for tmpfs at startup
# Description:       Create needed directories on /var/log/ for tmpfs at startup
### END INIT INFO
# needed Dirs
DIR[0]=/var/log/nginx
DIR[1]=/var/log/apt
DIR[2]=/var/log/ConsoleKit
DIR[3]=/var/log/fsck
DIR[4]=/var/log/news
DIR[5]=/var/log/ntpstats
DIR[6]=/var/log/samba
DIR[7]=/var/log/lastlog
DIR[8]=/var/log/exim
DIR[9]=/var/log/watchdog
case "${1:-''}" in
  start)
        typeset -i i=0 max=${#DIR[*]}
        while (( i < max ))
        do
                mkdir  ${DIR[$i]}
                chmod 755 ${DIR[$i]}
                i=i+1
        done
        # set rights
        chown www-data.adm ${DIR[0]}
        chown root.adm ${DIR[6]}
    ;;
  stop)
    ;;
  restart)
   ;;
  reload|force-reload)
   ;;
  status)
   ;;
  *)
DELIM

chmod 755 /etc/init.d/preplog-dirs
}

###############################################
# INSTALL FTP SERVER / ADD USER FOR DEVELOPMENT
###############################################
do_passwd_menu() {
########################
# set vsftp config path
########################
FTP_CONFIG_PATH="/etc/vsftpd.conf"

read -r -p 'Please enter vfstp user name :' vsftpn

apt-get install vsftpd

edit_config $FTP_CONFIG_PATH anonymous_enable NO enabled
edit_config $FTP_CONFIG_PATH local_enable YES enabled
edit_config $FTP_CONFIG_PATH write_enable YES enabled
edit_config $FTP_CONFIG_PATH local_umask 022 enabled

cat "force_dot_files=YES" >> "$vsftpn"

system vsftpd restart

# ############################
# ADD FTP USER & SET PASSWORD
# ############################
adduser "$vsftpn"
}


###############
# Password Menu
###############
do_passwd_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Password Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "PWD1 Change User Password" "Change password for the default user (pi)" \
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

###############
# Audio Menu
###############
do_audio_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Audio Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "AU1 Audio " "Ouput for audio from the onboard chip to hdmi or headphone jack" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      AU1\ *) do_audio ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###############
# Camera Menu
###############
do_camera_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Camera Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "C1 Camera " "Enable/Disable Raspberry Pi Camera onboard interface" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      C1\ *) do_camera ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

##################
# Serial Menu
##################
do_serial_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Serial Terminal Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "ST1 Serial Terminal" "Enable/Disable Serial Terminal output" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      ORA1\ *) do_serial ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

###################
# overclocking menu
###################
do_overclock_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Overclock Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
####################
#enable hats menu
####################
do_hats_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Hats Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "H1 Device Tree" "Enable/Disable the use of Device Tree" \
    "H2 SPI" "Enable/Disable automatic loading of SPI kernel module (needed for e.g. PiFace)" \
    "H3 I2C" "Enable/Disable automatic loading of I2C kernel module" \
    "H4 WM8731" "Enable/Disable automatic loading of wm8731 sound kernel module" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      H1\ *) do_devicetree ;;
      H2\ *) do_spi ;;
      H3\ *) do_i2c ;;
      H4\ *) do_wm8731 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

#########################
# web server Options menu
#########################
do_web_menu() {
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Web Services Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Internationalisation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Networking Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "SSH Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Networking Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "OpenRepeater Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "OpenRepeater Basic Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "OpenRepeater Advanced Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Advanced Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "A1 Overscan" "You may need to configure overscan if black bars are present on display" \
    "A2 Memory Split" "Change the amount of memory made available to the GPU" \
    "A4 Serial Terminal" " Serial Terminal configuration Menu" \
    "A5 Audio Menu" "Audio Configuration Menu" \
    "A6 Expand Filesystem" "Ensures that all of the SD card storage is available to the OS" \
    "A7 Camera Menu " "Raspberry Pi Camera" \
    "A8 Add to Rastrack" "Add this Pi to the online Raspberry Pi Map (Rastrack)" \
    "A9 Overclock Menu " "Overclocking for your Pi" \
    "A10 Update" "Update this tool to the latest version" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      A1\ *) do_overscan ;;
      A2\ *) do_memory_split ;;
      A4\ *) do_serial_menu ;;
      A5\ *) do_audio_menu ;;
      A6\ *) do_expand_rootfs ;;
      A7\ *) do_camera_menu ;;
      A8\ *) do_rastrack ;;
      A9\ *) do_overclock_menu ;;
      A10\ *) do_update ;;
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
  FUN=$(whiptail --title "Raspberry Pi OpenRepeater Configuration Tool" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
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
