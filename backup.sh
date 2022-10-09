#! /bin/sh
# Backup destination
backdest="/opt/backup"

# Labels for backup name
distro="arch"
atype="full"
date=$(date "+%F")
backupfile="$backdest/$distro-$atype-$date.tar.gz"
backupdir=(
    /home/
    /etc/
    /usr/local/
)
tar cpPf - "${backupdir[@]}" | pv -s $(du -sb "${backupdir[@]}" --total | tail -1 | awk '{print $1}') | gzip > $backupfile
