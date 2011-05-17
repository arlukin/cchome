#!/bin/sh
git config --global user.name "Arlukin"
git config --global user.email daniel@cybercow.se

git config --global diff.tool araxis
git config --global merge.tool araxis

echo "export PATH=$PATH:$HOME/cchome/bin:$HOME/cchome/bin/araxis" >> $HOME/.bash_profile
