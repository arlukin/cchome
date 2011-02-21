#!/bin/bash

# Script Name: dar_backups.sh
# Author: Roi Rodriguez Mendez & Mauro Silvosa Rivera (Cluster Digital S.L.)
#         Daniel Lindh (www.cybercow.se)
# Description:
#       dar_backups.sh is a script to be runned from cron which
#       backups data and stores it locally and optionally remote using scp.
#       It decides between doing a master or an incremental backup based
#       on the existance or not of a master one for the actual month.
#
#       * The script will store a new backup for each month.
#       * Folders named 0NoBackup or NoBackup, anywhere among the folders
#         that are being backuped, will not be added to the backup.
#
#       Add to crontab by first running this command "crontab -e:"
#       and then add this line.
#       15 0 * * * ./dar_backup.sh
#
#       For more information about dar backups
#       http://gradha.sdf-eu.org/textos/dar-differential-backup-mini-howto.en.html
#       http://dar.linux.free.fr/doc/index.html#3
# Version: 1.1
# Revision History:
#       22.08.2005 - Creation
#       09.12.2009 - Extended by Daniel Lindh

# Base directory where backups are stored
BASE_BAK_DIR=/media/UNTITLE/0Backup/dar

# Directories to backup
INCLUDE_DIR="-g ./media/UNTITLE/MyPrivate
            -g ./home/arlukin/MyPrivate"

# Directories not to backup
EXCLUDE_DIR="-P NoBackup
            -P 0NoBackup"

# Max backup file size
SLICE_SIZE=500M

# Password for encryption.
PASSWORD="xx"

# Send error emails to.
MAIL_TO="daniel@cybercow.se"

# Directory where backups for the actual month are stored (path relative to
# $BASE_BAK_DIR)
MONTHLY_BAK_DIR=`date -I | awk -F "-" '{ print $1"-"$2 }'`

# Remote backup settings
# You need to setup automatic login for the backup user
# http://articles.cybercow.se/2009120966/articles/linux/ssh-without-password.html
REMOTE_BAK="true"
REMOTE_HOST="xx.xx.xx.xx"
REMOTE_PORT="xx"
REMOTE_USR="daniel"
REMOTE_BASE_DIR="/opt/daniel/Backup/av-asp-server"
REMOTE_MONTHLY_DIR=$MONTHLY_BAK_DIR
REMOTE_DIR=${REMOTE_BASE_DIR}/${REMOTE_MONTHLY_DIR}
REMOTE_IDENTITY_FILE="/home/arlukin/.ssh/id_rsa"

# The name of the script
COMMAND_NAME=`echo ${0} | awk -F "/" '{ print $2 }'`

# Name and path for the backup file.
SLICE_NAME=${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/backup_`date -I`

## FUNCTIONS' DEFINITION
# Function which creates a master backup. It gets "true" as a parameter
# if the monthly directory has to be created.
function master_bak () {
  if /usr/bin/dar \
      -c ${SLICE_NAME}_master \
      -m 256 -s $SLICE_SIZE -y \
      -K bf:${PASSWORD} \
      -R / \
      -Z "*.bz2" -Z "*.zip" -Z "*.png" -Z "*.mp3" \
      -Z "*.jpg" -Z "*.JPG" \
      ${EXCLUDE_DIR} \
      ${INCLUDE_DIR} \
      > /dev/null ; then

    if /usr/bin/dar -K :${PASSWORD} -t ${SLICE_NAME}_master > /dev/null ; then
      echo "Archive created and successfully tested."
    else
      echo "Archive created but test FAILED."
      echo "Error from backup script" | mailx -s "Archive created but test FAILED" ${MAIL_TO}
    fi
  else
    echo "Archive creating FAILED."
    echo "Error from backup script" | mailx -s "Archive creating FAILED" ${MAIL_TO}
  fi

  if [ "$REMOTE_BAK" == "true" ]
  then
    /usr/bin/ssh -i ${REMOTE_IDENTITY_FILE} ${REMOTE_USR}@${REMOTE_HOST} -p${REMOTE_PORT} "mkdir -p $REMOTE_DIR"
    for i in `ls ${SLICE_NAME}_master*.dar`
    do
      echo "Send file to remote server"
      /usr/bin/scp -i ${REMOTE_IDENTITY_FILE} -C -p -P${REMOTE_PORT} $i ${REMOTE_USR}@${REMOTE_HOST}:${REMOTE_DIR}/`basename $i` > /dev/null
    done
  fi
}

# Makes the incremental backups
function diff_bak () {
  MASTER=$1

  if /usr/bin/dar \
      -c ${SLICE_NAME}_diff \
      -A $MASTER \
      -J bf:${PASSWORD} \
      -m 256 -s $SLICE_SIZE -y \
      -K bf:${PASSWORD} \
      -R / \
      -Z "*.bz2" -Z "*.zip" -Z "*.png" -Z "*.mp3" \
      -Z "*.jpg" -Z "*.JPG" \
      ${EXCLUDE_DIR} \
      ${INCLUDE_DIR} \
      > /dev/null ; then

    if /usr/bin/dar -K :${PASSWORD} -t ${SLICE_NAME}_diff > /dev/null ; then
      echo "Archive created and successfully tested."
    else
      echo "Archive created but test FAILED."
      echo "Error from backup script" | mailx -s "Archive created but test FAILED" ${MAIL_TO}
    fi
  else
    echo "Archive creating FAILED."
    echo "Error from backup script" | mailx -s "Archive creating FAILED" ${MAIL_TO}
  fi

  if [ "$REMOTE_BAK" == "true" ]
  then
    /usr/bin/ssh -i ${REMOTE_IDENTITY_FILE} ${REMOTE_USR}@${REMOTE_HOST} -p${REMOTE_PORT} "mkdir -p $REMOTE_DIR"
    for i in `ls ${SLICE_NAME}_diff*.dar`
    do
      echo "Send file to remote server"
      /usr/bin/scp -i ${REMOTE_IDENTITY_FILE} -C -p -P${REMOTE_PORT} $i ${REMOTE_USR}@${REMOTE_HOST}:${REMOTE_DIR}/`basename $i` > /dev/null
    done
  fi
}

function backup () {
  # Set appropriate umask value
  umask 027

  # Check for existing monthly backups directory
  if [ ! -d ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR} ]
  then
    # If not, tell master_bak() to mkdir it
    mkdir -p ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}
  fi

  # MASTER not void if a master backup exists
  MASTER=`ls ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/*_master*.dar 2> /dev/null | tail -n 1 | awk -F "." '{ print $1 }'`
  # Check if a master backup already exists.
  if [ "${MASTER}" != "" ]
  then
    # If it exists, it's needed to make a differential one
    echo "Diff " ${SLICE_NAME}
    diff_bak $MASTER
  else
    # Else, do the master backup
    echo "Master " ${SLICE_NAME}
    master_bak
  fi

  spin_down
}

# After the backup is completed, disks on local and remote will be set
# to sleep
function spin_down() {
  hdparm -Y /dev/sdb
  #/usr/bin/ssh -i ${REMOTE_IDENTITY_FILE} ${REMOTE_USR}@${REMOTE_HOST} -p${REMOTE_PORT} "sudo spindown"
}

function list_contents_bak () {
  for i in `ls ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/*_master*.dar 2> /dev/null | awk -F "." '{ print $1 }'`
  do
    echo $i
    /usr/bin/dar -K :${PASSWORD} -l $i
  done

  for i in `ls ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/*_diff*.dar 2> /dev/null | awk -F "." '{ print $1 }'`
  do
    echo $i
    /usr/bin/dar -K :${PASSWORD} -l $i
  done
}

function restore () {
echo "need more testing"
exit;
  for i in `ls ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/*_master*.dar 2> /dev/null | awk -F "." '{ print $1 }'`
  do
    echo $i
    /usr/bin/dar -K :${PASSWORD} -l $i
  done

  for i in `ls ${BASE_BAK_DIR}/${MONTHLY_BAK_DIR}/*_diff*.dar 2> /dev/null | awk -F "." '{ print $1 }'`
  do
    echo $i
    /usr/bin/dar -K :${PASSWORD} -l $i
  done
}

## MAIN FLUX
if [ "$1" == '-l' ]; then
  echo "List all backups"
  ls -alvhR ${BASE_BAK_DIR}
elif [ "$1" == '-ll' ]; then
  echo "List contents of all backups"
  list_contents_bak
elif [ "$1" == '-d' ]; then
  echo "Remove all backups"
  rm -r ${BASE_BAK_DIR}
elif [ "$1" == '-r' ]; then
  echo "Restore backups"
  restore
elif [ "$1" == '-h' ]; then
  echo "Usage ${COMMAND_NAME} [-r]

  -l  List all backups
  -ll List contents of all backups
  -d  Delete all backups
  -r  Restor backup
  "
else
  backup
fi
