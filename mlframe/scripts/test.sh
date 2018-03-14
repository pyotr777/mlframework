#!/bin/bash

if [ $1 ]; then
	N=$1
fi
echo "Running test command on $(hostname) pars: $@"
for i in {1..5}; do
	echo "$(hostname)($N):$i"
	echo "($N):$i"
	sleep 1
	echo "$(hostname)($N) err:$i" >&2
done
exit 125
