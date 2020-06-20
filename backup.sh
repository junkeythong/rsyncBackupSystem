#!/bin/bash

# Script to backup personal files to the external drive.

############ Some global setting ############
# Source directory we wish to backup
source_dir='/'

# Destination directory we wish to backup to (DO NOT end with a forward-slash).
dest_dir='/HDD500_BACKUP'

# We will use date as name of backup folder name
backup_name='$(date +"%d-%m-%Y")'

# Log file for this script
logfile='/var/log/rsync_backup'

# Exclude folder and file
exclude_folder_and_file="${dest_dir},'/.gvfs/','/Examples/','/.local/share/Trash/','/.thumbnails/', \
               '/transient-items/','/dev/*','/proc/*','/sys/*','/tmp/*','/mnt/*','/media/*', \
               '/run/*','/lost+found','/home/*/.cache/mozilla/*','/home/*/.cache/chromium/*', \
               '/home/*/.local/share/Trash/*','swapfile','.cache'"

#############################################

writeToLog() {
	echo -e "$(date --rfc-3339=seconds) ${1}" | tee -a "${logfile}"
}

writeToLog "########## BACKUP SYSTEM ##########"

# Check if backup directory is exist
writeToLog "===> Checking directory: $dest_dir of backup volume ..."
if [ ! -d ${dest_dir} ]; then
	writeToLog "${dest_dir} does NOT exist, force to create !"
	mkdir -p ${dest_dir}
fi 

# Check whether target volume is mounted, and mount it if not
if ! mountpoint -q ${dest_dir}/; then
        writeToLog "Mounting the external drive to: ${dest_dir} ..."
        if ! mount ${dest_dir} && ! mountpoint -q ${dest_dir}/; then
                writeToLog "FAILED to mount: error code 5 was returned!"
                exit 5
        fi
fi

# How to rotate log file, or copy, or push to message
# how to find disk to mount ?
# test with virtual machine

# Create folder backup for this time
if [ ! -d ${backup_name} ]; then
	writeToLog "Creating folder: ${backup_name}"
	mkdir -p ${backup_name}
fi

# Move to root
cd / || return 101

# Let's back up
writeToLog "===> Starting backup system from source:$source_dir to destination:$dest_dir ..."
if sudo rsync --archive --acls --xattrs -partial --progress --verbose --human-readable \
              --itemize-changes --progress --dry-run --delete --delete-excluded \
              --exclude={$exclude_folder_and_file} ${source_dir} ${dest_dir} \
              --log-file=${logfile}
then
	writeToLog "Backup completed successfully"
else
	writeToLog "Backup FAILED, will try again in the next time !!! return 100."
	return 100; 
fi

# We only keep 5 latest backup
number_backup='ls -l | grep "^d" | wc -l'
if [ $number_backup -gt 5 ]; then
	delete_dirs='sudo find ${dest_dir} - type d -printf '%T+ %p\n' | sort  | tail -n + 6 | awk '{print $NF}''
	writeToLog "Reached threshold! Deleting: $delete_dirs"
	sudo find ${dest_dir} - type d -printf '%T+ %p\n' | sort  | tail -n + 6 | awk '{print $NF}' | xargs rm -f
fi

writeToLog "===> Un-mount the mountpoint ..."
if ! umount ${mount_point}; then
        writeToLog "FAILED to umount: error code 6 was returned!"
        exit 6
fi

# Delete destination directory
writeToLog "===> Remove directory: $dest_dir of backup volume ..."
if [ -d ${dest_dir} ]; then
	rm -rf ${dest_dir}
fi 

exit 0
writeToLog "########## BACKUP SYSTEM AT BOOT ##########"
