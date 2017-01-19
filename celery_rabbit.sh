#!/bin/bash

cont=$(docker ps -a | grep "some-rabbit")
if [ -z "$cont" ]; then
	docker run -d --hostname my-rabbit --name some-rabbit rabbitmq:3
	sleep 2
fi

cont=$(docker ps -a | grep "some-celery")
echo $cont
if [ -n "$cont" ]; then
	docker kill some-celery
	docker rm some-celery
fi
echo "Starting some-celery"
docker run -d --link some-rabbit:rabbit -v "$(pwd)":/root --name celery-chainer pyotr777/celery-chainer
sleep 2
docker run --link some-rabbit:rabbit --rm pyotr777/celery-chainer celery status
