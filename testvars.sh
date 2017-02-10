#!/bin/bash

A=1
B=2
D=4

# Output variable assignment statement for configuration file
function saveVar {
	var=$1
	eval "val=\$$var"
	if [[ -n "$val" ]]; then
		echo "$var=\"$val\""
	fi
}

save_vars=( A B C D )
echo "${#save_vars[@]}"

for var in "${save_vars[@]}"; do
	line="$(saveVar $var)"
	if [ -n "$line" ]; then
		echo "$line"
	fi
done