export $(cat .env | xargs)

if [ "$1" == "peers" ]; then
  cd ${PWD}/crypto-config/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/
  export USER_KEY=$(ls)
  docker exec cli-${DOMAIN} discover --peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/tls/ca.crt \
  --userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/$USER_KEY \
  --userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/signcerts/cert.pem --MSP $MSP peers --channel $APP_CHANNEL --server peer-$DOMAIN:$PEER_PORT_1
fi

if [ "$1" == "config" ]; then
  cd ${PWD}/crypto-config/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/
  export USER_KEY=$(ls)
  docker exec cli-${DOMAIN} discover --configFile conf.yaml --peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/tls/ca.crt \
  --userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/$USER_KEY \
  --userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/signcerts/cert.pem --MSP $MSP saveConfig
  docker exec cli-${DOMAIN} discover --configFile conf.yaml config --channel $APP_CHANNEL --server peer-${DOMAIN}:${PEER_PORT_1}
fi

if [ "$1" == "endorsers" ]; then
  cd ${PWD}/crypto-config/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/
  export USER_KEY=$(ls)
  docker exec cli-${DOMAIN} discover --configFile conf.yaml --peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/tls/ca.crt \
  --userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/keystore/$USER_KEY \
  --userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/peer-$DOMAIN/msp/signcerts/cert.pem --MSP $MSP saveConfig
  docker exec cli-${DOMAIN} discover --configFile conf.yaml endorsers --channel $APP_CHANNEL --server peer-${DOMAIN}:${PEER_PORT_1} --chaincode did4dcat
fi
