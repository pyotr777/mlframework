#!/bin/bash

# Start framework infrastructure on local and/or remote hosts.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# TODO
# [ ] Check that remote folders exist (before calling rsync)
# [ ] Check that docker installed
# [ ] Check taht docker images exist
# [ ] Before starting RabbitMQ and Celery Flower containers check that ports are not used
# [ ] Use better terms for explaining broker, project folder, task, framework


usage=$(cat <<USAGEBLOCK
Usage:
$0 -a <[user@]host1,[user@]host2...> [-i identity file] -l <dirname> -r <path> [-b <broker address>] [-m local/N] [-w local,N1,N2...]
Options:
	-a	Remote hosts addresses, comma-separated list.
	-l	Local folder with task (project) files.
	-r	Remote path for storing task and framework files relative to home dir.
	-b	External address of the machine with Master and Broker containers.
	-m	Start Celery master and broker on local machine or on host N (N is a number).
	-w	Start workers on specified hosts. N1,N2... - comma separated numbers of hosts, listed in -a. First host has number 1.
USAGEBLOCK
)

if [[ $# < 1 ]]; then
    echo "$usage"
    exit 0
fi

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
        -l)
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


if [[ -z "$REMOTE" ]] || [[ -z "$REMOTE_PATH" ]] || [[ -z "$PROJ_FOLDER" ]]; then
	echo "$usage"
	echo "Necessary options: remote address (-a), project folder (-l) and remote path (-r)."
	exit 0
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

LocalExec() {
	filename=$1
	#echo "Executing commands from $filename on local machine/"
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
	echo "hosts, $hosts" > $filename
	echo "master,$master" >> $filename
	echo "broker,$broker" >> $filename
	echo "workers,$workers" >> $filename
	#cat $filename
}

#set -x

IFS="," remote_hosts=$REMOTE

# Add localhost to remote hosts array as element 0.
remote_hosts=( localhost ${remote_hosts[@]} )
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

	if [[ -n "$KEY" ]]; then
		ssh_com="$KEY $rhost"
	else
		ssh_com="$rhost"
	fi
	#echo $ssh_com

	echo "Testing SSH connection to $rhost with ssh $ssh_com"
	printf "hostname" > $cmd_filename
	HOSTNAME="$(RemoteExec $cmd_filename "$ssh_com")"
	if [[ -z "$HOSTNAME" ]]; then
		echo "Cannot connect with ssh $ssh_com."
		exit 1
	fi
	echo $HOSTNAME

	if [[ -z "$BROKER_ADDRESS" ]] && [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
		# Get local machine external address
		printf "echo \"\$SSH_CONNECTION\"" > $cmd_filename
		echo "" >> $cmd_filename
		output_string="$(RemoteExec $cmd_filename "$ssh_com")"
		IFS=" " read -ra arr <<< "$output_string"
		LOCAL_EXTERNAL_IP=${arr[0]}

		if [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
			echo "Could not determine external IP address."
			exit 1
		fi
		echo "Local machine external IP: $LOCAL_EXTERNAL_IP"
	fi

	OPT="-av"
	SSH_KEY="-e 'ssh -i $KEY'"

	echo "Compare ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	# Copy task files to remote
	eval rsync $OPT $KEY --exclude-from "rsyncexclude_task.txt" --size-only  ./$PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/

	# Copy framework files to remote
	eval rsync $OPT $KEY --include-from "rsyncinclude_framework.txt" --exclude='*' --size-only  ./ $rhost:$REMOTE_PATH/
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
		RemoteExec $cmd_filename $master_host
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
		echo $i
		host=${remote_hosts[$i]}
		cat <<- CMDBLOCK3 > $cmd_filename
		echo "Starting workers at $host. BROKER_ADDRESS=$BROKER_ADDRESS; PROJ_FOLDER=$PROJ_FOLDER"
		CMDBLOCK3

		if [[ "$host" != "localhost" ]]; then
			echo "cd $REMOTE_PATH" >> $cmd_filename
		fi
		cat <<- CMDBLOCK4 >> $cmd_filename
		echo "$(hostname):$(pwd)"
		./start_celery_worker.sh -b $BROKER_ADDRESS -l $PROJ_FOLDER
		docker ps
		CMDBLOCK4

		if [[ "$host" == "localhost" ]];then
			LocalExec "$cmd_filename"
		else
			#set -x
			if [[ -n "$KEY" ]]; then
				ssh_com="$KEY $host"
			else
				ssh_com="$host"
			fi
			cat $cmd_filename
			output_string="$(RemoteExec $cmd_filename $ssh_com)"
			echo "$output_string"
		fi
	done
fi

