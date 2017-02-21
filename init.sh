celery_cont_name="celery-flower"
rabbit_cont_name="rabbit"
worker_cont_name="celery-worker"
master_image="pyotr777/celery-chainer-flower"
worker_image="pyotr777/celery-chainer-worker"
worker_image_cuda="pyotr777/celery-chainer-worker-cuda:8.0-devel-ubuntu16.04"
config_file="config.sh"
CSV_file="infra.csv"
clean_script="infra_clean.sh"
cmd_filename="remote_command.sh"
ssh_options="-o ServerAliveInterval=10"
concurrency=1

debug="1"

RemoteExec() {
	filename=$1
	host=$2
	key=$3
	#filename="remote_command.sh"
	echo "" >> $filename
	echo  'cd $HOME' >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	if [[ -n "$debug" ]]; then
		{
			cmd="scp $key $filename $host:"
			echo "$cmd" >&2
			eval $cmd
		}
	else
		{
			cmd="scp $key $filename $host:"
			eval $cmd
		} &>/dev/null
	fi
	if [[ -n "$debug" ]]; then
		{
			cmd="ssh $key $ssh_options $host ./$filename"
			echo "$cmd" >&2
			eval $cmd
		}
	else
		{
			cmd="ssh $key $ssh_options $host ./$filename"
			eval $cmd
		} 2>/dev/null
	fi
}

LocalExec() {
	filename=$1
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	./$filename
}


# Remove user name from host address: ubuntu@host.com -> host.com
function hostAddress {
	host=$1
	ifs=$IFS
	IFS='@' arr=( $(echo "$host") )
	IFS=$ifs
	if [ ${#arr[@]} -gt 1 ]; then
		echo ${arr[1]}
	else
		echo $host
	fi
}


function message {
    echo -en "\033[38;5;70m $1\033[m\n"
}

function error_message {
    echo ""
    echo -en "\033[38;5;124m $1\033[m\n"
    echo " "
}