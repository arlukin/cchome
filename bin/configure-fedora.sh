#!/bin/sh

ssh-keygen -t rsa -C "daniel@cybercow.se"
cat .ssh/id_rsa.pub

echo -n "Paste the ssh key to github? "
read DUMMY

git clone git@github.com:arlukin/cchome.git
yum -y install git

