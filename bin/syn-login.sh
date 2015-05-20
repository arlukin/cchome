#!/bin/sh
#
# Sends a synosyslogmail to say someone just logged in to the Command Line Interface.
#
# Install with
# 	cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-login.sh /usr/bin/
# 	chmod +x /usr/bin/syn-login.sh
# 	echo "(sh /usr/bin/syn-login.sh) &" >> /etc/profile
#
# __author__ = "daniel.lindh@cybercow.se"
# __copyright__ = "Copyright 2015, Daniel Lindh"
# __license__ = "http://creativecommons.org/licenses/by/3.0/deed.en_US"
# __version__ = "0.2"
# __status__ = "Production"


# To turn echo off so the logged in user doesn't know the script is running
# redirect stdout(1) and stderr(2) to null:
exec 1>/dev/null 2>/dev/null

MESSAGE="User `whoami` logged in at `date +"%Y-%m-%d %T"`."
synosyslogmail --mailtype=KEYWORD --keyword="SSH-LOGIN" --content="$MESSAGE" 
              
exit
