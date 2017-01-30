#!/bin/bash

# Rsync files on remote hosts.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# TODO
# [ ] Read PROJ_FOLDER and REMOTE_PATH from CSV file.


usage=$(cat <<USAGEBLOCK
Update files on remote hosts with rsync.
Remote hosts read from infra.csv file, which must exist.

$0 -a <[user@]host1,[user@]host2...> [-i identity file] -l <dirname>

Options:
	-a	Remote hosts addresses, comma-separated list.
	-l	Local folder with task (project) files.
USAGEBLOCK
)


KEY=""
REMOTE=""
ssh_com=""

while test $# -gt 0; do
    case "$1" in
        -h | --help)
            echo $usage
            exit 0
            ;;
        -a)
            REMOTE="$2";shift;
            ;;
        -l)
            PROJ_FOLDER="$2";shift;
            ;;
        -r)
            REMOTE_PATH="$2";shift;
            ;;
        -i)
            KEY="-i $2";shift;
            ;;
        -*)
            echo "Invalid option: $1"
            echo "$usage"
            exit 1;;
    esac
    shift
done

if [[ -z "$REMOTE" ]] || [[ -z "$REMOTE_PATH" ]] || [[ -z "$PROJ_FOLDER" ]]; then
	echo "$usage"
	echo "Necessary options: remote address (-a), project folder (-l) and remote path (-r)."
	exit 0
fi


RemoteExec() {
	filename=$1
	host=$2
	#filename="remote_command.sh"
	#echo "Executing commands from $filename on $host"
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	{
		scp $filename $host:
	} &>/dev/null
	{
		ssh $host ./$filename
	} 2>/dev/null
}

set -e

CSV_file="infra.csv"
cmd_filename="remote_command.sh"

echo "Reading from $CSV_file"
while read -r line; do
	IFS="," read -ra remote_hosts <<< "$line"
	if [[ "${remote_hosts[0]}" == "hosts" ]]; then
		break
	fi
done < $CSV_file


#remote_hosts=("${remote_hosts[@]/hosts}")

echo "${remote_hosts[@]}"

# Copy files to remote locations
for rhost in "${remote_hosts[@]}"; do
	echo "RHOST: $rhost"
	if [[ "$rhost" == hosts ]] || [[ "$rhost" == "localhost" ]] || [[ -z "$rhost" ]]; then
		continue
	fi

	if [[ -n "$KEY" ]]; then
		ssh_com="$KEY $rhost"
	else
		ssh_com="$rhost"
	fi
	echo $ssh_com

	echo "Testing SSH connection to $rhost with ssh $ssh_com"
	printf "hostname" > $cmd_filename
	HOSTNAME="$(RemoteExec $cmd_filename "$ssh_com")"
	if [[ -z "$HOSTNAME" ]]; then
		echo "Cannot connect with ssh $ssh_com."
		exit 1
	fi
	echo $HOSTNAME

	OPT="-av"

	echo "Compare ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	# Copy task files to remote
	eval rsync $OPT $KEY --exclude-from "rsyncexclude_task.txt" --size-only  ./$PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/
	# Copy framework files to remote
	eval rsync $OPT $KEY --include-from "rsyncinclude_framework.txt" --exclude='*' --size-only  ./ $rhost:$REMOTE_PATH/
done
