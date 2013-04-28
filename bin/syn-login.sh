#!/bin/sh
#
# Sends an email to say someone just logged in to the Command Line Interface.
#
# Based on
# 	http://forum.synology.com/wiki/index.php/How_to_get_the_NAS_to_TO_EMAIL_you_everytime_someone_logs_into_the_CLI
# 
# Install nail (required)
#	http://forum.synology.com/wiki/index.php/A_short_list_of_the_more_useful_900%2B_ipkg_packages
#
# ipkg install nail
# 
# Remove from /opt/etc/nail.rc
# 	set hold  
#
# Insert at end of /opt/etc/nail.rc
# 	# Google account                                                                                                                                                                                                                                 
#	set smtp-use-starttls
#	set smtp=smtp.gmail.com:587
#	set from=[account]@gmail.com
#	set smtp-auth=login
#	set smtp-auth-user=[account]@gmail.com
#	set smtp-auth-password=[password]
#	set ssl-verify=ignore
#
# Install with
# 	cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-login.sh /opt/bin/
# 	chmod +x /opt/bin/syn-login.sh
# 	echo "(sh /opt/bin/syn-login.sh) &" >> /etc/profile

__author__ = "daniel.lindh@cybercow.se"
__copyright__ = "Copyright 2013, Daniel Lindh"
__license__ = "http://creativecommons.org/licenses/by/3.0/deed.en_US"
__version__ = "0.1"
__status__ = "Production"


# To turn echo off so the logged in user doesn't know the script is running
# redirect stdout(1) and stderr(2) to null:
exec 1>/dev/null 2>/dev/null


#set the subject of the TO_EMAIL
SUBJECT="file-au - A user has logged in to the CLI"
TO_EMAIL="daniel@cybercow.se"
MESSAGE="User `whoami` logged in at `date +"%Y-%m-%d %T"`."


# send the TO_EMAIL
echo "$MESSAGE" | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL


# if the TO_EMAIL fails nail will create a file dead.letter, test to see if it exists and if so 
# wait 1minute and then resend


while [ -e /root/dead.letter ]
do
  	sleep 60
  	rm "/root/dead.letter"
  	echo "$MESSAGE" | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL
done

exit
