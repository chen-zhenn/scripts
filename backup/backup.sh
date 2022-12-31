#!/usr/bin/env bash

date=$(date +"%d-%m-%G")
time="$(date +%T | tr -d :)"
timestamp="$time"
user_id=$(cat /etc/passwd | grep $USER | cut -d : -f 3)
user_dir=$HOME
backup_source=$1
partition_type="exfat"
partition_name="/dev/nvme0n1p7"
partition_mount_point=$2
backup_file_name="backup$( echo $backup_source | tr / "-")-$date"
backup_local_path=0
backup_remote_path=$3
has_mounted=$(mount | grep -o $partition_mount_point)
logs=logs.json

mount_partition() {
    local log_op_init=$(jq '.partition.op.main' $logs)
    echo $log_op_init | tr -d '"'
    sudo mount -t $partition_type -o uid=$user_id $partition_name $partition_mount_point
}

pack_dir_home() {
    local log_op_init=$(jq '.packing.op.main' $logs)
    local log_op_sub=$(jq '.packing.op.sub' $logs) 
    echo $log_op_init
    echo "$log_op_sub" | tr -d '"'
    tar -czf - -P $backup_source | pv -p --timer --rate --bytes > "$backup_file_name.gz"
}

do_local_backup() {
    [[ $backup_local_path -eq 0 ]] && backup_local_path=$partition_mount_point
    local log_op_init=$(jq '.backup.local.op.main' $logs)
    local log_op_sub=$(jq '.backup.local.op.sub' $logs)    
    echo $log_op_init | tr -d '"'
    echo "$log_op_sub $backup_local_path..." | tr -d '"'
    pv "$backup_file_name.gz" > "$backup_local_path/$backup_file_name.gz"
}

do_remote_backup() {    
    local source="$backup_local_path/$backup_file_name.gz"
    local dest="$backup_remote_path-$timestamp"
    local log_op_init=$(jq '.backup.remote.op.main' $logs)
    local log_op_sub=$(jq '.backup.remote.op.sub' $logs) 
    echo $log_op_init | tr -d '"'
    echo "$log_op_sub Google Drive em $dest..." | tr -d '"'
    rclone mkdir gdrive:$dest
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

init() {
    pack_dir_home
    [[ $? -eq 0 ]] && logger 2
    do_local_backup
    [[ $? -eq 0 ]] && logger 3
    do_remote_backup
    [[ $? -eq 0 ]] && logger 4
}

main(){

    abort_backup_task(){
        echo "Deseja cancelar tarefa de backup? (s)Sim,(n)Não"
        read confirm

        if [[ $confirm == "s" ]];then
            echo "Backup cancelado!"
            exit 0
            else main
        fi 
        echo "Backup cancelado!"
        exit 0
    }

    create_backup_dir(){
        echo 'Deseja fazer backup em outro diretório? (s)Sim,(n)Não'
        read confirm

        if [[ $confirm == "s" ]];then
            echo 'Infome caminho do diretório! Ex: /caminho/meu-backup'
            read directory_path

            if [[ -d "$user_dir/BACKUP/$directory_path" ]];then
                backup_local_path="$user_dir/BACKUP/$directory_path"
                init
                else
                    echo -e "$directory_path não existe!\nDeseja cria-lo? (s)Sim,(n)Não"
                    read confirm

                    if [[ $confirm == "s" ]];then
                        backup_local_path="$user_dir/BACKUP/$directory_path"
                        mkdir -p $backup_local_path
                        
                        if [[ $? -eq 0 ]];then
                            echo "Diretório criado em $backup_local_path"
                            init
                            [[ $? -eq 0 ]] && exit 0
                            else
                                echo "Não foi possivel criar diretório!"
                                abort_backup_task
                        fi
                        else abort_backup_task
                    fi
            fi
            else abort_backup_task
        fi
    }

    if [[ -d $partition_mount_point ]];then

        if [[ $has_mounted ]];then
            echo $(jq '.partition.successed' $logs) | tr -d '"'
            init
            [[ $? -eq 0 ]] && exit 0
        else
            echo $(jq '.partition.fail' $logs) | tr -d '"'
            echo 'Deseja montar partição para backup? (s)Sim,(n)Não'
            read confirm
            
            if [[ $confirm == "s" ]];then
                mount_partition
                [[ $? -eq 0 ]] && logger 1
                init
                [[ $? -eq 0 ]] && exit 0
            
            else create_backup_dir
            fi
        fi
    fi
}
main