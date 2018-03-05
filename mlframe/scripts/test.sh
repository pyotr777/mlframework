#!/bin/bash

echo "Running test command on $(hostname)"
for i in {1..15}; do
	echo $(hostname)$i
	sleep 2
done
