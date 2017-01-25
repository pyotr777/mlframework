#!/bin/bash
# Start RabbitMQ broker in container,
# Start Celery master container,
# Optionally start worker containers.
# Install Flower in master with pip install flower. Start it with celery -A proj flower.
# N read from argument. Deafult is 0.

# Start RabbitMQ container with open ports. To connect need only host IP address. E.g.:
# export CELERY_BROKER_URL=amqp://guest@172.19.5.5

# For containers (master and worker) started locally with this script
# Docker link is used and no environment setup is necessary.

rabbit_name="rabbit"
cont=$(docker ps -a | grep $rabbit_name)
if [ -z "$cont" ]; then
	docker run -d -p 25672:25672 -p 4369:4369 -p 5672:5672 --name rabbit rabbitmq:3
	sleep 2
fi

N=0
# Optionally start workers
if [ $# -gt 0 ]; then
	N=$1
	cont_name="celery-worker"
	IFS=$'\n'; arr=( $(docker ps -a | grep $cont_name | awk '{ print $1 }') )
	if [ ${#arr[@]} -gt 0 ]; then
		echo "Cleaning worker containers"
	fi
	for cont in "${arr[@]}"; do
		if [ -n "$cont" ]; then
			docker kill "$cont"
			docker rm "$cont"
		fi
	done
	echo "Starting $N Celery workers"
	for i in $(seq 1 $N); do
		docker run -d --link $rabbit_name:rabbit -v "$(pwd)":/root --name celery-worker$i pyotr777/celery-chainer-worker celery -A proj worker --loglevel=info -E
	done
fi


# Remove old celery master
cont_name="celery-flower"
cont=$(docker ps -a | grep $cont_name)
if [ -n "$cont" ]; then
	docker kill $cont_name
	docker rm $cont_name
fi

# Start Celery master with flower port open
echo "Starting Celery master"
docker run -ti --link $rabbit_name:rabbit -v "$(pwd)":/root --name $cont_name -p 5555:5555 pyotr777/celery-chainer bash

