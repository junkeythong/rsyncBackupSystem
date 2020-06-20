#!/bin/bash

# Script to backup personal files to the external drive.

############ Some global setting ############
# Source directory we wish to backup
source_dir='src_test'

# Destination directory we wish to backup to (DO NOT end with a forward-slash).
dest_dir='/HDD500'

# We will use date as name of backup folder name
backup_name=$(date +"%d-%m-%Y")

# Log file for this script
logfile='/var/log/rsync_backup'

# Exclude folder and file
exclude_folder_and_file=${dest_dir,'/.gvfs/','/Examples/','/.local/share/Trash/','/.thumbnails/', \
               '/transient-items/','/dev/*','/proc/*','/sys/*','/tmp/*','/mnt/*','/media/*', \
               '/run/*','/lost+found','/home/*/.cache/mozilla/*','/home/*/.cache/chromium/*', \
               '/home/*/.local/share/Trash/*','swapfile','.cache'}

#############################################

writeToLog() {
	echo -e "$(date --rfc-3339=seconds) ${1}" | tee -a "${logfile}"
}

writeToLog "########## FULL SYSTEM BACKUP ##########"

# Check if backup directory is exist
if [ ! -d $dest_dir ]; then
	writeToLog "$dest_dir does NOT exist, creating ... "
	sudo mkdir -p $dest_dir
fi 

# Check whether target volume is mounted, and mount it if not
if ! mountpoint -q $dest_dir/; then
        writeToLog "Mounting the external drive to: $dest_dir ..."
        if ! sudo mount $dest_dir && ! mountpoint -q $dest_dir/; then
                writeToLog "FAILED to mount! Exiting ..."
                exit 1
        fi
fi

# TODO:
# How to rotate log file, or copy, or push to message
# how to find disk to mount if label is change ?
# ask for root password ?
# delete folder when reach threshol

if [ ! -d $dest_dir/$backup_name ]; then
	writeToLog "Creating the backup folder: $backup_name"
	sudo mkdir -p $dest_dir/$backup_name
fi

# Let's back up
writeToLog "Starting backup system FROM $source_dir TO $dest_dir ..."
if sudo rsync --archive --acls --xattrs --partial --progress --verbose --human-readable \
              --itemize-changes --progress --dry-run --delete --delete-excluded \
              --exclude=$exclude_folder_and_file $source_dir $dest_dir \
              --log-file=$logfile
then
	writeToLog "Backup completed successfully"
else
	writeToLog "Backup FAILED !!!"
fi

# We only keep 5 latest backup
number_backup=$(ls -l $dest_dir | grep "^d" | wc -l)
if [ $number_backup -gt 5 ]; then
	delete_dirs=$(sudo find ${dest_dir} - type d -printf '%T+ %p\n' | sort  | tail -n + 6 | awk '{print $NF}')
	writeToLog "Reached threshold! Deleting: $delete_dirs"
	sudo find $dest_dir - type d -printf '%T+ %p\n' | sort  | tail -n + 6 | awk '{print $NF}' | xargs rm -rf
fi

writeToLog "Un-mount the mountpoint ..."
if ! sudo umount $dest_dir; then
        writeToLog "FAILED to umount $dest_dir!"
else
	# Delete destination directory
	writeToLog "Remove the directory: $dest_dir after ummount the disk ..."
	if [ -d $dest_dir ]; then
		sudo rm -rf $dest_dir
	fi
fi
writeToLog "backup DONE!"
exit 0
