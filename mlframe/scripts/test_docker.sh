#!/bin/bash

# Tests docker and nvidia-docker versions

docker_ver=$(docker version 2>/dev/null)
if [ $? -ge 1 ];then
	echo "Error connecting to Docker"
	exit 1
fi
echo "$docker_ver"

nvdocker_ver=$(nvidia-docker version 2>/dev/null)
if [ $? -ge 1 ];then
	echo "Error connecting to Nvidia-Docker"
	exit 1
fi
echo "$nvdocker_ver"
