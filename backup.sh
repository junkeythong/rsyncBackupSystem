#!/bin/bash

# Script to backup personal files to the external drive.

############ Some global setting ############
# Source directory we wish to backup
source_dir='/'

# Destination directory we wish to backup to (DO NOT end with a forward-slash).
dest_dir='/HDD500'

# Log file for this script
logfile='/var/log/rsync_backup'

# Disk UUID
diskUUID=500cfbf9-41f3-4b3e-98fd-53a9ed287a69

# Exclude folder and file. Should be list on 1 line, otherwise parsing will be wrong
exclude_folder_and_file={$dest_dir,'dev/*','lost+found','mnt/*','/proc/*','run/*','sys/*','tmp/*','home/*/.gvfs/','.thumbnails/','media','home/*/.cache/mozilla/','home/*/.cache/chromium/','home/*/.local/share/Trash/','swapfile','.cache'}

#############################################

writeToLog() {
	echo -e "$(date --rfc-3339=seconds) ${1}" | tee -a "${logfile}"
}

# Renew log file
echo '' > $logfile
writeToLog "########## FULL SYSTEM BACKUP ##########"

# Check if backup directory is exist
if [ ! -d $dest_dir ]; then
	writeToLog "$dest_dir does NOT exist, creating ... "
	mkdir -p $dest_dir
fi 

# Check whether target volume is mounted, and mount it if not
if ! mountpoint -q $dest_dir/; then
        writeToLog "Mounting the external drive to: $dest_dir ..."
        if ! mount -U $diskUUID $dest_dir && ! mountpoint -q $dest_dir/; then
                writeToLog "FAILED to mount! Exiting ..."
                exit 1
        fi
fi

# Let's back up
writeToLog "Starting backup system FROM $source_dir TO $dest_dir ..."
if rsync --archive --acls --xattrs --partial --human-readable --recursive --hard-links --owner \
		--delete --delete-excluded --info=progress2 --verbose \
		--exclude-from=exclude.txt $source_dir $dest_dir \
		--log-file=$logfile
then
	writeToLog "Backup completed successfully"
else
	writeToLog "Backup FAILED !!!"
fi

writeToLog "Un-mount the mountpoint ..."
if ! umount $dest_dir; then
        writeToLog "FAILED to umount $dest_dir!"
else
	# Delete destination directory
	writeToLog "Remove the directory: $dest_dir after ummount the disk ..."
	if [ -d $dest_dir ]; then
		rm -rf $dest_dir
	fi
fi
writeToLog "Backup DONE!"
exit 0
