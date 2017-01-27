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

echo "Remove celery-flower and rabbit containers"

# Remove Celery master container
RemoveContainer "celery-flower"

# Remove RabbitMQ  container
RemoveContainer "rabbit"