celery_cont_name="celery-flower"
rabbit_cont_name="rabbit"
worker_cont_name="celery-worker"
master_image="pyotr777/celery-chainer-flower"
worker_image="pyotr777/celery-chainer-worker"
config_file="config.sh"
CSV_file="infra.csv"
clean_script="infra_clean.sh"
cmd_filename="remote_command.sh"
ssh_options="-o ServerAliveInterval=10"

debug="1"

RemoteExec() {
	filename=$1
	host=$2
	key=$3
	#filename="remote_command.sh"
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	{
		cmd="scp $key $filename $host:"
		#if [[ -n "$debug" ]]; then
		#		echo "Executing command: $cmd"
		#fi
		eval $cmd
	}
	{
		cmd="ssh $key $ssh_options $host ./$filename"
		#echo "Executing command: $cmd"
		eval $cmd
	}
}

LocalExec() {
	filename=$1
	#if [[ -n "$debug" ]]; then
	#	echo "Executing commands from $filename on local machine"
	#	cat $filename
	#fi
	echo "" >> $filename
	printf "rm $filename" >> $filename
	chmod +x $filename
	./$filename
}