#!/bin/bash

################################################################################
# prep4img script
################################################################################

echo "--------------------------------------------------------------"
echo " Stopping SVXLink"
echo "--------------------------------------------------------------"

orp_helper svxlink stop

################################################################################

echo "--------------------------------------------------------------"
echo " Purging DB of Identifiable Info"
echo "--------------------------------------------------------------"

sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE settings SET value='' WHERE keyID='callSign'"
sqlite3 "/var/lib/openrepeater/db/openrepeater.db" "UPDATE modules SET moduleEnabled='0', moduleOptions='' WHERE svxlinkName='EchoLink'"

################################################################################

echo "--------------------------------------------------------------"
echo " Purging Config Files & Log"
echo "--------------------------------------------------------------"

echo "" > /etc/svxlink/svxlink.conf
echo "" > /etc/svxlink/svxlink.d/ModuleEchoLink.conf
echo "" > /var/log/svxlink

################################################################################

echo "--------------------------------------------------------------"
echo " Remove DEV directory if it exists"
echo "--------------------------------------------------------------"

rm -R /var/www/openrepeater/dev

################################################################################
echo "--------------------------------------------------------------"
echo " COMPLETED:"
echo " Don't forget to clear root folder of scripts using:"
echo " rm -R /root/*"
echo ""
echo " Did you set root password to ORP default?"
echo ""
echo " Shutdown using halt"
echo "--------------------------------------------------------------"