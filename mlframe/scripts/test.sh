#!/bin/bash

if [ $1 ]; then
	N=$1
fi
echo "Running test command on $(hostname)"
for i in {1..10}; do
	echo "$(hostname)($N):$i"
	sleep 0.1
	echo "$(hostname) err" >&2
done
exit 125
