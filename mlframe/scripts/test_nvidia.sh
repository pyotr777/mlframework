#!/bin/bash

# Test installed NVIDIA drivers, CUDA and cuDNN versions on Ubuntu
# Ver.1.0
# 2018 (C) Peter Bryzgalov @ CHITECH Stair Lab

# Get NVIDIA driver version
version_file="/proc/driver/nvidia/version"
NV_DRV="x"
CUDA="x"
cuDNN="x"

debug="yes"

if [ "$debug" ]; then
	echo "$(basename $0) arguments: $@"
fi

function return_states {
	echo "NVDRV:$NV_DRV,CUDA:$CUDA,cuDNN:$cuDNN"
	exit 0
}

if [ ! -f "$version_file" ]; then
	echo "Driver not found"
	return_states
fi

# Files should exist and permissions should be all 666
if [ "$(stat -c "%a" /dev/nvidia* | grep -v 666)" ]; then
	echo "Device files /dev/nvidia* permissions should be all 666"
	stat -c "%a %n" /dev/nvidia*
fi

# Driver version
NV_DRV=$(grep -Eo "Kernel Module\s+([0-9\.]+)" /proc/driver/nvidia/version | awk '{ print $3 }')
#echo $NV_DRV


function CheckCudaLocation {
	CUDA_LOCATION=$1; shift
	# If path is a link
	if [ -h "$CUDA_LOCATION" ];then
		# Check that readlink command exists
		if [ ! "$(readlink /  2>&1 1>/dev/null)" ]; then
			# Get link target
			CUDA=$(readlink $CUDA_LOCATION | grep -Eo "[0-9\.]+")
		else
			# readlink command not present
			CUDA=$(file /usr/local/cuda | grep -Eo "[0-9\.]+")
		fi
	elif [[ -d "$CUDA_LOCATION" ]]; then
		CUDA=$(echo $CUDA_LOCATION | grep -Eo "[0-9\.]+")
	else
		CUDA=""
	fi
	echo $CUDA
}

# CUDA in path
CUDA_IN_PATH=$(echo $PATH | grep -Eoi "[a-zA-Z\/\.\-\_]*cuda[a-z0-9\.\-]*")
if [ "$CUDA_IN_PATH" ]; then
	CUDA=$(CheckCudaLocation "$CUDA_IN_PATH")
	if [ ! "$CUDA" ]; then
		echo "CUDA path in PATH envvar does not exist."
		CUDA="x"
	fi
else
	# Try default location
	LOCATION="/usr/local/cuda"
	CUDA=$(CheckCudaLocation "$LOCATION")
	if [ ! "$CUDA" ]; then
		echo "CUDA not found on this system"
		CUDA="x"
	fi
fi

# Get cuDNN version
CUDNN_PKG=$(dpkg --get-selections | grep -Eo "libcudnn[0-9]\s")
if [ ! "$CUDNN_PKG" ]; then
	echo "cuDNN not installed"
else
	cuDNN=$(dpkg -s $CUDNN_PKG | grep -i "version:" | grep -Eo "[0-9\.]+-[0-9]+")
fi

return_states