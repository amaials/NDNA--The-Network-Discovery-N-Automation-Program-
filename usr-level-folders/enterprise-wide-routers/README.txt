
        ####### README ####### 

Create any type of IP Router list you'd like, 

For example:

Running the provided scripts you can:

1. Create an enterprise wide IP list of IOS Routers.

2. Create an enterprise wide IP list of NXOS Routers.

3. Create an enterprise wide IP list of Routers. (includes BOTH NXOS and IOS)

4. Create your own list manually and put into the "enterprise-wide-routers-IPs.txt" file

After you've run any above script to create your custom router IP Lists, you must copy and paste it into the:
"enterprise-wide-routers-IPs.txt" file located in this folder

Then, you can run the enterprise-wide-routers.py script in the custom scripts folder
(/usr/DCDP/bin/python_custom_scripts/enterprise-wide-routers) which looks for this file (/usr/enterprise-wide-routers/enterprise-wide-routers-IPs.txt)
to determine which routers to connect to.