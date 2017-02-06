#!/bin/bash
# Read infrastructure configuration from infra.csv file.
# Return host with master container.

infra_CSV="infra.csv"

lines=( $(cat "$infra_CSV") )
#echo "Read ${#lines[@]} lines."
ifs=$IFS
for line in "${lines[@]}"; do
	IFS="," read -ra arr <<< "$line"
	#echo "${#arr[@]} elements, 0: ${arr[0]}"
	if [[ "${arr[0]}" == "hosts" ]]; then
		hosts=("${arr[@]}")
		#echo "Have ${#hosts[@]} hosts."
	elif [[ "${arr[0]}" == "master" ]]; then
		#echo "master arr: ${arr[@]}"
		master="${arr[1]}"
		#echo $master
	fi
done
IFS=$ifs
#echo "hosts: ${hosts[@]}; master: $master"
masterhost="${hosts[$((master+1))]}"
echo "$masterhost"