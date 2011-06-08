#!/bin/sh

# cd && curl https://raw.github.com/arlukin/cchome/master/bin/configure-fedora.sh > configure-fedora.sh && chmod +x configure-fedora.sh && ./configure-fedora.sh

# Install cchome
ssh-keygen -t rsa -C "daniel@cybercow.se"
cat .ssh/id_rsa.pub

read DUMMY
echo -n "Paste the ssh key to github, and press any key."

git clone git@github.com:arlukin/cchome.git
yum -y install git

# Set monitor to primary screen.
xrandr --output DVI-0 --primary


