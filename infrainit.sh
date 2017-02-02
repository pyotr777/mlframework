#!/bin/bash

# Start framework infrastructure on local and/or remote hosts.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# TODO
# [V] Check that remote folders exist (before calling rsync)
# [V] Check that docker installed
# [?] Check taht docker images exist. Pushed images with Chainer to dockerhub.
# [ ] Before starting RabbitMQ and Celery Flower containers check that ports are not used
# [ ] Use better terms for explaining broker, project folder, task, framework


usage=$(cat <<USAGEBLOCK
Usage:
$0 -a <[user@]host1,[user@]host2...> [-f] [-i <ssh key file>] -l <dirname> -r <path> [-b <broker address>] [-m local/N] [-w local,N1,N2...]
Options:
	-a	Remote hosts addresses, comma-separated list.
	-d	Local directory with task (project) files.
	-r	Remote path for storing task and framework files relative to home directory.
	-b	External address of the machine with Master and Broker containers.
	-m	Start Celery master and broker on local machine or on host N (N is a number).
	-w	Start workers on specified hosts. N1,N2... - comma separated numbers of hosts, listed in -a. First host has number 1.
	-f	Read all the above options from file config.sh. If -f option not used config.sh will be overwritten with new options provided as arguments to this script.
USAGEBLOCK
)

if [[ $# < 1 ]]; then
    echo "$usage"
    exit 0
fi

config_file="config.sh"

KEY=""
REMOTE=""
ssh_com=""

while test $# -gt 0; do
    case "$1" in
        -h | --help)
            echo $usage
            exit 0
            ;;
        -i)
            KEY="-i $2";shift;
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
        -b)
            BROKER_ADDRESS="$2";shift;
            ;;
        -m)
            START_MASTER="$2";shift;
            ;;
        -w)
            START_WORKER="$2";shift;
            ;;
        -f)
			READ_FROM_CONFIG=YES
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

# Output variable assignment statement for configuration file
function saveVar {
	var=$1
	eval "val=\$$var"
	if [[ -n "$val" ]]; then
		echo "$var=\"$val\""
	fi
}


if [[ -n "$READ_FROM_CONFIG" ]]; then
	echo "Reading configuration from $config_file"
	. $config_file
fi

if [[ -n "$REMOTE" ]]; then
	if [[ -z "$REMOTE_PATH" ]] || [[ -z "$PROJ_FOLDER" ]]; then
		echo "$usage"
		echo "Necessary options: remote address (-a), project folder (-l) and remote path (-r)."
		exit 0
	fi
fi

if [[ -z "$START_MASTER" ]] && [[ -z "$START_WORKER" ]]; then
	echo "$usage"
	echo "Provide one of the options -m or -w or both."
	exit 0
fi

if [[ -z "$START_MASTER" ]] && [[ -z "$BROKER_ADDRESS" ]]; then
	echo "$usage"
	echo "If not starting master on the remote host need broker address (-b)."
	exit 0
fi



# Save configuration
cat <<- CMDBLOCK_CFG > $config_file
$(saveVar REMOTE_PATH)
$(saveVar PROJ_FOLDER)
$(saveVar REMOTE)
$(saveVar KEY)
$(saveVar BROKER_ADDRESS)
$(saveVar START_MASTER)
$(saveVar START_WORKER)
CMDBLOCK_CFG


RemoteExec() {
	filename=$1
	host=$2
	key=$3
	#filename="remote_command.sh"
	#echo "(RemoteExec) Executing commands from $filename on $host with ssh key $key"
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	{
		cmd="scp $key $filename $host:"
		#echo "Executing command: $cmd"
		eval $cmd
	}
	{
		cmd="ssh $key $host ./$filename"
		#echo "Executing command: $cmd"
		eval $cmd
	} 2> /dev/null
}

LocalExec() {
	filename=$1
	echo "Executing commands from $filename on local machine"
	cat $filename
	echo "---"
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	./$filename
}


SaveHostData() {
	filename=$1
	hosts=$2
	master=$3
	broker=$4
	workers=$5
	echo "hosts,$hosts" > $filename
	echo "master,$master" >> $filename
	echo "broker,$broker" >> $filename
	echo "workers,$workers" >> $filename
	echo "remote_path,$REMOTE_PATH" >> $filename
	echo "folder,$PROJ_FOLDER" >> $filename
	#cat $filename
}

function message {
    echo ""
    echo -en "\033[38;5;70m $1\033[m\n"
    echo " "
}

function error_message {
    echo ""
    echo -en "\033[38;5;124m $1\033[m\n"
    echo " "
}


set -e

IFS="," remote_hosts=$REMOTE

# Add localhost to remote hosts array as element 0.
remote_hosts=(localhost ${remote_hosts[@]})
# echo "Remote hosts: ${remote_hosts[@]}"

if [[ -n "$START_WORKER" ]]; then
	IFS="," read -ra worker_hosts <<< "${START_WORKER//local/0}"
	#echo "Worker hosts: ${worker_hosts[@]}"
	#echo "Remote hosts: ${remote_hosts[@]}"
fi

if [[ "$START_MASTER" == "local" ]]; then
	START_MASTER=0
fi
master_host=${remote_hosts[$START_MASTER]}


CSV_file="infra.csv"
SaveHostData "$CSV_file" "localhost,$REMOTE" "$START_MASTER" "$START_MASTER" "${START_WORKER//local/0}"

# Create infrastructure cleaning script
clean_script="infra_clean.sh"
echo "#!/bin/bash" > $clean_script
for i in "${worker_hosts[@]}"; do
	# echo "$i ${remote_hosts[$i]}"
	if [[ "${remote_hosts[$i]}" != "localhost" ]];then
		cmd="ssh $KEY ${remote_hosts[$i]} $REMOTE_PATH/clean_celery_worker.sh"
	else
		cmd="./clean_celery_worker.sh"
	fi
	echo $cmd >> $clean_script
done

if [[ "$master_host" != "localhost" ]]; then
	cmd="ssh $KEY $master_host $REMOTE_PATH/clean_celery_master.sh"
else
	cmd="./clean_celery_master.sh"
fi
echo $cmd >> $clean_script
echo "rm $CSV_file" >> $clean_script
echo "rm $clean_script" >> $clean_script

chmod +x $clean_script


cmd_filename="remote_command.sh"

echo "Have ${#remote_hosts[@]} hosts: ${remote_hosts[@]}"
echo "Have ${#worker_hosts[@]} worker hosts: ${worker_hosts[@]}"
# Copy files to remote locations
for rhost in "${remote_hosts[@]}"; do
	#echo $rhost
	if [[ "$rhost" == "localhost" ]]; then
		continue
	fi

	echo "Testing SSH connection to $rhost with ssh key $KEY"

	cat <<- CMDBLOCK0 > $cmd_filename
	{
		if [[ ! -d $REMOTE_PATH ]]; then
			mkdir -p $REMOTE_PATH
		fi
	} &>/dev/null
	hostname
	CMDBLOCK0
	#RemoteExec $cmd_filename $rhost $KEY
	HOSTNAME=$(RemoteExec $cmd_filename $rhost $KEY)
	if [[ -z "$HOSTNAME" ]]; then
		echo "Cannot connect with ssh $KEY $rhost."
		exit 1
	fi
	echo $HOSTNAME

	# Testing docker on remote hosts
	echo "Testing installed docker version on $rhost"
	cat <<- CMDBLOCK_docker > $cmd_filename
	{
		docker version | grep -i "version"
	} 2>/dev/null
	echo \$version
	CMDBLOCK_docker
	#RemoteExec $cmd_filename $rhost $KEY
	docker_version=$(RemoteExec $cmd_filename $rhost $KEY)
	if [[ -z "$docker_version" ]]; then
		error_message "Docker is not installed on $rhost."
		exit 1
	else
		echo "On $rhost installed docker $docker_version."
	fi



	if [[ -z "$BROKER_ADDRESS" ]] && [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
		# Get local machine external address
		printf "echo \"\$SSH_CONNECTION\"" > $cmd_filename
		echo "" >> $cmd_filename
		output_string=$(RemoteExec $cmd_filename $rhost $KEY)
		IFS=" " read -ra arr <<< "$output_string"
		LOCAL_EXTERNAL_IP=${arr[0]}

		if [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
			echo "Could not determine external IP address."
			exit 1
		fi
		echo "Local machine external IP: $LOCAL_EXTERNAL_IP"
	fi
	set +x
	OPT="-av"
	if [[ -n "$KEY" ]]; then
		SSH_KEY="-e \"ssh $KEY\""
	else
		SSH_KEY=""
	fi

	message "Sync ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	# Copy task files to remote
	cmd="rsync $OPT $SSH_KEY --exclude-from rsyncexclude_task.txt --size-only  ./$PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	message $cmd
	eval $cmd
	message "Sync ./ with $rhost:$REMOTE_PATH"
	# Copy framework files to remote
	eval rsync $OPT $SSH_KEY --include-from "rsyncinclude_framework.txt" --exclude='*' --size-only  ./ $rhost:$REMOTE_PATH/
done


# Starting master
if [[ -n "$START_MASTER" ]]; then
	cat <<- CMDBLOCK > $cmd_filename
	echo "Starting master at $master_host"
	CMDBLOCK

	if [[ "$master_host" != "localhost" ]]; then
		echo "cd $REMOTE_PATH" >> $cmd_filename
	fi

	cat <<- CMDBLOCK2 >> $cmd_filename
	./start_celery_master.sh
	docker ps
	CMDBLOCK2
	echo "Command file:"
	cat $cmd_filename
	if [[ "$master_host" == "localhost" ]]; then
		LocalExec $cmd_filename
	else
		RemoteExec $cmd_filename $master_host $KEY
	fi
	if [[ -z "$BROKER_ADDRESS" ]]; then
		if [[ "$master_host" == "localhost" ]]; then
			BROKER_ADDRESS=$LOCAL_EXTERNAL_IP
		else
			BROKER_ADDRESS="$master_host"
		fi
		echo "Set Broker address to $BROKER_ADDRESS."
	fi
fi


# Starting workers
if [[ -n "$START_WORKER" ]]; then
	echo "Workers: ${#worker_hosts[@]}"
	for i in "${worker_hosts[@]}"; do
		echo "worker $((i+1))"
		host=${remote_hosts[$i]}

		if [[ -n "$BROKER_ADDRESS" ]]; then
			BROKER_OPTIONS="-b $BROKER_ADDRESS"
		fi
		if [[ -n "$PROJ_FOLDER" ]]; then
			PROJ_FOLDER_OPTIONS="-l $PROJ_FOLDER"
		fi

		cat <<- CMDBLOCK3 > $cmd_filename
		echo "Starting workers at $host. BROKER_ADDRESS=$BROKER_ADDRESS PROJ_FOLDER=$PROJ_FOLDER"
		CMDBLOCK3

		if [[ "$host" != "localhost" ]]; then
			echo "cd $REMOTE_PATH" >> $cmd_filename
		fi
		cat <<- CMDBLOCK4 >> $cmd_filename
		echo "$(hostname):$(pwd)"
		./start_celery_worker.sh $BROKER_options $PROJ_FOLDER_OPTIONS
		docker ps
		CMDBLOCK4

		if [[ "$host" == "localhost" ]];then
			LocalExec "$cmd_filename"
		else
			output_string=$(RemoteExec $cmd_filename $host $KEY)
			echo "$output_string"
		fi
	done
fi

