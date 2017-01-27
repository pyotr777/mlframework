echo "Starting workers at pwr321. BROKER_ADDRESS=172.19.40.35; PROJ_FOLDER=proj"
cd ML/mlframework
hostname
pwd && ls -l
./start_celery_worker.sh -b 172.19.40.35 -l proj
docker ps -a

rm remote_command.sh