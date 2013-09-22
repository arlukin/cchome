#!/bin/sh
#
# Archive (tar) a folder, encrypt (gpg2) and sftp to a remote host.
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
# Decrypt the archive.
#   gpg2 --decrypt-files --decrypt *.gpg
#   cat 2013-04-monthly_backup.split* | /opt/bin/tar xv
#   cat 2013-04-17-week_incr_backup.split* | /opt/bin/tar x
#   cat 2013-04-17-28-daily_incr_backup.split* | /opt/bin/tar x
#
# Extract the archive (need reversed split)
#  /opt/bin/tar --list --listed-incremental=/dev/null --file 2013-09-17-full.split00
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
# 0       09      *       *       1       root    /opt/bin/syn-backup.sh  etc            /volume1/backup/syn-backup etc
# 0       09      *       *       2       root    /opt/bin/syn-backup.sh  opt/etc        /volume1/backup/syn-backup opt-etc
# 0       09      *       *       3       root    /opt/bin/syn-backup.sh  volume1/homes  /volume1/backup/syn-backup home
# 0       09      *       *       4       root    /opt/bin/syn-backup.sh  volume1/lindh  /volume1/backup/syn-backup lindh
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
SUBJECT="file-au - syn-backup"
TO_EMAIL="daniel@cybercow.se"

# Remote sftp server
REMOTE_HOST="masterpo@www.nebol.se"
REMOTE_PORT="43"

# Folder to backup
FOLDER_TO_BACKUP="$1"

# Where to locally store the backups
BACKUP_ROOT_FOLDER="$2"

# Backup name
BACKUP_NAME="$3"


#
# Constants
#

Y=`date +"%Y"`
M=`date +"%m"`
W=`date '+%U'`
D=`date '+%d'`
YMD=`date +"%Y-%m-%d"`

SPLIT_SIZE="4096m"

PROGRAM_NAME=$0

BACKUP_FOLDER="$BACKUP_ROOT_FOLDER/$Y/$BACKUP_NAME"

LOG_FILE="$BACKUP_FOLDER/$YMD-backup.log"
BATCH_FILE="$BACKUP_FOLDER/$YMD-upload.batch"

FULL_BACKUP_FOLDER="$BACKUP_FOLDER"
FULL_SPLIT_FILE="$FULL_BACKUP_FOLDER/$BACKUP_NAME-$YMD-full.split"
FULL_SNAR_FILE="$FULL_BACKUP_FOLDER/full.snar"

MONTHLY_BACKUP_FOLDER="$FULL_BACKUP_FOLDER/$M"
MONTHLY_SPLIT_FILE="$MONTHLY_BACKUP_FOLDER/$BACKUP_NAME-$YMD-monthly-inc.split"
MONTHLY_SNAR_FILE="$MONTHLY_BACKUP_FOLDER/month.snar"

WEEK_BACKUP_FOLDER="$MONTHLY_BACKUP_FOLDER/week_$W"
WEEK_SPLIT_FILE="$WEEK_BACKUP_FOLDER/$BACKUP_NAME-$YMD-week-inc.split"
WEEK_SNAR_FILE="$WEEK_BACKUP_FOLDER/week.snar"

DAILY_BACKUP_FOLDER="$WEEK_BACKUP_FOLDER/$D"
DAILY_SPLIT_FILE="$DAILY_BACKUP_FOLDER/$BACKUP_NAME-$YMD-daily-inc.split"
DAILY_SNAR_FILE="$DAILY_BACKUP_FOLDER/day.snar"


print_log ()
{
    echo "`date +"%T"` - $1"
}

print_help ()
{
    echo "$PROGRAM_NAME opt/etc /opt/backups opt-etc"
    echo "  Note where the slashes are."
    echo "  src should not start with slash and be specified from root"
}


app_exist() {
    which $1 >/dev/null
    [ $? -ne 0 ] && echo "$1 can't be found" && exit 1

}


verify_requirements () {
    # Required linux tools
    app_exist split
    app_exist tar
    app_exist gpg
    app_exist gpg2
    app_exist nail

    # Validate
    if [ -z "$FOLDER_TO_BACKUP" ]; then
        echo "You need to enter folder to backup"
        print_help
        exit
    fi

    if [ -z "$BACKUP_ROOT_FOLDER" ]; then
        echo "You need to enter folder to backup to"
        print_help
        exit
    fi

    if [ -z "$BACKUP_NAME" ]; then
        echo "You need to enter a backup name"
        print_help
        exit
    fi
}


upload () {
    #
    print_log "  Upload to remote server"

    #
    print_log "    Create batch"

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
    print_log "    Batch file contains"
    cat $BATCH_FILE
    echo ""

    #
    print_log "    Do the upload - $BATCH_FILE $REMOTE_HOST:$REMOTE_PORT "
    sftp -b $BATCH_FILE -oPort=$REMOTE_PORT $REMOTE_HOST

    #
    print_log "    Remove batch"
    rm $BATCH_FILE

    #
    print_log "    Remove gpg"
    rm $1*.gpg
}


send_log_on_email () {
    print_log "Send email to $TO_EMAIL"
    SUBJECT_FOLDER_TO_BACKUP="$SUBJECT - $FOLDER_TO_BACKUP"

    [ -d "/root/dead.letter" ] && rm "/root/dead.letter"
    cat $LOG_FILE | /opt/bin/nail -s "$SUBJECT_FOLDER_TO_BACKUP" $TO_EMAIL

    # If the TO_EMAIL fails, nail will create the file dead.letter, test to see
    # if it exists and if so wait 1 minute and then resend
    while [ -e /root/dead.letter ]
    do
        print_log "  Failed to send email, retry in 60 seconds"
        sleep 60
        rm "/root/dead.letter"
        cat $LOG_FILE | /opt/bin/nail -s "$SUBJECT_FOLDER_TO_BACKUP" $TO_EMAIL
    done
}


create_full_backup () {
    print_log "Do full backup"
    create_backup $FULL_BACKUP_FOLDER $FULL_SPLIT_FILE $FULL_SNAR_FILE
}


create_monthly_backup () {
    print_log "Do monthly backup"

    print_log "  Create folders - $MONTHLY_BACKUP_FOLDER"
    mkdir -p $MONTHLY_BACKUP_FOLDER

    print_log "  Restore full snar file"
    cp $FULL_SNAR_FILE $MONTHLY_SNAR_FILE

    create_backup $MONTHLY_BACKUP_FOLDER $MONTHLY_SPLIT_FILE $MONTHLY_SNAR_FILE
}


create_weekly_backup () {
    print_log "Do weekly backup"

    print_log "  Create folders - $WEEK_BACKUP_FOLDER"
    mkdir -p $WEEK_BACKUP_FOLDER

    print_log "  Restore monthly snar file"
    cp $MONTHLY_SNAR_FILE $WEEK_SNAR_FILE

    create_backup $WEEK_BACKUP_FOLDER $WEEK_SPLIT_FILE $WEEK_SNAR_FILE
}


create_daily_backup () {
    print_log "Do daily backup"

    print_log "  Create folders - $DAILY_BACKUP_FOLDER"
    mkdir -p $DAILY_BACKUP_FOLDER

    print_log "  Restore weekly snar file"
    cp $WEEK_SNAR_FILE $DAILY_SNAR_FILE

    create_backup $DAILY_BACKUP_FOLDER $DAILY_SPLIT_FILE $DAILY_SNAR_FILE
}


create_backup () {
    BACKUP_FOLDER=$1
    SPLIT_FILE=$2
    SNAR_FILE=$3

    print_log "  Create incremental archive - $SPLIT_FILE"
    cd /
    /opt/bin/tar c --no-check-device -g $SNAR_FILE $FOLDER_TO_BACKUP | \
        split -d -b $SPLIT_SIZE - $SPLIT_FILE

    print_log "  Encrypt - $SPLIT_FILE*"
    gpg2 --compress-level 0 --recipient daniel --batch  \
         --encrypt-files --encrypt $SPLIT_FILE*

    print_log "  All files in $BACKUP_FOLDER"
    ls -hal $BACKUP_FOLDER
    echo ""

    upload $SPLIT_FILE
}


store_to_logfile () {
    touch $LOG_FILE

    # Stdout is not a terminal.
    npipe=/tmp/$$.tmp
    trap "rm -f $npipe" EXIT
    mknod $npipe p
    tee <$npipe $LOG_FILE &
    exec 1>&-
    exec 1>$npipe
}


main () {
    verify_requirements
    mkdir -p $BACKUP_FOLDER
    store_to_logfile

    print_log "syn-backup started"
    print_log "Backup /${FOLDER_TO_BACKUP} to $BACKUP_ROOT_FOLDER"
    print_log "  Logfile can be found at $LOG_FILE "

    [ -f "$FULL_SNAR_FILE" ] && print_log "  Full backup already done"
    [ -d "$MONTHLY_BACKUP_FOLDER" ] && print_log "  Monthly backup already done"
    [ -d "$WEEK_BACKUP_FOLDER" ] && print_log "  Weekly backup already done"
    [ -d "$DAILY_BACKUP_FOLDER" ] && print_log "  Daily backup already done"

    # All fast operations done, now tell myself the backup routine is started.
    send_log_on_email

    if [ ! -f "$FULL_SNAR_FILE" ]; then
        create_full_backup
    elif [ ! -d "$MONTHLY_BACKUP_FOLDER" ]; then
        create_monthly_backup
    elif [ ! -d "$WEEK_BACKUP_FOLDER" ]; then
        create_weekly_backup
    elif [ ! -d "$DAILY_BACKUP_FOLDER" ]; then
        create_daily_backup
    fi

    print_log "syn-backup ended"
    print_log
    send_log_on_email
}


main
