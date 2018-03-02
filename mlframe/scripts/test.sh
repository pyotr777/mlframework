#!/bin/bash

echo "Running test command on $(hostname)"
for i in {1..5}; do
	echo $i
	sleep 1
done