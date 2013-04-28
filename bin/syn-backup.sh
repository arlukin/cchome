#!/bin/sh
#
# Archive (tar) all files in a folder, encrypt (gpg2) the and send (sftp) to a remote host.
#
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
# 	gpg2 --decrypt-files --decrypt *.gpg
#   cat 2013-04-monthly_backup.split* | /opt/bin/tar xv
#   cat 2013-04-17-week_incr_backup.split* | /opt/bin/tar x
#   cat 2013-04-17-28-daily_incr_backup.split* | /opt/bin/tar x
#
# Install with
# 	cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-backup.sh /opt/bin/ && chmod +x /opt/bin/syn-backup.sh
# 	
# Install rsnapshot
# 	http://forum.synology.com/wiki/index.php/Overview_on_modifying_the_Synology_Server,_bootstrap,_ipkg_etc
# 	http://www.kevitivity.com/2012/11/integrating-rsnapshot-backups-with-synology-nas-systems/comment-page-1/#comment-5124
#
# Configure /etc/crontab
# 0       06      *       *       *       root    /opt/bin/rsnapshot daily 
# 0       07      *       *       6       root    /opt/bin/rsnapshot weekly
# 0       08      1       *       *       root    /opt/bin/rsnapshot monthly
# 0       09      *       *       6       root    /opt/bin/syn-backup.sh
#
# /usr/syno/etc/rc.d/S04crond.sh stop
# /usr/syno/etc/rc.d/S04crond.sh start

__author__ = "daniel.lindh@cybercow.se"
__copyright__ = "Copyright 2013, Daniel Lindh"
__license__ = "http://creativecommons.org/licenses/by/3.0/deed.en_US"
__version__ = "0.1"
__status__ = "Production"


#
# SETTINGS
#

# Email
SUBJECT="file-au - syn-backup $YM"
TO_EMAIL="daniel@cybercow.se"

# Remote sftp server
REMOTE_HOST="masterpo@www.nebol.se"
REMOTE_PORT="43"

# Folder to backpu
FOLDER_TO_BACKUP="volume1/backup/rsnapshot_bak/daily.0"
#FOLDER_TO_BACKUP="$1"

# Where to locally store the backups
BACKUP_ROOT_FOLDER="/volume1/backup/syn-backup"
#BACKUP_ROOT_FOLDER="$2"


# Validate
if [ -z "$FOLDER_TO_BACKUP" ]; then
    echo "You need to enter folder to backup."
fi

if [ -z "$BACKUP_ROOT_FOLDER" ]; then
    echo "You need to enter folder to backup to."
fi

#
# Constants
#
YM=`date +"%Y-%m"`
W=`date '+%U'`
D=`date '+%d'`

SPLIT_SIZE="1024m"

BACKUP_FOLDER="$BACKUP_ROOT_FOLDER/$YM"

LOG_FILE="$BACKUP_FOLDER/backup.log"
SNAR_FILE="$BACKUP_FOLDER/backup.snar"
BATCH_FILE="$BACKUP_FOLDER/upload.batch"

MONTHLY_BACKUP_FOLDER="$BACKUP_FOLDER/full"
MONTHLY_SPLIT_FILE="$MONTHLY_BACKUP_FOLDER/$YM-monthly_backup.split"
MONTHLY_SNAR_FILE="$MONTHLY_BACKUP_FOLDER/backup.snar"

WEEK_BACKUP_FOLDER="$BACKUP_FOLDER/week_$W"
WEEK_SPLIT_FILE="$WEEK_BACKUP_FOLDER/$YM-$W-week_incr_backup.split"
WEEK_SNAR_FILE="$WEEK_BACKUP_FOLDER/backup.snar"

DAILY_BACKUP_FOLDER="$BACKUP_FOLDER/week_$W/$D"
DAILY_SPLIT_FILE="$DAILY_BACKUP_FOLDER/$YM-$W-$D-daily_incr_backup.split"


upload () {
	#
	echo "Upload to remote server."

	# 
	echo "Upload - create batch."

	cat > $BATCH_FILE << EOF
cd home
EOF
	
	for gpg in $1*.gpg;
	do 
	cat >> $BATCH_FILE << EOF
put $gpg
EOF
	done

	# 
	echo "Upload - do the upload."
	sftp -b $BATCH_FILE -oPort=$REMOTE_PORT $REMOTE_HOST

	# 
	echo "Upload - remove batch."
	rm $BATCH_FILE

	#
	echo "Upload - remove gpg."
	for gpg in $1*.gpg;
	do 
		rm $gpg;
	done
}


send_log_on_email () {
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

}


create_monthly_backup () {	
	create_backup $MONTHLY_BACKUP_FOLDER $MONTHLY_SPLIT_FILE

	echo "Create monthly snapshot of snar file."
	cp $SNAR_FILE $MONTHLY_SNAR_FILE
}


create_weekly_backup () {		
	echo "Restore monthly snar file."
	cp $MONTHLY_SNAR_FILE $SNAR_FILE

	create_backup $WEEK_BACKUP_FOLDER $WEEK_SPLIT_FILE

	echo "Create weekly snapshot of snar file."
	cp $SNAR_FILE $WEEK_SNAR_FILE
}


create_dailly_backup () {			
	echo "Restore weekly snar file."
	cp $WEEK_SNAR_FILE $SNAR_FILE

	create_backup $DAILY_BACKUP_FOLDER $DAILY_SPLIT_FILE
}


create_backup () {
	BACKUP_FOLDER=$1
	SPLIT_FILE=$2

	echo "Create folders."
	mkdir -p $BACKUP_FOLDER

	echo "Create incremental archive $SPLIT_FILE."
	cd /
	/opt/bin/tar c -g $SNAR_FILE $FOLDER_TO_BACKUP | split -d -b $SPLIT_SIZE - $SPLIT_FILE

	echo "Encrypt."
	gpg2 --compress-level 0 --encrypt-files --batch -r daniel --encrypt $SPLIT_FILE*

	upload $SPLIT_FILE
}


main () {
	echo "Create log folder."
	mkdir -p $BACKUP_FOLDER

	echo "Redirect all output to $LOG_FILE."
	touch $LOG_FILE
	exec 1>>$LOG_FILE 2>>$LOG_FILE

	echo "syn-backup started at `date +"%T"`."
	echo "Backup $FOLDER_TO_BACKUP"
	send_log_on_email

	[ -d "$MONTHLY_BACKUP_FOLDER" ] && echo "Monthly backup already done."
	[ -d "$WEEK_BACKUP_FOLDER" ] && echo "Weekly backup already done."
	[ -d "$DAILY_BACKUP_FOLDER" ] && echo "Daily backup already done."

	if [ ! -d "$MONTHLY_BACKUP_FOLDER" ]; then
		create_monthly_backup	
	elif [ ! -d "$WEEK_BACKUP_FOLDER" ]; then
		create_weekly_backup
	elif [ ! -d "$DAILY_BACKUP_FOLDER" ]; then
		create_dailly_backup
	fi

	echo "syn-backup ended at `date +"%T"`."
	send_log_on_email
}


main