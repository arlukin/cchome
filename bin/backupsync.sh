#/!/bin/sh

# Rsync everything to aw-asp-desktop from aw-asp-server
rsync	--exclude '0NoBackup' \
	--exclude 'Movies Film' \
	--exclude 'Movies Series' \
	--password-file=/etc/backupsync.passw \
	--archive --hard-links --delete --delete-excluded --delete-after -P \
	/media/UNTITLE/ \
	/home/arlukin/MyPrivate \
	arlukin@192.168.0.5::backup/aw-asp-server/

# Create history with rsync on aw-asp-admin
#sudo rsync --archive --sparse --hard-links --delete --delete-excluded --delete-after -v /media/media/* arlukin@192.168.0.100:/opt/media/.snapshots/

# Spin down disk that was backuped on aw-asp-server
hdparm -Y /dev/sdb

# Spin down backup disk on aw-asp-desktop
ssh -i /home/arlukin/.ssh/id_rsa arlukin@192.168.0.5 "sudo spindown"
