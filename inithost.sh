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
SSH_COM=""

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
	cmd=$1
	host=$2
	filename="remote_command.sh"
	echo "Executing commands on $host"
	#echo "tmp file: $filename"
	echo "#!/bin/bash" > $filename
	printf "$cmd" >> $filename
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


#set -x

IFS="," remote_hosts=$REMOTE

# Add localhost to remote hosts array as element 0.
remote_hosts=( localhost ${remote_hosts[@]} )
# echo "Remote hosts: ${remote_hosts[@]}"


if [[ -n "$START_WORKER" ]]; then
	IFS="," worker_hosts=${START_WORKER//local/0}
fi

echo "Have ${#remote_hosts[@]} remote hosts: ${remote_hosts[@]}"
# Copy files to remote locations
for rhost in ${remote_hosts[@]}; do
	#echo $rhost
	if [[ "$rhost" == "localhost" ]]; then
		continue
	fi

	if [[ -n "$KEY" ]]; then
		SSH_COM="$KEY $rhost"
	else
		SSH_COM="$rhost"
	fi
	echo $SSH_COM

	echo "Testing SSH connection to $rhost with ssh $SSH_COM"
	HOSTNAME="$(RemoteExec hostname "$SSH_COM")"
	if [[ -z "$HOSTNAME" ]]; then
		echo "Cannot connect with ssh $SSH_COM."
		exit 1
	fi
	echo $HOSTNAME
	exit 0

	if [[ -z "$BROKER_ADDRESS" ]] && [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
		# Get local machine external address
		sshconnection=( $(RemoteExec "echo '$SSH_CONNECTION'" "$SSH_COM") )
		LOCAL_EXTERNAL_IP=${sshconnection[0]}

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
	if [[ "$START_MASTER" == "local" ]]; then
		START_MASTER=0
	fi
	master_host=${remote_hosts[$START_MASTER]}
	if [[ "$master_host" == "localhost" ]]; then
		ssh_com=""
		change_dir=""
	else
		ssh_com="ssh $KEY $master_host"
		change_dir="cd $REMOTE_PATH &&"
	fi
	eval $ssh_com docker ps -a
	echo "Starting Master on $master_host."
	eval $ssh_com $change_dir ./celery_rabbit.sh
	eval $ssh_com docker ps -a
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
	for i in $worker_hosts; do
		host=${remote_hosts[$i]}
		if [[ "$host" == "localhost" ]];then
			docker ps -a
			echo "Starting workers on $host."
			./start_celery_worker.sh -b $BROKER_ADDRESS -l $PROJ_FOLDER
			docker ps -a
		else
			ssh_com="$KEY $host"
			eval ssh $ssh_com "docker ps -a"
			echo "Starting workers on $host with $ssh_com."
			eval ssh $ssh_com "hostname && pwd && cd '$HOME/'$REMOTE_PATH && ./start_celery_worker.sh -b $BROKER_ADDRESS -l $PROJ_FOLDER"
			eval ssh $ssh_com "docker ps -a"
		fi
	done
fi

