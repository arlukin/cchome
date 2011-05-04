#!/bin/sh
git config --global user.name "Arlukin"
git config --global user.email daniel@cybercow.se

git config --global diff.tool araxis
git config --global merge.tool araxis

echo "export PATH=$PATH:$HOME/cc/bin" >> $HOME/.bash_profile
echo "export PATH=$PATH:$HOME/cc/bin/araxis" >> $HOME/.bash_profile
