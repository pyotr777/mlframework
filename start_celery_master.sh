#!/bin/bash

celery_cont_name="celery-flower"
rabbit_cont_name="rabbit"

./clean_celery_master.sh 1>/dev/null


# Start RabbitMq and Celery master containers
#echo "Starting Rabbit"
docker run -d -p 25672:25672 -p 4369:4369 -p 5672:5672 --name $rabbit_cont_name rabbitmq:3
#echo "Starting Celery master with Flower"
docker run -d --link $rabbit_cont_name:rabbit -v "$(pwd)":/root --name $celery_cont_name -p 5555:5555 pyotr777/celery-chainer-flower
#sleep 3
#open http://localhost:5555