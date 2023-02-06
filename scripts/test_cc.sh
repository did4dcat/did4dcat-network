export $(cat .env | xargs)

ORDERER=orderer-${DOMAIN}:${ORDERER_PORT_1}

DID=${1}
URI=${2}

ARGS=()

for (( i=0; i<${3}; i++ ))
do
  CURRENT_DOMAIN=$(($i + 4))
  CURRENT_PEER_PORT=$(($i + 4 + ${3}))
  ARGS+=('--peerAddresses peer-'${!CURRENT_DOMAIN}':'${!CURRENT_PEER_PORT}' --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/'${!CURRENT_DOMAIN}'/peers/peer-'${!CURRENT_DOMAIN}'/tls/ca.crt')
done

docker exec cli-${DOMAIN} peer chaincode invoke -o $ORDERER --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem -C $APP_CHANNEL -n $CC_NAME ${ARGS[@]} -c '{"function":"InitLedger","Args":[]}'
sleep 15
docker exec cli-${DOMAIN} peer chaincode invoke -o $ORDERER --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem -C $APP_CHANNEL -n $CC_NAME ${ARGS[@]} -c '{"function":"CreateDataset","Args":["'$DID'", "'$URI'"]}'
sleep 15
docker exec cli-${DOMAIN} peer chaincode query -C $APP_CHANNEL -n $CC_NAME -c '{"function":"ReadDataset","Args":["'$DID'"]}'
docker exec cli-${DOMAIN} peer chaincode query -C $APP_CHANNEL -n $CC_NAME -c '{"function":"GetAllDatasets","Args":[]}'
