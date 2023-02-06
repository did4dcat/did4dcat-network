export $(cat .env | xargs)

if [ "$1" == "up" ]; then
  docker-compose -f ./compose/host.yaml up -d
fi

if [ "$1" == "up-cli" ]; then
  docker-compose -f ./compose/host.yaml up -d cli
fi

if [ "$1" == "up-ca" ]; then
  docker-compose -f ./compose/host.yaml up -d ca
fi

if [ "$1" == "stop" ]; then
  docker-compose -f ./compose/host.yaml stop
fi

if [ "$1" == "down" ]; then
  docker-compose -f ./compose/host.yaml down
fi

if [ "$1" == "remove" ]; then
  docker-compose -f ./compose/host.yaml down -v
  docker rm $(docker ps -aq)
  docker rmi $(docker images dev-* -q)
fi
