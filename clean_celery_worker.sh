#!/bin/bash

RemoveContainer() {
	cont_name=$1
	cont=$(docker ps | grep $cont_name)
	if [ -n "$cont" ]; then
	    docker kill $cont_name &>/dev/null
	fi
	cont=$(docker ps -a | grep $cont_name)
	if [ -n "$cont" ]; then
	    docker rm $cont_name &>/dev/null
	fi
}

# Removing existing worker containers
cont_name="celery-worker"
IFS=$'\n'; arr=( $(docker ps -a | grep $cont_name | awk '{ print $1 }') )
if [ ${#arr[@]} -gt 0 ]; then
    echo "Cleaning worker containers"
fi
for cont in "${arr[@]}"; do
    if [ -n "$cont" ]; then
        RemoveContainer "$cont"
    fi
done