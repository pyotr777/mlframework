#!/bin/bash
# Start celery master container with bash. Must be run from mlframework directory.
# To start workers use:
# export CELERY_BROKER_URL=amqp://guest@<rabbitmq server ip>
# celery -A proj worker [--loglevel=info] [-E] [--concurrency=<Number of workers>]

usage=$(cat <<USAGEBLOCK
Usage:
$0 [-b <broker address>] -l <dirname>
Options:
	-l	Local folder with task files.
	-b	External address of the machine with Master and Broker containers.
USAGEBLOCK
)

if [[ $# < 1 ]]; then
	echo "$usage"
	echo "Need task (project) folder name."
	exit 0;
fi

#docker run -ti -v "$(pwd)":/root --name celery-worker1 pyotr777/celery-chainer-worker bash

while test $# -gt 0; do
    case "$1" in
        -h | --help)
            echo $usage
            exit 0
            ;;
        -l)
            PROJ_FOLDER="$2";shift;
            ;;
        -b)
            BROKER_ADDRESS="$2";shift;
            ;;
        --)
            shift
            break;;
        -*)
            echo "Invalid option: $1"
            echo "$usage"
            exit 1;;
    esac
    shift
done

# Removing existing containers
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


if [[ -n "$BROKER_ADDRESS" ]]; then
	BROKER_OPT="-e CELERY_BROKER_URL=$BROKER_ADDRESS"
fi

# Starting worker container with workers
docker run -d -v "$(pwd)":/root $BROKER_OPT --name celery-worker pyotr777/celery-chainer-worker celery -A $PROJ_FOLDER worker --loglevel=info -E