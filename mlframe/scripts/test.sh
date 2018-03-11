#!/bin/bash

if [ $1 ]; then
	N=$1
fi
echo "Running test command on $(hostname)"
for i in {1..2}; do
	echo "$(hostname)($N):$i"
	sleep 0.4
	echo "$(hostname) err$i" >&2
done
exit 125
