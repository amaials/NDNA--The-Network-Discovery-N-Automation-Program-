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

### Program will be run from /usr/share/cacti/cli/NDNA on the Cacti Server

# BUILD GRAPHS AND ASSIGN TO TREE

echo ""
echo ""
if (dialog --title "Welcome to The 'NDNA-Build-Graphs-Into-Cacti-Program'" --yesno "         Choose Yes to Begin, or No to Exit." 10 60) then
    echo "Running the program..."
else
    exit 1
fi
echo ""
echo ""
######################
# Start to build script to build graphs....
echo "Starting to build graphs in Cacti for current DataCenter import....."
echo ""
echo ""
# BUILD SITE/DC VAR
read -p "Enter The Company Code/Data_Center String: " DataCenter
echo ""
echo ""
echo "                 ******* ALERT ******* "
echo "  If you get the following message while building Graphs:"
echo "-------------------------------------------------------------"
echo "ERROR: Unknown snmp-field ifOperStatus for host(ID-Number)"
echo ""
echo "  This just means the host is not reachable via SNMP." 
echo " The error can be ignored, and the program will continue" 
echo "           running through completion"
echo ""
echo ""
echo "No Graphs can be built for ANY devices where Cacti is not able" 
echo "            To communicate with it via SNMP"
echo "-------------------------------------------------------------"
echo ""
echo "    The Program will resume in a few seconds...Standby....."
sleep 25
echo ""
echo ""
######################

date=$(date +"%b-%d-%y")

# write STDERR to log file
exec 2> >(tee /usr/share/cacti/cli/NDNA/NTC-date.log)

#########################################################
cd /usr/share/cacti/cli/tmp
# PULL OUT CACTI DEVICE IDs 
cat grab-cacti-device-IDs.txt | grep ^Su | awk {'print $5'} | sed -e 's/(//' | sed -e 's/)//' > device-IDs.txt
#########################################################

#########################################################
# count the number of device IDs present SO WE KNOW HOW MANY VARIABLES/DEVICE IDs to build into Cacti and can print statement 
wc -w device-IDs.txt | awk {'print $1'} > number-of-device-variables-needed.txt

deviceidvars=$(</usr/share/cacti/cli/tmp/number-of-device-variables-needed.txt)

echo "building graphs for $deviceidvars devices into the cacti system.........standby"
sleep 6
#########################################################

#########################################################
#  put together build-graph-bash-script

# build PHP statement to build graphs for each host/device ID
cat device-IDs.txt | sed -e 's/^/php -q add_graphs.php --host-id=/' | sed -e 's/$/ --graph-type=ds --graph-template-id=32 --snmp-query-id=1 --snmp-query-type-id=13 --snmp-field=ifOperStatus --snmp-value=Up/' >  build-device-graphs.bash

# insert shebang on first line
sed -i '1s/^/#!\/bin\/bash\n/' build-device-graphs.bash
# cd to proper dir before running commands
sed -i '2s/^/cd \/usr\/share\/cacti\/cli\n/' build-device-graphs.bash
# make executable
chmod 755 build-device-graphs.bash
# Run the program to build graphs
./build-device-graphs.bash
#########################################################

#########################################################
echo "Graphs have been created. Building Company/Site Header $DataCenter in Cacti Tree Under NDNA-Internetwork..."
echo ""
echo ""
sleep 7
#########################################################

cd /usr/share/cacti/cli
#########################################################
# Build Company/DC Header in Cacti Tree
php -q add_tree.php --type=node --node-type=header --tree-id=2 --name=$DataCenter

# NOTE- our current pwd is /usr/share/cacti/cli so we only need to specify tmp/
# Pull Company/DC cacti Header ID from Cacti Tree redirect to a file
php -q add_tree.php --list-nodes --tree-id=2 | grep $DataCenter | awk {'print $2'} > tmp/current-co-site-cacti-tree-ID.txt
#########################################################


#########################################################
echo "$DataCenter Company/Site Header has been created in Cacti Tree Under NDNA-Internetwork......"
echo ""
echo ""
echo "Assigning Graphs to $DataCenter Under NDNA-Internetwork in Cacti Tree......."
echo ""
echo ""
sleep 7
#########################################################

#########################################################
# Pull current-co-site-cacti-tree-ID - then pull back in as a variable
cd tmp
cactitreeleafID=$(</usr/share/cacti/cli/tmp/current-co-site-cacti-tree-ID.txt)

cat /usr/share/cacti/cli/tmp/build-devices-into-cacti.bash | awk {'print $4'} | sed -e 's/--description="//' | sed -e 's/"//' > currentdchostnames.txt

# probably dont need this variable, but creating just in case, or for future use.
currentdchostnames=$(</usr/share/cacti/cli/tmp/currentdchostnames.txt)
#########################################################


#########################################################
cd /usr/share/cacti/cli/
# grab full host list from cacti and redirect into a file
php -q add_graphs.php --list-hosts > tmp/get-all-cacti-hosts.txt 


cd tmp
# cat file, using GRASP to pull out just the hosts from current DC import for diff compare
cat get-all-cacti-hosts.txt | grep -v ^Known | awk {'print $4'} > full-cacti-hosts-list.txt

# get diff and output to process via GRASP
diff currentdchostnames.txt full-cacti-hosts-list.txt > diff-output-to-further-process.txt

# modify to have final list of nodes to parse which is current cacti host list minus the nodes we just imported
 cat diff-output-to-further-process.txt | grep ">" | sed -e 's/>//' | sed -e 's/ //' > host-list-minus-current-dc.txt


# using GRASP, build a script to remove all hosts from cacti-host-list (cacti format output with IDs) leaving only current DCs (to then parse IDs)
cd /usr/share/cacti/cli/

# build file of cactihost-list AFTER import
php -q add_graphs.php --list-hosts > tmp/cacti-hosts-after-import.txt

cd tmp
# diff the before and after to get the diff, using grasp to output the current DC's host-IDs
# the cacti-hosts-before-import.txt will be written from the program ran on the NDNA server!
diff --ignore-all-space cacti-hosts-before-import.txt cacti-hosts-after-import.txt | grep ">" | awk {'print $2'} > host-IDs-current-dc-import.txt

# e.g.
# diff --ignore-all-space cacti-hosts-before-import.txt cacti-hosts-after-import.txt | grep ">"
# > 16      10.1.1.1                ca-lab-rt1
# > 17      10.2.2.2                ca-lab-rt2
# root@debian-python:/usr/share/cacti/cli/tmp# diff --ignore-all-space cacti-hosts-before-import.txt cacti-hosts-after-import.txt | grep ">" | awk {'print $2'}
# 16
# 17
#########################################################

#########################################################
# build bash script to obtain all grapth IDs associated with current DC import
cat host-IDs-current-dc-import.txt | sed -e 's/^/php -q add_tree.php --list-graphs --host-id=/' > get-grapth-ids.bash

# insert shebang on first line
sed -i '1s/^/#!\/bin\/bash\n/' get-grapth-ids.bash

# cd to proper dir before running commands
sed -i '2s/^/cd \/usr\/share\/cacti\/cli\n/' get-grapth-ids.bash

# make executable
chmod 755 get-grapth-ids.bash

# Run the program to get graph IDs
./get-grapth-ids.bash > grapth-id-results.txt
#########################################################


###########################################
# Build graphs onto DataCenter leaf of cacti tree
#
# parent-node== your Leaf, e.g. this is your CURRENT cactitreeID var,e.g. MFE:LA-DC (your DataCenter) 
#
# tree-id=2 is NDNA-Internetwork - Top Tree Level

# GET GRAPH INFO ON CURRENT CO/SITE (via GRASP getting host IDs e.g. 9 and 14 in examples below)
# php -q add_tree.php --list-graphs --host-id=9

#php -q add_tree.php --list-nodes --tree-id=2
#Known Tree Nodes:
#type    id      parentid        title   attribs
#Header  13      N/A     CCC:NYC Alphabetic Ordering
#Header  19      N/A     MFE:LA-DC       Alphabetic Ordering
#Graph   32      19      us-dal-rt1 - Traffic - Fa0/0    Daily (5 Minute Average)


# Can view with command "php -q add_tree.php --list-nodes --tree-id=2"
# php -q add_tree.php --type=node --parent-node=19 --node-type=graph --tree-id=2 --graph-id=41
# php -q add_tree.php --type=node --parent-node=19 --node-type=graph --tree-id=2 --graph-id=42
# etc. etc.
#


# build bash script to Build graphs onto DataCenter leaf of cacti tree
cat grapth-id-results.txt | awk {'print $1'} | grep ^[0-9] > grapth-id-final-results.txt

# NOTE - NEED DOUBLE QUOTE IN SED TO ALLOW VARIABLE TO WORK!
cat grapth-id-final-results.txt | sed -e "s/^/php -q add_tree.php --type=node --parent-node=$cactitreeleafID --node-type=graph --tree-id=2 --graph-id=/" > build-grapths.bash



# insert shebang on first line
sed -i '1s/^/#!\/bin\/bash\n/' build-grapths.bash

# cd to proper dir before running commands
sed -i '2s/^/cd \/usr\/share\/cacti\/cli\n/' build-grapths.bash
# make executable
chmod 755 build-grapths.bash

# Run the program to build graphs
./build-grapths.bash

echo ""
echo ""
echo "Removing temporary files..."
sleep 5
cd /usr/share/cacti/cli/tmp
rm *.txt
rm *.bash
echo ""
echo ""
echo "#################################################################################"
echo ""
echo "    Graphs for the NDNA DataCenter $DataCenter have been built into cacti"
echo ""
echo "             And assigned to the NDNA DataCenter $DataCenter"
echo ""
echo "                            Thank You!"
echo "#################################################################################"
echo ""
echo ""