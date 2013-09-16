#!/bin/sh
#
# Archive (tar) a folder, encrypt (gpg2) and send to a remote host.
#
# Install with
#   echo "PATH=\$PATH:/opt/bin" >> /root/.profile
#   source /root/.profile
#
#   # Need some packages
#   /opt/bin/ipkg install gnupg???
#   /opt/bin/ipkg install pinentry
#
#   cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-backup.sh /opt/bin/
#   chmod +x /opt/bin/syn-backup.sh
#
# Manually generate gpg keys
#   https://help.ubuntu.com/community/GnuPrivacyGuardHowto
#
#   killall -q gpg-agent
#   mkdir -p -m 700 ~/.gnupg
#   echo "pinentry-program /opt/bin/pinentry-curses" >> /root/.gnupg/gpg-agent.conf
#   eval $(gpg-agent --daemon)
#
#   gpg2 --gen-key
#   GPGKEY=4BF5A575
#   gpg2 --cert-digest-algo=SHA256 --edit-key $GPGKEY
#
#   # Add to /root/.profile
#   echo "export GPGKEY=4BF5A575" >> /root/.profile
#
#   killall -q gpg-agent
#   source ~/.profile
#   eval $(gpg-agent --daemon)
#
# To later decrypt the file.
#   gpg2 --decrypt-files --decrypt *.gpg
#   cat 2013-04-monthly_backup.split* | /opt/bin/tar xv
#   cat 2013-04-17-week_incr_backup.split* | /opt/bin/tar x
#   cat 2013-04-17-28-daily_incr_backup.split* | /opt/bin/tar x
#
#
# Install rsnapshot
#   http://forum.synology.com/wiki/index.php/Overview_on_modifying_the_Synology_Server,_bootstrap,_ipkg_etc
#   http://www.kevitivity.com/2012/11/integrating-rsnapshot-backups-with-synology-nas-systems/comment-page-1/#comment-5124
#
# Configure /etc/crontab
# 0       00      *       *       *       root    /opt/bin/rsnapshot daily
# 0       03      *       *       6       root    /opt/bin/rsnapshot weekly
# 0       06      1       *       *       root    /opt/bin/rsnapshot monthly
# 0       09      *       *       6       root    /opt/bin/syn-backup.sh
#
# /usr/syno/etc/rc.d/S04crond.sh stop
# /usr/syno/etc/rc.d/S04crond.sh start

__author__="daniel.lindh@cybercow.se"
__copyright__="Copyright 2013, Daniel Lindh"
__license__="http://creativecommons.org/licenses/by/3.0/deed.en_US"
__version__="0.2"
__status__="Production"


#
# SETTINGS
#

# Email
SUBJECT="file-au - syn-backup $YM"
TO_EMAIL="daniel@cybercow.se"

# Remote sftp server
REMOTE_HOST="masterpo@www.nebol.se"
REMOTE_PORT="43"

# Folder to backup
#   Should not start with slash and be specified from root.
FOLDER_TO_BACKUP="volume1/backup/rsnapshot/daily.0"
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

print_log ()
{
    echo "`date +"%T"` - $1"
}

app_exist() {
    which $1 >/dev/null
    [ $? -ne 0 ] && echo "$1 can't be found." && exit 1

}


verify_app_existence () {
    app_exist split
    app_exist tar
    app_exist gpg
    app_exist gpg2
    app_exist nail
}


upload () {
    #
    print_log "Upload to remote server."

    #
    print_log "Upload - create batch."

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
    print_log "Batch file contains"
    cat $BATCH_FILE

    #
    print_log "Upload - do the upload. $BATCH_FILE $REMOTE_HOST:$REMOTE_PORT "
    #sftp -b $BATCH_FILE -oPort=$REMOTE_PORT $REMOTE_HOST

    #
    print_log "Upload - remove batch."
    rm $BATCH_FILE

    #
    print_log "Upload - remove gpg."
    for gpg in $1*.gpg;
    do
        rm $gpg;
    done
}


send_log_on_email () {
    # send the TO_EMAIL
    print_log "Send email to $TO_EMAIL"
    [ -d "/root/dead.letter" ] && rm "/root/dead.letter"
    cat $LOG_FILE | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL

    # if the TO_EMAIL fails nail will create a file dead.letter, test to see if
    # it exists and if so  wait 1 minute and then resend
    while [ -e /root/dead.letter ]
    do
        print_log "Failed to send email, retry in 60 seconds."
        sleep 60
        rm "/root/dead.letter"
        print_log "$SUBJECT" | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL
    done

}


create_monthly_backup () {
    create_backup $MONTHLY_BACKUP_FOLDER $MONTHLY_SPLIT_FILE

    print_log "Create monthly snapshot of snar file - $MONTHLY_SNAR_FILE"
    cp $SNAR_FILE $MONTHLY_SNAR_FILE
}


create_weekly_backup () {
    print_log "Restore monthly snar file."
    cp $MONTHLY_SNAR_FILE $SNAR_FILE

    create_backup $WEEK_BACKUP_FOLDER $WEEK_SPLIT_FILE

    print_log "Create weekly snapshot of snar file."
    cp $SNAR_FILE $WEEK_SNAR_FILE
}


create_dailly_backup () {
    print_log "Restore weekly snar file."
    cp $WEEK_SNAR_FILE $SNAR_FILE

    create_backup $DAILY_BACKUP_FOLDER $DAILY_SPLIT_FILE
}


create_backup () {
    BACKUP_FOLDER=$1
    SPLIT_FILE=$2

    print_log "Create folders - $BACKUP_FOLDER."
    mkdir -p $BACKUP_FOLDER

    print_log "Create incremental archive - $SPLIT_FILE."
    cd /
    /opt/bin/tar c -g $SNAR_FILE $FOLDER_TO_BACKUP | \
        split -d -b $SPLIT_SIZE - $SPLIT_FILE

    print_log "Encrypt - $SPLIT_FILE*"
    gpg2 --compress-level 0 --recipient daniel --batch  \
         --encrypt-files --encrypt $SPLIT_FILE*

    print_log "All files in $BACKUP_FOLDER"
    ls $BACKUP_FOLDER
    print_log

    #upload $SPLIT_FILE
}


main () {
    verify_app_existence
    print_log "Create print_log folder."
    mkdir -p $BACKUP_FOLDER

    print_log "Redirect all output to $LOG_FILE."
    touch $LOG_FILE
    exec 1>>$LOG_FILE 2>>$LOG_FILE
    print_log
    print_log

    print_log "syn-backup started."
    print_log "Backup $FOLDER_TO_BACKUP"

    [ -d "$MONTHLY_BACKUP_FOLDER" ] && print_log "Monthly backup already done."
    [ -d "$WEEK_BACKUP_FOLDER" ] && print_log "Weekly backup already done."
    [ -d "$DAILY_BACKUP_FOLDER" ] && print_log "Daily backup already done."

    # All fast operations done, now tell myself the backup routine is started.
    send_log_on_email

    if [ ! -d "$MONTHLY_BACKUP_FOLDER" ]; then
        create_monthly_backup
    elif [ ! -d "$WEEK_BACKUP_FOLDER" ]; then
        create_weekly_backup
    elif [ ! -d "$DAILY_BACKUP_FOLDER" ]; then
        create_dailly_backup
    fi

    print_log "syn-backup ended."
    print_log
    print_log
    send_log_on_email
}


main
