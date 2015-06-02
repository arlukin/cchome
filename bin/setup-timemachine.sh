#!/bin/sh

# Config
PLIST=/Library/LaunchDaemons/se.cybercow.arlukin-once-per-day-time-machine-backup.plist

# Start script
echo "Setup $PLIST"

# 
[[ -f $PLIST ]] && launchctl unload -w $PLIST
[[ -f $PLIST ]] && rm $PLIST

#
cat > $PLIST << _EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>se.cybercow.arlukin-once-per-day-time-machine-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>tmutil startbackup</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>0</integer>
        <key>Minute</key>
        <integer>45</integer>
    </dict>
</dict>
</plist>
_EOF

launchctl load -w $PLIST
cat $PLIST
date