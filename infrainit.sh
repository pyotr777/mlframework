#!/bin/bash

# Start framework infrastructure on local and/or remote hosts.
# Copyright (C) 2017 Bryzgalov Peter @ Stair Lab CHITECH

# Version 0.4alpha

# TODO
# [V] Check that remote folders exist (before calling rsync)
# [V] Check that docker installed
# [?] Check taht docker images exist. Pushed images with Chainer to dockerhub.
# [ ] Before starting RabbitMQ and Celery Flower containers check that ports are not used
# [ ] Use better terms for explaining broker, project folder, task, framework
# [ ] Check that GatewayPorts set to yes in /etc/ssh/sshd_config on worker hosts (for SSH tunnels).

usage=$(cat <<USAGEBLOCK
Usage:
$0 -a <[user@]host1,[user@]host2...> [-f] [-i <ssh key file>] -r <path> -d <dirname> [-m local/N] [-w local,N1,N2...]
Options:
	-a	Remote hosts addresses, comma-separated list.
	-r	Remote path for storing task and framework files relative to home directory.
	-d	Name of directory with task (project) files.
	-m	Master host: start Celery master and broker on local machine or on host N (N is a number).
	-w	Start workers on specified hosts. N1,N2... - comma separated numbers of hosts, listed in -a. First host has number 1.
	-f	Read all the above options from file config.sh. If -f option not used config.sh will be overwritten with new options provided as arguments to this script.
USAGEBLOCK
)

if [[ $# < 1 ]]; then
	echo "$usage"
	exit 0
fi


# Variables initialisation
. init.sh

KEY=""
key_opt=""
REMOTE=""
ssh_com=""

make_ssh_tunnels=""

while test $# -gt 0; do
	case "$1" in
		-h | --help)
			echo $usage
			exit 0
			;;
		-i)
			KEY="$2";key_opt="-i $2";shift;
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
	if [[ -n "$KEY" ]]; then
		key_opt="-i $KEY"
	fi
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
echo "" > $config_file
save_vars=( REMOTE_PATH PROJ_FOLDER REMOTE KEY BROKER_ADDRESS START_MASTER START_WORKER )
for var in "${save_vars[@]}"; do
	line="$(saveVar $var)"
	if [ -n "$line" ]; then
		echo "$line" >> $config_file
	fi
done


SaveHostData() {
	filename=$1
	hosts=$2
	master=$3
	broker=$4
	workers=$5
	key=$6
	echo "hosts,$hosts" > $filename
	echo "master,$master" >> $filename
	if [[ -n "$broker" ]]; then
		echo "broker,$broker" >> $filename
	fi
	echo "workers,$workers" >> $filename
	echo "remote_path,$REMOTE_PATH" >> $filename
	echo "folder,$PROJ_FOLDER" >> $filename
	if [[ -n "$key" ]]; then
		echo "key,$key" >> $filename
	fi
}


set -e

IFS="," remote_hosts=$REMOTE

# Add localhost to remote hosts array as element 0.
remote_hosts=(localhost ${remote_hosts[@]})
# echo "Remote hosts: ${remote_hosts[@]}"

if [[ -n "$START_WORKER" ]]; then
	IFS="," read -ra worker_hosts <<< "${START_WORKER//local/0}"
fi

if [[ "$START_MASTER" == "local" ]]; then
	START_MASTER=0
fi
master_host=${remote_hosts[$START_MASTER]}


SaveHostData "$CSV_file" "localhost,$REMOTE" "$START_MASTER" "$START_MASTER" "${START_WORKER//local/0}" "$KEY"

# Create infrastructure cleaning script
echo "#!/bin/bash" > $clean_script
echo "set -e" >> $clean_script
for i in "${worker_hosts[@]}"; do
	# echo "$i ${remote_hosts[$i]}"
	if [[ "${remote_hosts[$i]}" != "localhost" ]];then
		cmd="ssh $key_opt ${remote_hosts[$i]} $REMOTE_PATH/clean_celery_worker.sh"
	else
		cmd="./clean_celery_worker.sh"
	fi
	echo $cmd >> $clean_script
done

if [[ "$master_host" != "localhost" ]]; then
	cmd="ssh $key_opt $master_host $REMOTE_PATH/clean_celery_master.sh"
else
	cmd="./clean_celery_master.sh"
fi
echo $cmd >> $clean_script
echo "rm $CSV_file" >> $clean_script
echo "rm $clean_script" >> $clean_script

chmod +x $clean_script

if [[ -n "$debug" ]]; then
	echo "Have ${#remote_hosts[@]} hosts: ${remote_hosts[@]}"
	echo "Have ${#worker_hosts[@]} worker hosts: ${worker_hosts[@]}"
fi


# Testing docker on remote hosts
for rhost in "${remote_hosts[@]}"; do
	if [[ "$rhost" == "localhost" ]]; then
		continue
	fi
	if [[ -n "$debug" ]]; then
		echo "Testing installed docker version on $rhost"
	fi
	cat <<- CMDBLOCK_docker > $cmd_filename
	{
		docker version | grep -i "version"
	} 2>/dev/null
	echo \$version
	CMDBLOCK_docker
	docker_version=$(RemoteExec $cmd_filename $rhost "$key_opt")
	if [[ -z "$docker_version" ]]; then
		error_message "Docker is not installed on $rhost."
		while true; do
			read -p "Use Docker installer script for Ubuntu? [y/n]" yn
			case $yn in
				[Yy]* ) cp install_docker_ubuntu.sh remote_command.sh; RemoteExec remote_command.sh $rhost "$key_opt"; break;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes [y] or no [n].";;
			esac
		done
	else
		if [[ -n "$debug" ]]; then
			echo "On $rhost installed docker $docker_version."
		fi
	fi
done

set -e


# Copy files to remote locations
for rhost in "${remote_hosts[@]}"; do
	#echo $rhost
	if [[ "$rhost" == "localhost" ]]; then
		continue
	fi

	if [[ -n "$debug" ]]; then
		echo "Testing SSH connection to $rhost with ssh key $KEY"
	fi

	cat <<- CMDBLOCK0 > $cmd_filename
	{
		if [[ ! -d $REMOTE_PATH ]]; then
			mkdir -p $REMOTE_PATH
		fi
	} &>/dev/null
	hostname
	CMDBLOCK0
	#RemoteExec $cmd_filename $rhost $KEY
	HOSTNAME=$(RemoteExec $cmd_filename $rhost "$key_opt")
	if [[ -z "$HOSTNAME" ]]; then
		error_message "Cannot connect with ssh $KEY $rhost."
		exit 1
	fi
	if [[ -n "$debug" ]]; then
		echo $HOSTNAME
	fi


	if [[ -z "$BROKER_ADDRESS" ]] && [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
		# Get local machine external address
		printf "echo \"\$SSH_CONNECTION\"" > $cmd_filename
		echo "" >> $cmd_filename
		output_string=$(RemoteExec $cmd_filename $rhost "$key_opt")
		IFS=" " read -ra arr <<< "$output_string"
		LOCAL_EXTERNAL_IP=${arr[0]}

		if [[ -z "$LOCAL_EXTERNAL_IP" ]]; then
			error_message "Could not determine external IP address of local machine."
			exit 1
		fi
		if [[ -n "$debug" ]]; then
			echo "Local machine external IP: $LOCAL_EXTERNAL_IP"
		fi
	fi

	if [[ -n "$debug" ]]; then
		OPT="-avii --progress"
	else
		OPT="-av --progress"
	fi
	if [[ -n "$key_opt" ]]; then
		SSH_KEY="-e \"ssh $key_opt\""
	else
		SSH_KEY=""
	fi

	message "Copying files to $rhost"

	if [[ -n "$debug" ]]; then
		echo "Sync ./$PROJ_FOLDER/ with $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	fi
	# Copy task files to remote
	cmd="rsync $OPT $SSH_KEY --exclude-from rsyncexclude_task.txt $PROJ_FOLDER/ $rhost:$REMOTE_PATH/$PROJ_FOLDER/"
	#message $cmd
	if [[ -n "$debug" ]]; then
		echo $cmd
		eval $cmd
	else
		eval $cmd &>/dev/null
	fi

	if [[ -n "$debug" ]]; then
		echo "Sync ./ with $rhost:$REMOTE_PATH"
	fi
	# Copy framework files to remote
	cmd="rsync $OPT $SSH_KEY --include-from rsyncinclude_framework.txt --exclude='*' ./ $rhost:$REMOTE_PATH/"
	if [[ -n "$debug" ]]; then
		echo $cmd
		eval $cmd
	else
		eval $cmd &>/dev/null
	fi
done




# Starting master
if [[ -n "$START_MASTER" ]]; then
	message "Starting master at $master_host. Celery Flower will be available at http://$(hostAddress "$master_host"):5555"

	echo "#!/bin/bash" > $cmd_filename
	if [[ "$master_host" != "localhost" ]]; then
		echo "cd $REMOTE_PATH" >> $cmd_filename
	fi

	cat <<- CMDBLOCK2 >> $cmd_filename
	./start_celery_master.sh
	if [[ -n "$debug" ]]; then
		docker ps | grep "$celery_cont_name"
	fi
	CMDBLOCK2

	if [[ -n "$debug" ]]; then
		echo "Command file $cmd_filename:"
		cat $cmd_filename
	fi

	if [[ "$master_host" == "localhost" ]]; then
		LocalExec $cmd_filename
	else
		RemoteExec $cmd_filename $master_host "$key_opt"
	fi

	if [[ -z "$BROKER_ADDRESS" ]]; then
		if [[ "$master_host" == "localhost" ]]; then
			BROKER_ADDRESS=$LOCAL_EXTERNAL_IP
		else
			BROKER_ADDRESS=$(hostAddress "$master_host")
		fi
		if [[ -n "$debug" ]]; then
			echo "Set Broker address to $BROKER_ADDRESS."
		fi
	fi
fi

worker_host_list=""

# Starting workers
if [[ -n "$START_WORKER" ]]; then
	if [[ -n "$debug" ]]; then
		echo "Stargint workers: ${#worker_hosts[@]}"
	fi
	for i in "${worker_hosts[@]}"; do
		host=${remote_hosts[$i]}
		message "Starting worker at host $host"

		# Add host to worker_host_list.
		if [[ -n "$worker_host_list" ]]; then
			worker_host_list="$worker_host_list, "
		fi
		worker_host_list="$worker_host_list$host"

		# Start SSH tunnel
		if [[ -n "$make_ssh_tunnels" ]] && [[ "$host" != "localhost" ]]; then
			if [[ -n "$debug" ]]; then
				echo "Starting SSH tunnel from $host:5672 to $master_host:5672"
			fi
			cmd="ssh -R 0.0.0.0:5672:localhost:5672 $key_opt $host -f -N -o ServerAliveInterval=10"
			if [[ -n "$debug" ]]; then
				echo $cmd
			fi
			echo $cmd > $cmd_filename
			echo "echo \$!" >> $cmd_filename
			set -x
			if [[ "$master_host" == "localhost" ]]; then
				LocalExec $cmd_filename
			else
				RemoteExec $cmd_filename $master_host "$key_opt"
			fi

			# Change BROKER_ADDRESS so that workers connect to SSH tunnel on host machine of Docker container.
			BROKER_ADDRESS="localhost"
		fi


		# Options for start_celery_worker.sh
		if [[ -n "$BROKER_ADDRESS" ]]; then
			BROKER_OPTIONS="-b $BROKER_ADDRESS"
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

sleep 3
./check_celery_status.sh

message "Infrastructure initialisation complete."
message "Master and broker are running on $master_host. Workers on $worker_host_list."
echo "Use ./infra_clean.sh command to remove infrastructure."
