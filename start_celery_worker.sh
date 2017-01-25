#!/bin/bash
# Start celery master container with bash. Must be run from mlframework directory.
# To start workers use:
# export CELERY_BROKER_URL=amqp://guest@<rabbitmq server ip>
# celery -A proj worker [--loglevel=info] [-E] [--concurrency=<Number of workers>]

docker run -ti -v "$(pwd)":/root --name celery-worker1 pyotr777/celery-chainer-worker bash