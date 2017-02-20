#!/bin/bash

# Rsync files on remote hosts.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# TODO
# [V] Read PROJ_FOLDER and REMOTE_PATH from CSV file.

. init.sh
. $config_file

usage=$(cat <<USAGEBLOCK
Update files on remote hosts with rsync.
Use CL arguments and $CSV_file file. CL arguments has priority.

$0 [-a <[user@]host1,[user@]host2...>] [-i identity file] -d <dirname> -r <path>

Options:
	-a	Remote hosts addresses, comma-separated list.
	-d	Local folder with task (project) files.
	-r	Remote path for storing task and framework files relative to home dir..
USAGEBLOCK
)


key_opt=""
REMOTE=""
ssh_com=""


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
		remote_path)
			REMOTE_PATH="${arr[1]}"
			echo "Using remote path $REMOTE_PATH"
			;;
		folder)
			PROJ_FOLDER="${arr[1]}"
			echo "Using proj folder $PROJ_FOLDER"
			;;
		key)
			KEY="${arr[1]}";key_opt="-i ${arr[1]}";shift;
            ;;
    esac
done < $CSV_file


# Reading CL arguments
while test $# -gt 0; do
    case "$1" in
        -h | --help)
            echo $usage
            exit 0
            ;;
        -a)
            REMOTE="$2";shift;
            ;;
        -d)
            PROJ_FOLDER="$2";shift;
            ;;
        -r)
            REMOTE_PATH="$2";shift;
            ;;
        -i)
            KEY="$2";key_opt="-i $2";shift;
            ;;
        --debug)
			debug=YES
			;;
        -*)
            echo "Invalid option: $1"
            echo "$usage"
            exit 1;;
    esac
    shift
done



if [[ -z "$REMOTE_PATH" ]] || [[ -z "$PROJ_FOLDER" ]]; then
	if [[ -z "$REMOTE_PATH" ]]; then
		echo "Remote path is empty"
	fi
	if  [[ -z "$PROJ_FOLDER" ]]; then
		echo "proj folder is empty"
	fi

	echo "$usage"
	exit 1
fi

set -e


if [[ -n "$REMOTE" ]]; then
	rhost=$REMOTE
	echo $rhost
	if [[ -n "$KEY" ]]; then
		SSH_KEY="-e \"ssh $key_opt\""
	else
		SSH_KEY=""
	fi
	echo $ssh_com
	OPT="-avii"

	echo "Compare ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	# Copy task files to remote
	eval rsync $OPT $SSH_KEY --exclude-from "rsyncexclude_task.txt"  ./$PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/
	# Copy framework files to remote
	eval rsync $OPT $SSH_KEY --include-from "rsyncinclude_framework.txt" --exclude='*' --size-only  ./ $rhost:$REMOTE_PATH/
	exit 0
fi


echo "${remote_hosts[@]}"
# Copy files to remote locations
for rhost in "${remote_hosts[@]}"; do
	if [[ "$rhost" == "hosts" ]] || [[ "$rhost" == "localhost" ]] || [[ -z "$rhost" ]]; then
		continue
	fi
	echo $rhost
	if [[ -n "$key_opt" ]]; then
		SSH_KEY="-e \"ssh $key_opt\""
	else
		SSH_KEY=""
	fi


	if [[ -n "$debug" ]]; then
		echo "rsync ssh option: $SSH_KEY"
		echo "Testing SSH connection to $rhost with ssh $key_opt $rhost"

	fi
	printf "hostname" > $cmd_filename
	HOSTNAME=$(RemoteExec $cmd_filename $rhost "$key_opt")
	if [[ -z "$HOSTNAME" ]]; then
		echo "Cannot connect with ssh $key_opt $rhost."
		exit 1
	fi
	if [[ -n "$debug" ]]; then
		echo $HOSTNAME
	fi

	if [[ -n "$debug" ]]; then
		OPT="-avii --progress"
	else
		OPT="-av --progress"
	fi

	if [[ -n "$debug" ]]; then
		echo "Compare ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	fi
	# Copy task files to remote
	cmd="rsync $OPT $SSH_KEY --exclude-from \"rsyncexclude_task.txt\" --size-only  ./$PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	if [[ -n "$debug" ]]; then
		echo $cmd
	fi
	eval $cmd 2>/dev/null
	cmd="rsync $OPT $SSH_KEY --include-from \"rsyncinclude_framework.txt\" --exclude='*' --size-only  ./ $rhost:$REMOTE_PATH/"
	if [[ -n "$debug" ]]; then
		echo $cmd
	fi
	eval $cmd 2>/dev/null
done
