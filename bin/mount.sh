#!/bin/bash

#
# Used on the office iMac to ssh mount directories on the office servers.
#

function init_password_less_ssh {
  echo "Mount server " $1
  ssh root@$1 'mkdir -p .ssh;chmod 700 .ssh; touch .ssh/authorized_keys;chmod 640 .ssh/authorized_keys'
  cat /Users/dali/.ssh/id_rsa.pub | ssh root@$1 'cat >> .ssh/authorized_keys'
}

function ssh_mount_server {
  init_password_less_ssh $2

  mkdir -p ~/mount/$1
  umount ~/mount/$1
  sshfs root@$2:/opt/ ~/mount/$1 -oauto_cache,reconnect
}

#                 Folder            Server ip
ssh_mount_server 'fp-tp-scan'      '10.100.100.12'
ssh_mount_server 'fp-tp-gf-rd-int' '10.100.100.130'
ssh_mount_server 'fo-tp-install'   '10.100.100.200'
