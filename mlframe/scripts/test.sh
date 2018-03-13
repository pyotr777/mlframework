#!/bin/bash

if [ $1 ]; then
	N=$1
fi
echo "Running test command on $(hostname)"
for i in {1..5}; do
	echo "$(hostname)($N):$i"
	echo "output $i"
	#sleep 0.4
	echo "$(hostname) err$i" >&2
done
exit 125
