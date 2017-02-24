#!/bin/bash
# Run python -m <project dir>.<task name> in master container.

usage=$(cat <<USAGEBLOCK
Usage:
$0 task_name
USAGEBLOCK
)

if [[ $# < 1 ]]; then
    echo "$usage"
    exit 0
fi

TASK=$1

# Read fixed parameters
. init.sh
# Read configuration parameters
. $config_file

if [[ -n "$KEY" ]]; then
	key_opt="-i $KEY"
fi


master_host="$(./get_master_host.sh)"

cmd="python -m $PROJ_FOLDER.$TASK"
cmd="docker exec -t $celery_cont_name $cmd"
echo "Run $cmd in container $celery_cont_name on host $master_host with ssh $key_opt"

echo "#!/bin/bash" > $cmd_filename
echo "$cmd" >> $cmd_filename


if [[ "$master_host" == "localhost" ]]; then
	LocalExec $cmd_filename
else
	RemoteExec $cmd_filename $master_host "$key_opt"
fi

# Download output.csv from master
if [[ -n "$debug" ]]; then
	OPT="-avii"
else
	OPT="-av"
fi

if [[ -n "$KEY" ]]; then
	SSH_KEY="-e \"ssh $key_opt\""
else
	SSH_KEY=""
fi

cmd="rsync $OPT --include-from \"rsyncinclude_results.txt\" --exclude='*' $master_host:$REMOTE_PATH/ . "
if [[ -n "$debug" ]]; then
	echo "Download files"
	echo "$cmd"
	eval $cmd
else
	eval $cmd 2>/dev/null
fi

