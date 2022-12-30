#!/usr/bin/env bash

date=$(date +"%d-%m-%G")
user_id=$(cat /etc/passwd | grep $USER | cut -d : -f 3)
source=$1
partition_type="exfat"
partition_name="/dev/nvme0n1p7"
partition_mount_point=$2
backup_file_name="backup-linux-$( echo $source | tr -d /)-$date"
backup_remote_path=$3
has_mounted=$(mount | grep -o $partition_mount_point)
logs=logs.json

mount_partition() {
    local log_op_main=$(jq '.partition.op.main' $logs) | tr -d '"'
    echo $log_op_main
    sleep 5
    mount -t $partition_type auto -o uid=$user_id $partition_name $partition_mount_point
}

pack_dir_home() {
    local src=$( echo $source | tr -d /)
    local log_op_main=$(jq '.packing.op.main' $logs)
    local log_op_sub=$(jq '.packing.op.sub' $logs) 
    echo $log_op_main | tr -d '"'
    echo "$log_op_sub" | tr -d '"'
    tar -czf - -P $source | pv -p --timer --rate --bytes > "$backup_file_name.gz"
}

do_local_backup() {
    local src=$( echo $source | tr -d /)
    local log_op_main=$(jq '.backup.local.op.main' $logs)
    local log_op_sub=$(jq '.backup.local.op.sub' $logs)
    echo $log_op_main | tr -d '"'
    echo "$log_op_sub $partition_mount_point..." | tr -d '"'
    pv "$backup_file_name.gz" > "$partition_mount_point/$backup_file_name.gz"
}

do_remote_backup() {
    local backup_file=$backup_file_name
    local source="$partition_mount_point/$backup_file.gz"
    local dest=$backup_remote_path   
    local log_op_main=$(jq '.backup.remote.op.main' $logs)
    local log_op_sub=$(jq '.backup.remote.op.sub' $logs)
    echo $log_op_main | tr -d '"'
    echo "$log_op_sub Google Drive em $dest..." | tr -d '"'
    rclone copy -P $source gdrive:$dest
}

logger() {
    case $1 in
        1) echo -e $(jq '.partition.done' $logs) | tr -d '"';;
        2) echo -e $(jq '.packing.done' $logs) | tr -d '"';;
        3) echo -e $(jq '.backup.done' $logs) | tr -d '"';;
        4) echo -e $(jq '.backup.done' $logs) | tr -d '"';;
    esac
}

main() {
    pack_dir_home
    [[ $? -eq 0 ]] && logger 2
    do_local_backup 
    [[ $? -eq 0 ]] && logger 3
    do_remote_backup 
    [[ $? -eq 0 ]] && logger 4
}

if [[ $has_mounted ]];then
    echo $(jq '.partition.successed' $logs) | tr -d '"'
    main
    [[ $? -eq 0 ]] && cd ~
    exit 0
else
    echo $(jq '.partition.fail' $logs) | tr -d '"'
    mount_partition
    [[ $? -eq 0 ]] && logger 1
    main
    [[ $? -eq 0 ]] && cd ~
    exit 0
fi