IMAGE="pyotr777/chainer-jupyter"
CONTNAME="chainer-jupyter"
cont=$(docker ps -a | grep $CONTNAME)
if [ -n "$cont" ]; then
	docker rm $CONTNAME
fi
docker run -d -v $(pwd):/root/ -p 8888:8888 --name $CONTNAME $IMAGE
sleep 2
open "http://localhost:8888"
