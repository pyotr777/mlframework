#!/bin/bash

if [ $1 ]; then
	N=$1
fi
echo "Running test command on $(hostname)"
for i in {1..6}; do
	echo "$(hostname)$N:$i"
	sleep 2
done
