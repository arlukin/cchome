#!/bin/bash

#
# Used on the office iMac to ssh mount directories on the office servers.
#

MOUNT=~/cchome/mount

function init_password_less_ssh {
  echo "Mount server " $1
  ssh $1 'mkdir -p .ssh;chmod 700 .ssh; touch ~/.ssh/authorized_keys;chmod 640 ~/.ssh/authorized_keys'
  cat ~/.ssh/id_rsa.pub | ssh $1 'cat >> ~/.ssh/authorized_keys'
}

function ssh_mount_server {
  echo "$2:$3 $MOUNT/$1" 
  init_password_less_ssh $2

  mkdir -p $MOUNT/$1
  umount $MOUNT/$1
  #diskutil umount force $MOUNT/$1
  sshfs $2:$3 $MOUNT/$1 
  #-oauto_cache,reconnect
}

#                 Local Folder     Server ip          Remote folder

ssh_mount_server 'fo-tp-dalitst'   'root@10.100.100.231'      '/opt/'
ssh_mount_server 'fo-tp-php-old'   'root@10.100.0.100'        '/opt/RootLive/'
ssh_mount_server 'fo-tp-file'      'root@10.100.0.4'          '/file/'
ssh_mount_server 'fo-tp-vh01'      'root@10.100.100.201'      '/opt/'
ssh_mount_server 'fo-tp-install'   'root@10.100.100.200'      '/opt/'

#sshfs -p34 arlukin@192.168.0.100:/ av-as-server/

