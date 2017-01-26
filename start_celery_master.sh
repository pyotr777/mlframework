#!/bin/bash
# Start celery master container
echo "Starting Celery master"
docker run -ti --link rabbit-broker:rabbit -v "$(pwd)":/root --name celery-flower -p 5555:5555 pyotr777/celery-chainer bash