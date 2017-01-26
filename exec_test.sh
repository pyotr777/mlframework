#!/bin/bash
# Test remote execution

RemoteExec() {
	cmd=$1
	host=$2
	filename="remote_command.sh"
	#echo "Executing commands on $host"
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

cmd=$(cat <<CMDBLOCK
echo "Start"
hostname
whoami
echo "end"
CMDBLOCK)

host="stairlab"

#RemoteExec "$cmd" "$host"
#echo "---"
var=$(RemoteExec hostname "$host")
echo "var = $var"