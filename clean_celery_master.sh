#!/bin/bash


# Remove old celery master
cont_name="celery-flower"
cont=$(docker ps -a | grep $cont_name)
if [ -n "$cont" ]; then
    docker kill $cont_name 2>/dev/null
    docker rm $cont_name
fi