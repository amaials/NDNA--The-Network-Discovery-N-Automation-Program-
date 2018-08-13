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


## PRECREATE VNAD-LEs folder in /usr/VNAD-LEs and chmod 755 /usr/VNAD/*.bash
####################################



find /usr/VNAD/ -type d -exec chmod 755 -R {} \;

######################################################
if [ -d /usr/VNAD/tmp ]
then
    rm -r /usr/VNAD/tmp
else
    echo ""
fi
#####################################################

echo "######################################################################"
echo  "                    _    ___   _____    ____ "
echo  "                   | |  / / | / /   |  / __ \  "
echo  "                   | | / /  |/ / /| | / / / /"
echo  "                   | |/ / /|  / ___ |/ /_/ / "
echo  "                   |___/_/ |_/_/  |_/_____/  "
echo  ""                         
echo  "         Vendor-Neutral-Automation and Discovery program"
echo  ""
echo "                   Add-on to the NDNA Program"
echo  "                   _   _   _   _   _   _   _  "
echo  ""   
echo  "               Hit Ctrl Z to Escape the Program"
echo "######################################################################"
echo  ""
######################################################
echo "####################################################################################################"
echo ""
echo "  Enter The Name of an Existing NDNA Site/DataCenter, VNAD LE (Logical Entity) or new VNAD LE specific name"
echo ""
echo "     VNAD LEs (Logical Entities), would be something that SPANs Multiple Sites/Be logical in Nature....."
echo "                       e.g. something like MPLS-WAN-ROUTERS, EDGE-ROUTERS, etc"
echo ""
echo "                                 Names are case sensitive"
echo ""
echo "      This will place all IP Lists that are created in /usr/DataCenters/<your DC Name>"
echo "                    or /usr/VNAD-LEs/<your VNAD Logical Entity Name>"
echo ""
echo "          Document the name. You will need to reference it as you use the program!!"
echo ""
echo "####################################################################################################"
echo ""
echo "       ALL YOUR CUSTOM DISCOVERY AND PROGRAMMING FILES WILL ALSO BE STORED IN THESE FOLDERS!!"
echo ""
echo "You still need to run any subsequent custom discovery or programming from the /usr/VNAD/* Directories (This is where you run the program)"
echo ""
read -p "   Enter Existing Data_Center, Existing VNAD LE (Logical Entity), or new VNAD LE Here: " DataCenter
echo ""
echo "####################################################################################################"
echo ""


VNADDCLOGDIR=/usr/VNAD/logs/$DataCenter

if [ -d "$VNADDCLOGDIR" ];
then
   echo "VNAD logs directory exists...bypassing directory creation"
else
   echo "** Creating VNAD logs Directory...."
   echo ""
   # build directory for logs
   mkdir /usr/VNAD/logs/$DataCenter
fi

date=$(date +"%b-%d-%y")

# write STDERR to log file
exec 2> >(tee /usr/VNAD/logs/$DataCenter/VNAD-$date.log)

date=$(date +"%b-%d-%y")

DIR=/usr/DataCenters/$DataCenter

VNADDIR=/usr/VNAD-LEs/$DataCenter

if [ -d "$VNADDIR" ]
then
    echo "** Directories for VNAD-Logical-Entity $VNADDIR exist....."
    echo ""
elif [ -d "$DIR" ]
then
    echo "** Directories for NDNA Site/DC $DIR exist....."
else
    echo "** This is a new VNAD-Logical-Entity....Creating $DataCenter directories...."
    echo ""
    ## Create new VNAD-LE folder
    mkdir /usr/VNAD-LEs/$DataCenter/
fi

##############################
if ls /usr/DataCenters/$DataCenter/VNAD/configs/*.txt 1> /dev/null 2>&1
then
    # backup VNAD datacenter's custom config folder
    zip -r -q $DataCenter-VNAD-custom-configs-dir-$date.zip /usr/DataCenters/$DataCenter/VNAD/configs/*.txt
    mv *.zip /usr/Backups/
else
    echo ""
fi
##############################

##############################
if ls /usr/VNAD-LEs/$DataCenter/VNAD/configs/*.txt 1> /dev/null 2>&1
then
    zip -r -q $DataCenter-VNAD-custom-configs-dir-$date.zip /usr/VNAD-LEs/$DataCenter/VNAD/configs/*.txt
    mv *.zip /usr/Backups/
else
    echo ""
fi
##############################

#####################################################
echo ""
echo ""
######################################################
echo "######################################################################"
echo  ""
echo "     Firewalls in the path must allow ICMP echo requests/replies"
echo "                  UDP port 161 for SNMP Polling"
echo "      And TCP port 22 for SSH connections when using automation"
echo  ""
echo "#####################################################################"

# Create each time due to tmp dirs is recursively deleted at the end of each program run
mkdir /usr/VNAD/tmp
mkdir /usr/VNAD/tmp/nmap-snmp-interfaces-output
mkdir /usr/VNAD/tmp/valid-snmp-nodes
mkdir /usr/VNAD/tmp/initial-vendor-logs
mkdir /usr/VNAD/tmp/final-vendor-logs
mkdir /usr/VNAD/tmp/final-output
mkdir /usr/VNAD/tmp/snmp-subnets-ranges

echo ""
echo ""
######################################################
echo "#####################################################"
echo ""
read -p "Enter the snmp community string: " snmp_comm
echo ""
echo "#####################################################"
    #make subnet a variable - then can scan with any subnet..within /24, but this way it's just easier
echo ""
echo ""

echo "######################################################################################"
echo ""
echo " Enter the subnet to scan using CIDR notation with no more than a /23 at a time...."
echo "             e.g. 10.0.4.0/23 or anything smaller, e.g. 10.1.1.0/26"
echo ""
echo "######################################################################################"
echo ""
read -p "Enter the subnet to scan NOW: " snmp_subnet
echo ""
echo "######################################################################################"

# No -Pu option, as this bypasses discovery, e.g. using ping, so not using this. This way, it's much faster and pings devices to see what IPs are available
# The -PE option uses ICMP echo request. Note, ICMP echo request must be open in FWs in the path, in addition to UDP 161
# The -sU scans UDP AND the -n makes sure to NOT do a reverse DNS lookup on the IP, which will break the application!
nmap $snmp_subnet -PE -nsU -p 161 --script=snmp-interfaces.nse --script-args snmpcommunity=$snmp_comm > /usr/VNAD/tmp/nmap-snmp-interfaces-output/nmap-snmp-interfaces-output.txt

echo $snmp_subnet | sed -e 's/[0-9][0-9][0-9]\.[0-9][0-9][0-9]\/.*//' | sed -e 's/[0-9][0-9][0-9]\.[0-9][0-9]\/.*//' | sed -e 's/[0-9][0-9][0-9]\.[0-9]\/.*//' | sed -e 's/[0-9][0-9]\.[0-9][0-9][0-9]\/.*//' | sed -e 's/[0-9][0-9]\.[0-9][0-9]\/.*//' | sed -e 's/[0-9][0-9]\.[0-9]\/.*//' | sed -e 's/[0-9]\.[0-9][0-9][0-9]\/.*//' | sed -e 's/[0-9]\.[0-9][0-9]\/.*//' | sed -e 's/[0-9]\.[0-9]\/.*//' > /usr/VNAD/tmp/nmap_net.txt

# Create variable of subnet
snmp_subnet_var=$(</usr/VNAD/tmp/nmap_net.txt) 


cd /usr/VNAD/tmp/nmap-snmp-interfaces-output
#cat nmap-snmp-interfaces-output.txt | grep "IP address: $snmp_subnet_var" | awk {'print $4'} > /usr/VNAD/tmp/valid-snmp-nodes/valid-snmp-nodes.txt
cat nmap-snmp-interfaces-output.txt | grep "Nmap scan report for $snmp_subnet_var" | awk {'print $5'} > /usr/VNAD/tmp/valid-snmp-nodes/valid-snmp-nodes.txt

#####################################################
# BUILD HOSTNAME INFO
cd /usr/VNAD/tmp/valid-snmp-nodes

file="/usr/VNAD/tmp/valid-snmp-nodes/valid-snmp-nodes.txt"
while IFS= read line
do
        # display $line or do somthing with $line
        # this script runs snmpwalk on $line, e.g. on each IP address in the file valid-snmp-nodes.txt and 
        # writes a txt file with the name $line.txt, e.g. 192.168.88.199.txt (etc......)
  echo ""  
  echo ""
  snmpwalk -Os -c $snmp_comm -v 2c $line iso.3.6.1.2.1.1.5 > $line.txt
  echo "** Hostname Information Extraction has Completed"
done <"$file"

# build file with keys for dict in /usr/VNAD EACH TIME PROGRAM IS RUN - Will append to file when copying over to VNAD LE or DC folders and remove duplicates
echo "IP-Address,Hostname" > /usr/VNAD/tmp/valid-snmp-nodes/VNAD-hostname-to-IPs-pre.csv

# finish building CSV file before removing duplicates and creating final CSV to move to final directory
#ls | grep -H ^"iso" *.txt | awk {'print $1 ", " $4'} | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/\.txt.*0//' >> VNAD-hostname-to-IPs-pre.csv
ls | grep -H ^"iso" *.txt | awk {'print $1 ", " $4'} | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/\.txt.*,/,/' >> VNAD-hostname-to-IPs-pre.csv
# remove duplicate hostnames
cat /usr/VNAD/tmp/valid-snmp-nodes/VNAD-hostname-to-IPs-pre.csv | awk '{ if (a[$2]++ ==0) print $0; }' > /usr/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv
######################################################

# create final non-duplicate hostname IP list to run sysdescr on..
cat /usr/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv | grep ^"[1-2]" | awk {'print $1'} | sed -e 's/,//' > /usr/VNAD/tmp/valid-snmp-nodes/valid-snmp-nodes-final.txt

#####################################################
# BUILD VENDOR INFO
cd /usr/VNAD/tmp/valid-snmp-nodes

file="/usr/VNAD/tmp/valid-snmp-nodes/valid-snmp-nodes-final.txt"
while IFS= read line
do
        # display $line or do somthing with $line
        # this script runs snmpwalk on $line, e.g. on each IP address in the file valid-snmp-nodes.txt and 
        # writes a txt file with the name $line.txt, e.g. 192.168.88.199.txt (etc......)
  echo ""
  echo ""
  snmpwalk -Os -c $snmp_comm -v 2c $line iso.3.6.1.2.1.1.1 > $line.txt
  echo "** Vendor Information Extraction has Completed"
done <"$file"
######################################################
######################################################
echo ""
echo ""
echo "** Building Vendor Files....."
echo ""
echo ""
find . | grep -r "Cisco IOS" > /usr/VNAD/tmp/initial-vendor-logs/Cisco_IOS.log
find . | grep -r "Cisco NX-OS" > /usr/VNAD/tmp/initial-vendor-logs/Cisco_NXOS.log
find . | grep -r "Cisco Adaptive Security" > /usr/VNAD/tmp/initial-vendor-logs/Cisco_ASA.log
find . | grep -r JUNOS > /usr/VNAD/tmp/initial-vendor-logs/Juniper.log
find . | grep -r "Palo Alto" > /usr/VNAD/tmp/initial-vendor-logs/Palo.log
find . | grep -r Arista > /usr/VNAD/tmp/initial-vendor-logs/Arista.log
#find . | grep -r F5 > /usr/VNAD/tmp/initial-vendor-logs/F5.log   --- future release
######################################################

cd /usr/VNAD/tmp/initial-vendor-logs/

cat Cisco_IOS.log | awk {'print $1'} | grep ^[1-2] > Cisco-IOS-final.log
cat Cisco_NXOS.log | awk {'print $1'} | grep ^[1-2] > Cisco-NXOS-final.log
cat Cisco_ASA.log | awk {'print $1'} | grep ^[1-2] > Cisco-ASA-final.log
cat Juniper.log | awk {'print $1'} | grep ^[1-2] > Juniper-final.log
cat Palo.log | awk {'print $1'} | grep ^[1-2] > Palo-final.log
cat Arista.log | awk {'print $1'} | grep ^[1-2] > Arista-log-final.log
# cat F5.log | awk {'print $1'} | grep ^[1-2] > F5-log-final.log   --- future release
######################################################
######################################################
echo "** Almost Complete...... "
sleep 2
echo ""
echo ""
sleep 2
echo ""
echo ""
mv *final.log /usr/VNAD/tmp/final-vendor-logs
######################################################
######################################################
echo "** Building Vendor specific IP files for Python Automation Capabilities....Standby..." 

cd /usr/VNAD/tmp/final-vendor-logs


# files were pre-created, so we can prepend to final IP files as we run potentially multiple subnet *walks*
cat Cisco-IOS-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/cisco_ip_file.txt
cat Cisco-NXOS-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/cisco_nxos_ip_file.txt
cat Cisco-ASA-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/cisco_asa_ip_file.txt
cat Juniper-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/Juniper_ip_file.txt
cat Palo-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/Palo_ip_file.txt
# cat F5-log-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/F5_ip_file.txt   --- future release
cat Arista-log-final.log | sed -e 's/.txt.*//' >> /usr/VNAD/tmp/final-output/Arista_ip_file.txt
######################################################
######################################################
echo ""
echo ""
##########################################################################################
# copy over to final staging before final destination of VNAD LE or DataCenter folder
cp /usr/VNAD/tmp/final-output/cisco_ip_file.txt /usr/VNAD/IP-Lists/Cisco/IOS
cp /usr/VNAD/tmp/final-output/cisco_nxos_ip_file.txt /usr/VNAD/IP-Lists/Cisco/NXOS
cp /usr/VNAD/tmp/final-output/cisco_asa_ip_file.txt /usr/VNAD/IP-Lists/Cisco/ASA
cp /usr/VNAD/tmp/final-output/Juniper_ip_file.txt /usr/VNAD/IP-Lists/Juniper/
cp /usr/VNAD/tmp/final-output/Palo_ip_file.txt /usr/VNAD/IP-Lists/Palo-Alto
# cp /usr/VNAD/tmp/final-output/F5_ip_file.txt /usr/VNAD/IP-Lists/F5    --- future release
cp /usr/VNAD/tmp/final-output/Arista_ip_file.txt /usr/VNAD/IP-Lists/Arista
######################################
######################################
if [ -d /usr/DataCenters/$DataCenter ]
then
    if  [ -d /usr/DataCenters/$DataCenter/VNAD ]
    then
        echo "Appending to Existing VNAD Data-Center folder..."
        # then append new IPs and remove duplicates - this is the current file, e.g. from current discovery, but after duplicates are removed, -py.txt file is final file, even during first discovery
        cat /usr/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt
        cat /usr/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt
        cat /usr/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt
        cat /usr/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt
        cat /usr/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt
        cat /usr/VNAD/IP-Lists/Arista/Arista_ip_file.txt >> /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt

        # remove duplicate IPs and add py name to file - NOTE IP file py automation scripts point to has to ALWAYS be the -py.txt file - 
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file-py.txt

        # remove duplicate hostnames and date file with updated non-duplicates
        cat /usr/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv >> /usr/DataCenters/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv
        cat /usr/DataCenters/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv | awk '{ if (a[$2]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs-$date.csv

        cp /usr/VNAD/$DataCenter/logs/VNAD-$date.log /usr/DataCenters/$DataCenter/VNAD/logs

        cd /usr/DataCenters/$DataCenter/VNAD/
        rm -r /usr/VNAD/tmp
        zip -r -q $DataCenter-VNAD-Backup-$date.zip /usr/DataCenters/$DataCenter/VNAD/
        mv *.zip /usr/Backups/
        echo ""

    else
        cp -r /usr/VNAD /usr/DataCenters/$DataCenter
        cd /usr/DataCenters/$DataCenter/VNAD/
        rm -r /usr/DataCenters/$DataCenter/VNAD/tmp
        rm -r /usr/DataCenters/$DataCenter/VNAD/Automation
        rm -r /usr/VNAD/tmp
        rm /usr/DataCenters/$DataCenter/VNAD/VNAD.bash
        #rm /usr/DataCenters/$DataCenter/VNAD/VNAD-nmap.bash
        echo ""
        # remove duplicate IPs and add py name to file - NOTE IP file py automation scripts point to has to ALWAYS be the -py.txt file - 
        # THAT'S WHY WE MUST RUN even during first discovery (Even tho no dups to remove)
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file-py.txt
        cat /usr/DataCenters/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv | awk '{ if (a[$2]++ ==0) print $0; }' > /usr/DataCenters/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs-$date.csv
        zip -r -q $DataCenter-VNAD-Backup-$date.zip /usr/DataCenters/$DataCenter/VNAD/
        mv *.zip /usr/Backups/
    fi

else
    echo ""
fi
######################################
######################################
if [ -d /usr/VNAD-LEs/$DataCenter ]
then
    if  [ -d /usr/VNAD-LEs/$DataCenter/VNAD ]
    then
        echo "Appending to Existing VNAD Logical Entity folder..."
        # then append new IPs and remove duplicates - this is the current file, e.g. from current discovery, but after duplicates are removed, -py.txt file is final file, even during first discovery
        cat /usr/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt
        cat /usr/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt
        cat /usr/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt
        cat /usr/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt
        cat /usr/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt
        cat /usr/VNAD/IP-Lists/Arista/Arista_ip_file.txt >> /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt

        # remove duplicate IPs and add py name to file - NOTE IP file py automation scripts point to has to ALWAYS be the -py.txt file - 
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file-py.txt

        # remove duplicate hostnames and date file with updated non-duplicates
        cat /usr/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv >> /usr/VNAD-LEs/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv
        cat /usr/VNAD-LEs/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv | awk '{ if (a[$2]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs-$date.csv

        cp /usr/VNAD/logs/$DataCenter/VNAD-$date.log /usr/VNAD-LEs/$DataCenter/VNAD/logs

        cd /usr/VNAD-LEs/$DataCenter/VNAD/
        rm -r /usr/VNAD/tmp
        zip -r -q $DataCenter-VNAD-Backup-$date.zip /usr/VNAD-LEs/$DataCenter/VNAD/
        mv *.zip /usr/Backups/
        echo ""

    else
        cp -r /usr/VNAD /usr/VNAD-LEs/$DataCenter
        cd /usr/VNAD-LEs/$DataCenter/VNAD/
        rm -r /usr/VNAD-LEs/$DataCenter/VNAD/tmp
        rm -r /usr/VNAD-LEs/$DataCenter/VNAD/Automation
        rm -r /usr/VNAD/tmp
        rm /usr/VNAD-LEs/$DataCenter/VNAD/VNAD.bash
        #rm /usr/VNAD-LEs/$DataCenter/VNAD/VNAD-nmap.bash
        echo ""
        # remove duplicate IPs and add py name to file - NOTE IP file py automation scripts point to has to ALWAYS be the -py.txt file - 
        # THAT'S WHY WE MUST RUN even during first discovery (Even tho no dups to remove)
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/IOS/cisco_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/NXOS/cisco_nxos_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Cisco/ASA/cisco_asa_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Palo-Alto/Palo_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file.txt | awk '{ if (a[$1]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/IP-Lists/Arista/Arista_ip_file-py.txt
        cat /usr/VNAD-LEs/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs.csv | awk '{ if (a[$2]++ ==0) print $0; }' > /usr/VNAD-LEs/$DataCenter/VNAD/hostname-to-IPs/VNAD-hostname-to-IPs-$date.csv
        zip -r -q $DataCenter-VNAD-Backup-$date.zip /usr/VNAD-LEs/$DataCenter/VNAD/
        mv *.zip /usr/Backups/
    fi

else
    echo ""
fi
######################################
######################################

echo "############################################################"
echo "  -------------------------------------------------------- "
echo "          VNAD Program has completed for $DataCenter           "
echo "                                                           "
echo "              Thank you for being patient                 "
echo "                                                           "
echo "            You can review the log in either:"
echo "         /usr/VNAD-LEs/$DataCenter/VNAD/logs or the"
echo "         /usr/DataCenters/$DataCenter/VNAD/logs folder"
echo ""
echo "             The location depends on if this was run"
echo "               on a VNAD-LE or run on a DataCenter"
echo " "
echo "          Follow any instructions in the user guide       "
echo "  -------------------------------------------------------- "
echo "############################################################"