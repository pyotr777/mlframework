#!/bin/bash
# Print CL arguments

echo "Have $# arguments: $*"
echo "Error" >&2
for i in {1..5}; do
	echo $i
	sleep 1
done