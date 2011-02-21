#!/bin/bash
if [ "$(xrandr | grep LVDS1 | cut -d " " -f 3)" == "1024x600+0+0" ] ; 
then 
xrandr -o left;
else 
xrandr -o  normal;
fi

