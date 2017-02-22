#!/bin/bash
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# Variables initialisation
. init.sh
. $config_file

key_opt=""
REMOTE=""
ssh_com=""

if [[ ! -f "$CSV_file" ]]; then
	echo "No infrastructure information found. Create infrastructure with infrainit.sh."
	exit 1
fi
message "Checking workers status"
echo "Reading from $CSV_file"
while read -r line; do
	IFS="," read -ra arr <<< "$line"
	case "${arr[0]}" in
        hosts)
            remote_hosts=("${arr[@]/hosts}")
            if [[ -n "$debug" ]]; then
            	echo "hosts: ${remote_hosts[@]}"
            fi
            ;;
        master)
			START_MASTER="${arr[1]}"
			if [[ -n "$START_MASTER" ]]; then
				master_host=${remote_hosts[$((START_MASTER+1))]}
				if [[ -n "$debug" ]]; then
					echo "Using master host $master_host"
				fi
			fi
			;;
		remote_path)
			REMOTE_PATH="${arr[1]}"
			if [[ -n "$debug" ]]; then
				echo "Using remote path $REMOTE_PATH"
			fi
			;;
		folder)
			PROJ_FOLDER="${arr[1]}"
			if [[ -n "$debug" ]]; then
				echo "Using proj folder $PROJ_FOLDER"
			fi
			;;
		key)
			if [[ -n "${arr[1]}" ]]; then
				KEY="${arr[1]}";key_opt="-i ${arr[1]}";shift;
			fi
            ;;
    esac
done < $CSV_file


if [[ -z "$master_host" ]]; then
	echo "No master host found in $CSV_file"
	exit 1
fi

cmd="docker exec -t $celery_cont_name celery status"
if [[ -n "$debug" ]]; then
	echo $cmd
fi
echo $cmd > $cmd_filename
if [[ "$master_host" == "localhost" ]]; then
	LocalExec $cmd_filename
else
	RemoteExec $cmd_filename $master_host "$key_opt"
fi