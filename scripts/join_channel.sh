export $(cat .env | xargs)

ORDERER=orderer-${DOMAIN}:${ORDERER_PORT_1}
TX=${MSP}anchors.tx

if [ "$1" == "create" ]; then
  docker exec cli-${DOMAIN} peer channel create -o $ORDERER -c $APP_CHANNEL -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem
  docker cp cli-${DOMAIN}:/opt/gopath/src/github.com/hyperledger/fabric/peer/$APP_CHANNEL.block $APP_CHANNEL.block
fi

if [ "$1" == "join" ]; then
  docker cp $APP_CHANNEL.block cli-${DOMAIN}:/opt/gopath/src/github.com/hyperledger/fabric/peer/$APP_CHANNEL.block
  docker exec cli-${DOMAIN} peer channel join -b $APP_CHANNEL.block
fi

if [ "$1" == "update" ]; then
  docker exec cli-${DOMAIN} peer channel update -o $ORDERER -c $APP_CHANNEL -f ./channel-artifacts/$TX --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem
fi
