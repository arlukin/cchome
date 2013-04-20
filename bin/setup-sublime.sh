#!/bin/sh
#
# My sublime text 2 settings.
#
# Read more
#   http://www.rockettheme.com/magazine/1319-using-sublime-text-2-for-development
#

if [ ! -e  /bin/subl ]; then
    echo "Setup symlink /bin/subl"
    sudo ln -s "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" /bin/subl
fi

# http://wbond.net/sublime_packages/package_control/installation

if [ ! -e ~/Library/Application\ Support/Sublime\ Text\ 2/Installed\ Packages/Package\ Control.sublime-package ]; then
    echo $PACKAGE_CONTROL
    echo "Install package_control"
    curl http://sublime.wbond.net/Package%20Control.sublime-package > ~/Library/Application\ Support/Sublime\ Text\ 2/Installed\ Packages/Package\ Control.sublime-package
fi

#

cat << EOF
Install the following packages by

cmd+shift+p  → “install” → ENTER → “sublimelint” → ENTER
    Check for syntax errors in python code.

cmd+shift+p  → “install” → ENTER → “codeintel” → ENTER
    alt-click will open class/method definition.

cmd+shift+p  → “install” → ENTER → goto doc → ENTER
    ctrl-shift-h will find python help for marked word.

EOF


#
echo "Setup with own User configs."

cd "/Users/daniel/Library/Application Support/Sublime Text 2/Packages/"
mv User User.org

ln -s /Users/daniel/cchome/var/sublime User

#
echo
echo "If anything was installed, please restart sublime."
echo
