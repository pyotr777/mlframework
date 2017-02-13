#!/bin/bash
# (Re)Start Celery workers.
# Parameters read from CL and from infra.csv file.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# Variables initialisation
. init.sh

usage=$(cat <<USAGEBLOCK
(Re)Start Celery workers.
Parameters are taken from CL and from infra.csv file. CL arguments has priority.

$0 [-a <[user@]host1,[user@]host2...>] [-i identity file] -d <dirname> -r <path>

Options:
    -a  Hosts addresses, comma-separated list.
    -d  Local folder with task (project) files.
    -r  Remote path for storing task and framework files relative to home dir.
    -m	Master host: address of Celery master and broker host.
USAGEBLOCK
)


KEY=""
key_opt=""
worker_hosts=""
ssh_com=""
BROKER_HOST=""

if [[ -f "$CSV_file" ]]; then
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
	        workers)
	            START_WORKER=("${arr[@]/workers}")
	            if [[ -n "$debug" ]]; then
	            	echo "workers: ${START_WORKER[@]}"
	            fi
	            ;;
	        broker)
				BROKER_HOST="${arr[1]}"
				if [[ -n "$debug" ]]; then
					echo "Broker host from CSV: $BROKER_HOST"
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
				KEY="${arr[1]}";key_opt="-i ${arr[1]}";shift;
	            ;;
	    esac
	done < $CSV_file
fi

# Parcing worker hosts
if [[ "${#START_WORKER[@]}" -gt 0 ]]; then
	worker_hosts=()
	for i in "${START_WORKER[@]}"; do
		if [[ -n "$i" ]]; then
			# remote_hosts[0] is empty element due to "${arr[@]/hosts}" operation.
			worker_hosts+=(${remote_hosts[$((i+1))]})
		fi
	done
fi

# Parcing master host address
if [[ -n "$BROKER_HOST" ]]; then
	BROKER_ADDRESS="${remote_hosts[$((BROKER_HOST+1))]}"
fi


if [ $# -gt 0 ]; then
	if [[ -n "$debug" ]]; then
		echo "Parcing CL arguments"
	fi
fi

while test $# -gt 0; do
    case "$1" in
        -h | --help)
            echo "$usage"
            exit 0
            ;;
        -i)
            KEY="$2";key_opt="-i $2";shift;
            ;;
        -a)
            worker_addresses="$2";shift;
            ;;
        -d)
            PROJ_FOLDER="$2";shift;
            ;;
        -r)
            REMOTE_PATH="$2";shift;
            ;;
        -b)
            BROKER_ADDRESS="$2";shift;
            ;;
		--debug)
			debug=YES
			;;
        --)
            shift
            break;;
        -*)
            echo "Invalid option: $1"
            echo "$usage"
            exit 1;;
    esac
    shift
done


echo "worker_addresses=$worker_addresses"
echo "worker hosts=${worker_hosts[@]}"
if [[ -n "$worker_addresses" ]]; then
	IFS="," read -ra worker_hosts <<< "$worker_addresses"
	update_hosts="$worker_addresses"
else
	update_hosts=$( IFS="," echo "${worker_hosts[*]}")
fi


if [[ -n "$debug" ]]; then
	echo "Worker hosts: ${worker_hosts[@]} (${#worker_hosts[@]})"
	echo "Update hosts: $update_hosts"
	echo "Broker address: $BROKER_ADDRESS"
fi

if [[ -z "$worker_hosts" ]]; then
	echo "$usage"
	echo "Provide hosts addresses either with CL parameter -a or CSV file $CSV_file."
	exit 1
fi

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


echo "./update_files.sh -a $update_hosts"
# Updating files on remote hosts
./update_files.sh -a $update_hosts


# Starting workers
if [[ -n "$worker_hosts" ]]; then

	if [[ -n "$debug" ]]; then
		echo "Starting workers: ${#worker_hosts[@]}"
	fi
	for host in "${worker_hosts[@]}"; do
		message "Starting worker at $host."

		# Options for start_celery_worker.sh
		if [[ -n "$BROKER_ADDRESS" ]]; then
			BROKER_OPTIONS="-b $(hostAddress $BROKER_ADDRESS)"
		fi
		if [[ -n "$PROJ_FOLDER" ]]; then
			PROJ_FOLDER_OPTIONS="-d $PROJ_FOLDER"
		fi

		cat <<- CMDBLOCK3 > $cmd_filename
		if [[ -n "$debug" ]]; then
			echo "BROKER_ADDRESS=$BROKER_ADDRESS PROJ_FOLDER=$PROJ_FOLDER"
		fi
		CMDBLOCK3

		if [[ "$host" != "localhost" ]]; then
			echo "cd $REMOTE_PATH" >> $cmd_filename
		fi
		cat <<- CMDBLOCK4 >> $cmd_filename
		if [[ -n "$debug" ]]; then
			echo "Working dir: \$(hostname):\$(pwd)"
		fi
		./start_celery_worker.sh $BROKER_OPTIONS $PROJ_FOLDER_OPTIONS
		#if [[ -n "$debug" ]]; then
		sleep 1
		docker ps | grep "$worker_cont_name"
		#fi
		CMDBLOCK4

		if [[ "$host" == "localhost" ]];then
			LocalExec "$cmd_filename"
		else
			RemoteExec $cmd_filename $host "$key_opt"
		fi
	done
fi

sleep 1
./check_celery_status.sh




