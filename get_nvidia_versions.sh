#!/bin/bash

# Test installed NVIDIA drivers, CUDA and cuDNN versions on Ubuntu

# Get NVIDIA driver version
version_file="/proc/driver/nvidia/version"
NV_DRV="x"
CUDA="x"
cuDNN="x"

function return_states {
	echo "NVDRV:$NV_DRV,CUDA:$CUDA,cuDNN:$cuDNN"
	exit 0
}

if [ ! -f "$version_file" ]; then
	echo "Driver not found"
	return_states
fi

NV_DRV=$(grep -Eo "Kernel Module\s+([0-9\.]+)" /proc/driver/nvidia/version | awk '{ print $3 }')
#echo $NV_DRV
return_states