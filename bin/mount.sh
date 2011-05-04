#!/bin/bash

#
# Used on the office iMac to ssh mount directories on the office servers.
#

MOUNT=~/cchome/mount

function init_password_less_ssh {
  echo "Mount server " $1
  ssh root@$1 'mkdir -p .ssh;chmod 700 .ssh; touch ~/.ssh/authorized_keys;chmod 640 ~/.ssh/authorized_keys'
  cat ~/.ssh/id_rsa.pub | ssh root@$1 'cat >> ~/.ssh/authorized_keys'
}

function ssh_mount_server {
  init_password_less_ssh $2

  mkdir -p $MOUNT/$1
  umount $MOUNT/$1
  sshfs root@$2:/opt/ $MOUNT/$1 -oauto_cache,reconnect
}

#                 Folder            Server ip

ssh_mount_server 'fo-tp-dalitst'   '10.100.100.231'
ssh_mount_server 'fo-tp-php-old'   '10.100.0.100'
ssh_mount_server 'fo-tp-file'      '10.100.0.4'
ssh_mount_server 'fo-tp-vh01'      '10.100.100.201'
ssh_mount_server 'fo-tp-install'   '10.100.100.200'
