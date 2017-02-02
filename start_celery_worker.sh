#!/bin/bash
# Start celery master container with bash. Must be run from mlframework directory.
# To start workers use:
# export CELERY_BROKER_URL=amqp://guest@<rabbitmq server ip>
# celery -A proj worker [--loglevel=info] [-E] [--concurrency=<Number of workers>]

usage=$(cat <<USAGEBLOCK
Usage:
$0 [-b <broker address>] -d <dirname>
Options:
	-d	Local folder with task files.
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
        -d)
            proj_folder="$2";shift;
            ;;
        -b)
            broker_address="$2";shift;
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

# Clean old conatiners
./clean_celery_worker.sh 1>/dev/null

if [[ -n "$broker_address" ]]; then
	BROKER_OPT="-e CELERY_BROKER_URL=amqp://guest@$broker_address -e RABBIT_PORT=tcp://$broker_address:4369"
    #echo "Using BROKER_OPT:$BROKER_OPT"
else
    BROKER_OPT="--link rabbit"
    #echo "Starting worker with link to rabbit container."
fi

# Starting worker container with workers
cmd="docker run -d -v "$(pwd)":/root $BROKER_OPT --name celery-worker pyotr777/celery-chainer-worker celery -A $proj_folder worker --loglevel=info -E"
#echo $cmd
eval $cmd

