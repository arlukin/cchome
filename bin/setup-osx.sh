#!/bin/sh

# How to get UTF8 work properly.
# http://fruitfulerrors.blogspot.com/2011/01/osx-106-lcctype.html
# http://hints.macworld.com/article.php?story=20060825071728278
if grep -q "LC_CTYPE=en_US.UTF-8" ~/.profile 
then
	echo "LC_CTYPE already set"
else
	echo "export LC_CTYPE=en_US.UTF-8" >> ~/.profile
	export LC_CTYPE=en_US.UTF-8
fi
