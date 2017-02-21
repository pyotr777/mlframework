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

# Variables initialisation
. init.sh

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

USE_NVIDIA=""
# Check if nvidia-docker installed
nvdocker=$(nvidia-docker version 2>/dev/null)
if [[ -n "$nvdocker" ]]; then
    # Check if GPU is available
    gpu=$(nvidia-docker run --rm nvidia/cuda nvidia-smi -L 2>/dev/null)
    if [[ -n "$gpu" ]]; then
        echo "GPU available on $(hostname)"
        USE_NVIDIA="yes"
    fi
fi


# Starting worker container with workers
if [[ -n "$USE_NVIDIA" ]]; then
    cmd="nvidia-docker run -d -v "$(pwd)":/root $BROKER_OPT --name $worker_cont_name $worker_image_cuda celery -A $proj_folder worker --loglevel=info -E --concurrency=$concurrency -n worker@%h"
else
    cmd="docker run -d -v "$(pwd)":/root $BROKER_OPT --name $worker_cont_name $worker_image celery -A $proj_folder worker --loglevel=info -E --concurrency=$concurrency -n worker@%h"
fi
if [[ -n "$debug" ]]; then
    echo $cmd
fi
eval $cmd

