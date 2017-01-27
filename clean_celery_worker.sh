#!/bin/bash

# Removing existing worker containers
cont_name="celery-worker"
IFS=$'\n'; arr=( $(docker ps -a | grep $cont_name | awk '{ print $1 }') )
if [ ${#arr[@]} -gt 0 ]; then
    echo "Cleaning worker containers"
fi
for cont in "${arr[@]}"; do
    if [ -n "$cont" ]; then
        docker kill "$cont" 2>/dev/null
        docker rm "$cont"
    fi
done