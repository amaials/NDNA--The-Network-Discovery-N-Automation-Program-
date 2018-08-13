#!/bin/bash

## 
## ------------------------------------------------------------------
##     NDNA: The Network Discovery N Automation Program
##     Copyright (C) 2017  Brett M Spunt, CCIE No. 12745 (US Copyright No. TXu 2-053-026)
## 
##     This file is part of NDNA.
##
##     NDNA is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
## 
##     NDNA is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
##
##     This program comes with ABSOLUTELY NO WARRANTY.
##     This is free software, and you are welcome to redistribute it
##
##     You should have received a copy of the GNU General Public License
##     along with NDNA.  If not, see <https://www.gnu.org/licenses/>.
## ------------------------------------------------------------------
## 


# BUILD SITE/DC VAR
echo ""
echo ""
echo " NTC Only supports importing IOS devices, not NXOS devices. No NXOS devices will be imported"
echo ""
echo ""
read -p "Enter The Company Code/Data_Center String: " DataCenter
echo ""
echo ""

DataCenterdir=/usr/DataCenters/$DataCenter
 
if [ -d "$DataCenterdir" ];
then
   echo "Data_Center Exists...."
else
   echo "Data_Center does not exist...Program exiting. Goodbye..."
   exit 1
fi


###########BUILD VARIABLES###########
echo ""
echo ""
# BUILD Cact Server IP VAR
read -p "Enter The IP address of the Remote Cacti Server: " cactiipvar
echo ""
echo ""


echo "pinging Cacti Server...standby..."
echo ""
echo ""
if ping -c 2 $cactiipvar &> /dev/null
then
  echo "ping check success...proceeding...."
  echo ""
  echo ""
else
  echo "ping check failed. check connectivity to the cacti server and try again"
  exit 1
fi


echo ""
echo ""
# BUILD Cact Server IP VAR
read -p "Enter The root password of the Remote Cacti Server: " rootpassvar
echo ""
echo ""


# BUILD snmp-community VAR
# prompt for snmp-community name to run against and store as a variable...
read -p "Enter The SNMP community String: " snmpcomvar
echo ""
echo ""

####################################
date=$(date +"%b-%d-%y")

# write STDERR to log file
exec 2> >(tee /usr/NTC/cacti/NTC-L3-date.log)
####################################


#############
#remove seed text from core device is exists
sed -i 's/_seed//' /usr/DataCenters/$DataCenter/DCDP/hostname-to-IPs/hostname-to-IPs-IOS.csv
#############


########BUILD IOS L3 IPs###############################
cd /usr/DataCenters/$DataCenter/DCDP/good-IPs

L3file="/usr/DataCenters/$DataCenter/DCDP/good-IPs/L3-IOS-IPs.txt"
while IFS= read line
do
  cat /usr/DataCenters/$DataCenter/DCDP/hostname-to-IPs/hostname-to-IPs-IOS.csv | grep -w $line >> /usr/NTC/cacti/L3-hostname-to-IPs.csv
done <"$L3file"
######################################################

cd /usr/NTC/cacti

cat L3-hostname-to-IPs.csv > NDNA-$DataCenter-to-CACTI.csv

######################
# write snmp community to a variable to copy over to cacti server via sshpass, then pull back in as a variable once 
# on the remote server. This script built on the NDNA server will have the $snmpcomvar string in it, not the real value
echo $snmpcomvar > snmp-com-tmp.txt

## must copy this file locally, even though it's used on remote Cacti server. It must be present locally in the same path for sshpass to work
cp snmp-com-tmp.txt /usr/share/cacti/cli/tmp
######################

#remove empty lines
sed -i '/^$/d' NDNA-$DataCenter-to-CACTI.csv

######################
# Start to build script for Cacti Import....
echo ""
echo "Starting to build script for Cacti Import....."
echo ""
# need to run commands from this directory
echo cd /usr/share/cacti/cli > build-devices-into-cacti.bash

cat NDNA-$DataCenter-to-CACTI.csv  | grep -v IP | sed -e 's/^/php -q add_device.php --description="/' | sed -e 's/[1-2].*, //' | sed -e 's/$/"/' > build-device-into-cacti-pre-hostname.txt
cat NDNA-$DataCenter-to-CACTI.csv   | grep -v IP | awk {'print $1'} | sed -e 's/,//' | sed -e 's/_.*//' | sed -e 's/^/ --ip="/' | sed -e 's/$/"/' | sed -e 's/$/ --template=5 --version=2 --community="$snmpcomvar"/' > build-device-into-cacti-pre-ip.txt

# concatenate both files "side by side" to each other using paste utility -->
# Don't worry about the space above between descript and --ip ....doesnt present an issue!
paste build-device-into-cacti-pre-hostname.txt build-device-into-cacti-pre-ip.txt >> build-devices-into-cacti.bash

# insert shebang on first line
sed -i '1s/^/#!\/bin\/bash\n/' build-devices-into-cacti.bash
######################


######################
echo "Connecting to Remote Cacti Server....Performing Prep Work....Standby..."
echo ""
echo "This will take a few minutes, then we will begin building in devices"
echo ""
#####
# copy over bash script to run on remote server
sshpass -p "$rootpassvar" scp -2 build-devices-into-cacti.bash root@$cactiipvar:

# then move into the proper directory
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "mv build-devices-into-cacti.bash /usr/share/cacti/cli/tmp"
#####


#####
# copy over snmp community text file to bring in as a variable on remote server
sshpass -p "$rootpassvar" scp -2 snmp-com-tmp.txt root@$cactiipvar:

# then move into the proper directory
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "mv snmp-com-tmp.txt /usr/share/cacti/cli/tmp"

# build snmp com variable code in bash script com on remote server. need to insert at the 2nd line "after" bin/bash statement
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "sed -i '2s/^/snmpcomvar=$(<\/usr\/share\/cacti\/cli\/tmp\/snmp-com-tmp.txt)\n/' /usr/share/cacti/cli/tmp/build-devices-into-cacti.bash"
#####

#make it executable
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "chmod 755 /usr/share/cacti/cli/tmp/build-devices-into-cacti.bash"

# build file of cacti-host-list prior to building in new DC/site
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "/usr/share/cacti/cli/cacti-hosts-before-import.bash > cacti-hosts-before-import.txt"
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "mv cacti-hosts-before-import.txt /usr/share/cacti/cli/tmp"

# run the script to build devices into cacti
echo "Building L3 Devices into Remote Cacti Server....Standby"
echo "#########################################################"
echo ""
echo "Please be patient, this will take roughly 10 seconds per device. Total time varies based on the amount of devices you are importing"
echo ""
sshpass -f <(printf '%s\n' $rootpassvar) ssh -o StrictHostKeyChecking=no -l root $cactiipvar "/usr/share/cacti/cli/tmp/build-devices-into-cacti.bash > /usr/share/cacti/cli/tmp/grab-cacti-device-IDs.txt"

rm -r /usr/NTC/cacti/*.txt
rm -r /usr/NTC/cacti/*.csv
rm -r /usr/NTC/cacti/*cacti.bash


echo "#################################################################################"
echo ""
echo "    L3 Devices for the NDNA DataCenter $DataCenter have been built into cacti"
echo ""
echo "          You must now log onto the Cacti Server at $cactiipvar"
echo ""
echo "And run the following Program located at /usr/share/cacti/cli/NDNA on the Cacti Server:" 
echo "" 
echo "                  *NDNA-build-graphs-into-cacti.bash*"
echo ""
echo "To be safe, allow Cacti enough time to gather SNMP information on all devices"
echo ""
echo "       Please wait at least 15 minutes before running this program"
echo ""
echo "     You must do this prior to building in any other DataCenters...."
echo ""
echo "                            Thank You!"
echo "#################################################################################"