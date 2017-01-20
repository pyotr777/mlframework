#!/bin/bash
# Start RabbitMQ broker in container,
# Start N Celery worker containers and one Master container.
# Install Flower in master with pip install flower. Start it with celery -A proj flower.
# N read from argument. Deafult is 1.

rabbit_name="rabbit-broker"
cont=$(docker ps -a | grep $rabbit_name)
if [ -z "$cont" ]; then
	docker run -d --hostname my-rabbit --name $rabbit_name rabbitmq:3
	sleep 2
fi

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

N=1
if [ $# -gt 0 ]; then
	N=$1
fi

echo "Starting $N Celery workers"
for i in $(seq 1 $N); do
	docker run -d --link $rabbit_name:rabbit -v "$(pwd)":/root --name celery-worker$i pyotr777/celery-chainer celery -A proj worker --loglevel=info
done

cont_name="celery-flower"
cont=$(docker ps -a | grep $cont_name)
if [ -n "$cont" ]; then
	docker kill $cont_name
	docker rm $cont_name
fi

echo "Starting Celery master"
docker run -ti --link $rabbit_name:rabbit -v "$(pwd)":/root --name $cont_name -p 5555:5555 pyotr777/celery-chainer bash
