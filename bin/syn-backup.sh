#/!/bin/sh

# Manually generate gpg keys
# 	https://help.ubuntu.com/community/GnuPrivacyGuardHowto
#
# 	gpg2 --gen-key 
# 	gpg2 --cert-digest-algo=SHA256 --edit-key $GPGKEY
# 
# Add to /root/.profile
# 	export GPGKEY=D8FC66D2
# 	killall -q gpg-agent
# 	eval $(gpg-agent --daemon)
# 	source ~/.profile
#
# To later decrypt the file.
# 	gpg2 --decrypt-files --decrypt cryptme.txt.gpg  

# Install with
# 	cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-backup.sh /opt/bin/
# 	chmod +x /opt/bin/syn-backup.sh

# Install rsnapshot
# 	http://forum.synology.com/wiki/index.php/Overview_on_modifying_the_Synology_Server,_bootstrap,_ipkg_etc
# 	http://www.kevitivity.com/2012/11/integrating-rsnapshot-backups-with-synology-nas-systems/comment-page-1/#comment-5124

# Configure /etc/crontab
# 0       06      *       *       *       root    /opt/bin/rsnapshot daily 
# 0       07      *       *       6       root    /opt/bin/rsnapshot weekly
# 0       08      1       *       *       root    /opt/bin/rsnapshot monthly
# 0       09      *       *       6       root    /opt/bin/syn-backup.sh
#
# /usr/syno/etc/rc.d/S04crond.sh stop
# /usr/syno/etc/rc.d/S04crond.sh start

YM=`date +"%Y-%m"`
SUBJECT="file-au - syn-backup $YM"
TO_EMAIL="daniel@cybercow.se"
LOG_FILE="/volume1/backup/rsnapshot_bak/$YM.log"
TAR_FILE="/volume1/backup/rsnapshot_bak/$YM.tar"
GPG_FILE="/volume1/backup/rsnapshot_bak/$YM.tar.gpg"
REMOTE_FILE="/volume1/backup/rsnapshot_bak/remote.gpg"

# Redirect all output to file
exec 1>>$LOG_FILE 2>>$LOG_FILE


# Create one compressed archive for every month, forever. 
# If the script is executed several times the same month, only one file will be stored.
echo "Create backup $TAR_FILE"
[ -e $TAR_FILE ] && rm $TAR_FILE && echo "Removed $TAR_FILE"
cd /volume1/backup/rsnapshot_bak/
tar cf $TAR_FILE daily.0


# 
echo "Encrypt $TAR_FILE.gpg"
gpg2 -r daniel --encrypt $TAR_FILE


# 
echo "Only one encrypted file will be stored."
[ -e $REMOTE_FILE ] && rm $REMOTE_FILE && echo "Removed $REMOTE_FILE"
mv $GPG_FILE $REMOTE_FILE


# 
echo "Upload to nebol"
cat > batch << EOF
cd home
put $REMOTE_FILE
EOF
sftp -b batch -oPort=43 masterpo@www.nebol.se
rm batch


#
echo "Email log"

# send the TO_EMAIL
cat $LOG_FILE | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL


# if the TO_EMAIL fails nail will create a file dead.letter, test to see if it exists and if so 
# wait 1minute and then resend
while [ -e /root/dead.letter ]
do
  	sleep 60
  	rm "/root/dead.letter"
  	echo "$SUBJECT" | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL
done

exit
