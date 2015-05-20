#!/opt/bin/bash
#
# Archive (tar) a folder, encrypt (gpg2) and sftp to a remote host.
#
# Install with
#   echo "PATH=\$PATH:/opt/bin" >> /root/.profile
#   source /root/.profile
#
# Install ipkg
#   http://forum.synology.com/wiki/index.php/Overview_on_modifying_the_Synology_Server,_bootstrap,_ipkg_etc
#   http://www.kevitivity.com/2012/11/integrating-rsnapshot-backups-with-synology-nas-systems/comment-page-1/#comment-5124
#
#   # Need some packages
#   /opt/bin/ipkg install gnupg???
#    /opt/bin/ipkg install pinentry
#
#   cp /volume1/homes/arlukin/CloudStation/cchome/bin/syn-backup.sh /opt/bin/
#   chmod +x /opt/bin/syn-backup.sh
#
#   https://help.ubuntu.com/community/GnuPrivacyGuardHowto
# Manually generate gpg keys
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
#   cat 2013-04-month_backup.split* | /opt/bin/tar xv
#   cat 2013-04-17-week_incr_backup.split* | /opt/bin/tar x
#   cat 2013-04-17-28-day_incr_backup.split* | /opt/bin/tar x
#
# Extract the archive (need reversed split)
#  /opt/bin/tar --list --listed-incremental=/dev/null --file 2013-09-17-full.split00
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

# Email to send logs/reports to
TO_EMAIL="daniel@cybercow.se"

# Remote sftp server
REMOTE_HOST="masterpo@www.nebol.se"
REMOTE_PORT="43"

# Where to locally store the backups
BACKUP_STORE="/volume1/backup/syn-backup"

# Folder to backup
FOLDERS_TO_BACKUP[0]="etc"
FOLDERS_TO_BACKUP[1]="volume1/homes"
FOLDERS_TO_BACKUP[2]="volume1/lindh"

# The size of each tar file.
SPLIT_SIZE="4096m"


#
# Constants
#

Y=`date +"%Y"`
M=`date +"%m"`
W=`date '+%U'`
D=`date '+%d'`
YMD=`date +"%Y-%m-%d"`
HMS=`date +"%T"`

PROGRAM_NAME=$0
HOSTNAME=`hostname`

BACKUP_FOLDER="$BACKUP_STORE/$Y"
LOG_FILE="$BACKUP_FOLDER/backup-$YMD.log"
BATCH_FILE="$BACKUP_FOLDER/upload-$YMD.batch"


# Think of those variables as class variables to object/function backup()
set_all_pathes ()
{
    BACKUP_NAME=$1
    BACKUP_NAME=${BACKUP_NAME##*/}

    FULL_BACKUP_FOLDER="$BACKUP_FOLDER"
    FULL_SPLIT_FILE="$FULL_BACKUP_FOLDER/$BACKUP_NAME-$YMD-full.split"
    FULL_SNAR_FILE="$FULL_BACKUP_FOLDER/$BACKUP_NAME-full.snar"

    MONTH_BACKUP_FOLDER="$FULL_BACKUP_FOLDER/$M"
    MONTH_SPLIT_FILE="$MONTH_BACKUP_FOLDER/$BACKUP_NAME-$YMD-month.split"
    MONTH_SNAR_FILE="$MONTH_BACKUP_FOLDER/$BACKUP_NAME-month.snar"

    WEEK_BACKUP_FOLDER="$MONTH_BACKUP_FOLDER/week_$W"
    WEEK_SPLIT_FILE="$WEEK_BACKUP_FOLDER/$BACKUP_NAME-$YMD-week.split"
    WEEK_SNAR_FILE="$WEEK_BACKUP_FOLDER/$BACKUP_NAME-week.snar"

    DAY_BACKUP_FOLDER="$WEEK_BACKUP_FOLDER/$D"
    DAY_SPLIT_FILE="$DAY_BACKUP_FOLDER/$BACKUP_NAME-$YMD-day.split"
    DAY_SNAR_FILE="$DAY_BACKUP_FOLDER/$BACKUP_NAME-day.snar"
}


# Used for all log print.
print_log ()
{
    echo "`date +"%T"` - $1"
    echo "`date +"%T"` - $1" >&3
}


# Check if application is installed and in PATH
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
}


# All outputs goes both to stdout and log file
store_to_logfile () {
    touch $LOG_FILE

    exec 3>&1
    exec > $LOG_FILE 2>&1
}


upload () {
    print_log "  Upload to remote server"
    print_log "--------------- WARNING ---------- "
    print_log "    Create upload batch file"

    cat > $BATCH_FILE << EOF
cd home
EOF

    for gpg in $1*.gpg;
    do
       cat >> $BATCH_FILE << EOF
put $gpg
EOF
    done

    print_log "    Batch file contains"
    cat $BATCH_FILE
    # New line without timestamp
    echo ""

    print_log "    Do the upload - $BATCH_FILE $REMOTE_HOST:$REMOTE_PORT "
    sftp -b $BATCH_FILE -oPort=$REMOTE_PORT $REMOTE_HOST

    print_log "    Remove batch"
    rm $BATCH_FILE
}


send_email () {
    SUBJECT="syn-backup - $HOSTNAME - $YMD $HMS "
    BODY_FILE=$1

    print_log "Send email to $TO_EMAIL with body $BODY_FILE"

    [ -f ~/dead.letter ] && rm ~/dead.letter
    cat $BODY_FILE | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL

    # If the TO_EMAIL fails, nail will create the file dead.letter, test to see
    # if it exists and if so wait 1 minute and then resend
    while [ -f ~/dead.letter ]
    do
        print_log "  Failed to send email, retry in 60 seconds"
        sleep 60
        rm ~/dead.letter
        cat $BODY_FILE | /opt/bin/nail -s "$SUBJECT" $TO_EMAIL
    done
}


send_email_start ()
{
    TMP_FILE=`mktemp`
    echo "Start backup" > $TMP_FILE
    send_email $TMP_FILE
    rm $TMP_FILE
}


create_backup () {
    BACKUP_FOLDER=$1
    SPLIT_FILE=$2
    SNAR_FILE=$3
    LAST_SNAR_FILE=$4

    print_log "  Create folders - $BACKUP_FOLDER"
    mkdir -p $BACKUP_FOLDER

    if [ -n "$LAST_SNAR_FILE" ];
    then
        print_log "  Restore snar file $LAST_SNAR_FILE to $SNAR_FILE"
        cp $LAST_SNAR_FILE $SNAR_FILE
    fi

    print_log "  Create incremental archive - $SPLIT_FILE"
    cd /
    /opt/bin/tar c --no-check-device \
        -g $SNAR_FILE $BACKUP_FOLDER --atime-preserve=system | \
        split -d -b $SPLIT_SIZE - $SPLIT_FILE

    print_log "  Encrypt - $SPLIT_FILE*"
    # Compress-level 0, because most files that are backuped are already encrypted.
    gpg2 --compress-level 0 --recipient daniel --batch  \
         --encrypt-files --encrypt $SPLIT_FILE*

    print_log "  All files in $BACKUP_FOLDER"
    ls -hal $BACKUP_FOLDER
    echo ""

    # Only upload month backups
    #upload $SPLIT_FILE

    print_log "    Remove split file"
    ls $SPLIT_FILE* | grep -v "\\.gpg" | grep "split"
    ls $SPLIT_FILE* | grep -v "\\.gpg" | grep "split" | xargs rm
}


backup ()
{
    FOLDER_TO_BACKUP=$1
    set_all_pathes $FOLDER_TO_BACKUP

    print_log "Backup /${FOLDER_TO_BACKUP} to $BACKUP_STORE"

    [ -f "$FULL_SNAR_FILE" ] && print_log "  Full backup already done"
    [ -f "$MONTH_SNAR_FILE" ] && print_log "  Monthly backup already done"
    [ -f "$WEEK_SNAR_FILE" ] && print_log "  Weekly backup already done"
    [ -f "$DAY_SNAR_FILE" ] && print_log "  Daily backup already done"


    if [ ! -f "$FULL_SNAR_FILE" ]; then
        print_log "Do full backup"
        create_backup $FULL_BACKUP_FOLDER $FULL_SPLIT_FILE $FULL_SNAR_FILE
        upload $MONTH_SPLIT_FILE

    elif [ ! -f "$MONTH_SNAR_FILE" ]; then
        print_log "Do month backup"
        create_backup $MONTH_BACKUP_FOLDER $MONTH_SPLIT_FILE $MONTH_SNAR_FILE $FULL_SNAR_FILE
        upload $MONTH_SPLIT_FILE

    elif [ ! -f "$WEEK_SNAR_FILE" ]; then
        print_log "Do week backup"
        create_backup $WEEK_BACKUP_FOLDER $WEEK_SPLIT_FILE $WEEK_SNAR_FILE $MONTH_SNAR_FILE

    elif [ ! -f "$DAY_SNAR_FILE" ]; then
        print_log "Do day backup"
        create_backup $DAY_BACKUP_FOLDER $DAY_SPLIT_FILE $DAY_SNAR_FILE $WEEK_SNAR_FILE

    fi
}


main () {
    verify_requirements
    mkdir -p $BACKUP_FOLDER
    store_to_logfile

    send_email_start

    print_log "syn-backup started"
    print_log "  Logfile can be found at $LOG_FILE "
    print_log

    for FOLDER in "${FOLDERS_TO_BACKUP[@]}"
    do
        backup $FOLDER
        print_log
    done

    print_log "syn-backup ended"
    send_email $LOG_FILE
}


main

