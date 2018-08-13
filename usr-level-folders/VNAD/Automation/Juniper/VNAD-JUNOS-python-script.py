#!/usr/bin/env python


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


"""

This is your VNAD Juniper python script. It can be used to thread to devices and either 
program the devices or pull ANY information from the devices. 

"""

import paramiko
import time
import re
import sys
import threading
import datetime
import getpass
import os
import os.path
import subprocess
import base64

print "###############################################################################################" 
print "   ______           __                       ____        __  __           "   
print "  / ____/_  _______/ /_____  ____ ___       / __ \__  __/ /_/ /_  ____  ____ "
print " / /   / / / / ___/ __/ __ \/ __ `__ \     / /_/ / / / / __/ __ \/ __ \/ __ \ " 
print "/ /___/ /_/ (__  ) /_/ /_/ / / / / / /    / ____/ /_/ / /_/ / / / /_/ / / / /  "
print "\____/\__,_/____/\__/\____/_/ /_/ /_/____/_/    \__, /\__/_/ /_/\____/_/ /_/ "
print "                                   /_____/     /____/                        "
print "                     _____           _       __ "
print "                    / ___/__________(_)___  / /_"
print "                    \__ \/ ___/ ___/ / __ \/ __/"
print "                   ___/ / /__/ /  / / /_/ / /_  "
print "             _____/____/\___/_/  /_/ .___/\__/  "
print "            /_____/   "
print "            "
print "                            For Juniper"
print ""
print ""    
print "###############################################################################################" 
print "                   Enter The DataCenter or VNAD LE Information Below:" 
print ""  
print "                This Must Exist From Previously Running The VNAD Program" 
print ""  
print "   This Will Write Your Custom Configs to /usr/DataCenters/<your DC directory>/VNAD/configs"
print "             or /usr/VNAD-LEs/<your VNAD Logical Entity Name>/VNAD/configs"
print ""
print "        The Path will depend on if this is a VNAD LE or Tied to a Data-Center/Site"
print "###############################################################################################" 
print "" 

DataCenter = raw_input( "Enter Data_Center or VNAD LE String Here e.g. New-York-DC: " )

class Logger(object):
    def __init__(self):
        self.terminal = sys.stdout
        self.log = open("/usr/VNAD/logs/%s/Juniper_python_script.log" % DataCenter, "w")

    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)  

    def flush(self):
        #this flush method is needed for python 3 compatibility.
        #this handles the flush command by doing nothing.
        #you might want to specify some extra behavior here.
        pass    

sys.stdout = Logger()
#sys.stdout = open('/usr/VNAD/logs/dcdp.log', 'w')

sys.stderr = open("/usr/VNAD/logs/%s/Juniper_python_script_err.log" % DataCenter, "w")


current_time=time.strftime("%Y-%m-%d %H:%M")

username = raw_input( "Enter username: " )
print "   "
print "#### Password will be hidden"
print "#### Please copy and input your password from an unsaved text file, e.g. not written to disk, a or secure database like KeepPass"
print "   "
password = getpass.getpass()
print "   "


######### Declare global dir variables -->
VNADDIR ="/usr/VNAD-LEs/%s" % DataCenter 
DIR = "/usr/DataCenters/%s" % DataCenter 


def cmd_is_valid():
    global cmd_file
    
    while True:
        cmd_file = "ssh_juniper_commands.txt"
        
        #Changing output messages
        if os.path.isfile(cmd_file) == True:
            print "\n* Attempting to connect to device(s)...\n"
            print "\n* Log files (stdout and stderr) will be written to /usr/VNAD/logs for all device(s)...\n"
            break
        
        else:
            print "\n* File %s does not exist! Please check and try again!\n" % cmd_file
            continue

try:
    #Calling command file validity function
    cmd_is_valid()
    
except KeyboardInterrupt:
    print "\n\n* Program aborted by user. Exiting...\n"
    sys.exit()

#setup max number of threads for Semaphore method to use. create sema variable for open ssh function to use
maxthreads = 25
sema = threading.BoundedSemaphore(value=maxthreads)

#Open SSHv2 connection to devices
def open_network_connection(ip):

    try:
        paramiko.util.log_to_file("/usr/VNAD/logs/paramiko.log")   
        #Define SSH parameters
        #Logging into device
        session = paramiko.SSHClient()
        session.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        sema.acquire()
        time.sleep(20)
        sema.release()
        
        session.connect(ip, username = username, password = password)

        connection = session.invoke_shell()	
        #Open user selected file for reading

        selected_cmd_file = open(cmd_file, 'r')
        #Starting from the beginning of the file

        selected_cmd_file.seek(0)

        #Writing each line in the file to the device
        for each_line in selected_cmd_file.readlines():
            connection.send(each_line + '\n')
            time.sleep(8)
        
        #Closing the command file
        selected_cmd_file.close()

#############################################################
        # Get around the 64K bytes (65536). paramiko limitation
        interval = 0.1
        maxseconds = 15
        maxcount = maxseconds / interval
        bufsize = 65535

        input_idx = 0
        timeout_flag = False
        start = datetime.datetime.now()
        start_secs = time.mktime(start.timetuple())
#############################################################
        router_output = ''

        while True:
            if connection.recv_ready():
                data = connection.recv(bufsize).decode('ascii')
                router_output += data

            if connection.exit_status_ready():
                break

            now = datetime.datetime.now()
            now_secs = time.mktime(now.timetuple())

            et_secs = now_secs - start_secs
            if et_secs > maxseconds:
                timeout_flag = True
                break

            rbuffer = router_output.rstrip(' ')
            if len(rbuffer) > 0 and (rbuffer[-1] == '#' or rbuffer[-1] == '>'): ## got a Cisco command prompt
                break
            time.sleep(0.200)
        if connection.recv_ready():
            data = connection.recv(bufsize)
            router_output += data.decode('ascii')
#############################################################
        
        if re.search(r"% Authorization failed", router_output):
            print "   "
            print "** Authorization failed for %s Looks Like a TACACS issue." % ip
            print "** Try and run the program again."
        else:
            print "\nCompleted device %s" % ip

        return router_output
        session.close()

    except paramiko.AuthenticationException:
        pass
        print "   "
        print "* Authentication Error for %s" % ip
        print "   "
        #print "* Closing program...\n"
    except paramiko.SSHException:
        pass
        print "   "
        print "* Incompatible SSH version. Paramiko requires compatible SSH and kex on device %s" % ip


def write_files(ip):
    file_name = '/usr/VNAD-LEs/%s/VNAD/configs/' % DataCenter + ip + '_' + current_time + '_Juniper.txt'
    fo = open(file_name, "w")
    #Calling the SSH function
    router_output = open_network_connection(ip)
    fo.write(router_output)
    fo.close()
    
#Creating threads function
def create_threads():
    threads = []
    for ip in iplist:
        th = threading.Thread(target = write_files, args = (ip,))   #args is a tuple with a single element     
        th.start()
        threads.append(th)
        
    for th in threads:
        th.join()
###################################


###################################
def open_network_connection2(ip):
    try:
        paramiko.util.log_to_file("/usr/VNAD/logs/paramiko.log")   
        #Define SSH parameters
        #Logging into device
        session = paramiko.SSHClient()
        session.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        sema.acquire()
        time.sleep(20)
        sema.release()
        
        session.connect(ip, username = username, password = password)

        connection = session.invoke_shell() 
        #Open user selected file for reading

        selected_cmd_file = open(cmd_file, 'r')
        #Starting from the beginning of the file

        selected_cmd_file.seek(0)

        #Writing each line in the file to the device
        for each_line in selected_cmd_file.readlines():
            connection.send(each_line + '\n')
            time.sleep(8)
        
        #Closing the command file
        selected_cmd_file.close()

#############################################################
        # Get around the 64K bytes (65536). paramiko limitation
        interval = 0.1
        maxseconds = 15
        maxcount = maxseconds / interval
        bufsize = 65535

        input_idx = 0
        timeout_flag = False
        start = datetime.datetime.now()
        start_secs = time.mktime(start.timetuple())
#############################################################
        router_output = ''

        while True:
            if connection.recv_ready():
                data = connection.recv(bufsize).decode('ascii')
                router_output += data

            if connection.exit_status_ready():
                break

            now = datetime.datetime.now()
            now_secs = time.mktime(now.timetuple())

            et_secs = now_secs - start_secs
            if et_secs > maxseconds:
                timeout_flag = True
                break

            rbuffer = router_output.rstrip(' ')
            if len(rbuffer) > 0 and (rbuffer[-1] == '#' or rbuffer[-1] == '>'): ## got a Cisco command prompt
                break
            time.sleep(0.200)
        if connection.recv_ready():
            data = connection.recv(bufsize)
            router_output += data.decode('ascii')
#############################################################

        if re.search(r"% Authorization failed", router_output):
            print "   "
            print "** Authorization failed for %s Looks Like a TACACS issue." % ip
            print "** Try and run the program again."
        else:
            print "\nCompleted device %s" % ip

        return router_output
        session.close()

    except paramiko.AuthenticationException:
        pass
        print "   "
        print "* Authentication Error for %s" % ip
        print "   "
        #print "* Closing program...\n"
    except paramiko.SSHException:
        pass
        print "   "
        print "* Incompatible SSH version. Paramiko requires compatible SSH and kex on device %s" % ip


def write_files2(ip):
    file_name = '/usr/DataCenters/%s/VNAD/configs/' % DataCenter + ip + '_' + current_time + '_Juniper.txt'
    fo = open(file_name, "w")
    #Calling the SSH function
    router_output = open_network_connection2(ip)
    fo.write(router_output)
    fo.close()
    
#Creating threads function
def create_threads2():
    threads = []
    for ip in iplist2:
        th = threading.Thread(target = write_files2, args = (ip,))   #args is a tuple with a single element     
        th.start()
        threads.append(th)
        
    for th in threads:
        th.join()
###################################


###################################
if (os.path.isdir(VNADDIR)):
    print "Calling SSH Connection to VNAD-LE Juniper nodes..."
    print "\n* Output files will be written to /usr/VNAD-LEs/%s/VNAD/configs for all device(s)...\n" % DataCenter
    iplist = open('/usr/VNAD-LEs/%s/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt' % DataCenter).readlines()
    # remove return from file names, e.g. remove \n from list
    iplist = map(lambda s: s.strip(), iplist)
    create_threads()
    # If VNADDIR exists, create threads runs on VNAD LE folder -->
else:
    print "Calling SSH Connection to Data-Center VNAD Juniper nodes..."
    print "\n* Output files will be written to /usr/DataCenters/%s/VNAD/configs for all device(s)...\n" % DataCenter
    iplist2 = open('/usr/DataCenters/%s/VNAD/IP-Lists/Juniper/Juniper_ip_file-py.txt' % DataCenter).readlines()
    # remove return from file names, e.g. remove \n from list
    iplist2 = map(lambda s: s.strip(), iplist2)
    create_threads2()
    # If VNADDIR doesnt exist, create threads2 runs on DC VNAD folder by default
###################################