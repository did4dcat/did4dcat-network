export $(cat .env | xargs)

ORDERER=orderer-${DOMAIN}:${ORDERER_PORT_1}

if [ "$1" == "install" ]; then
  docker exec cli-${DOMAIN} peer lifecycle chaincode install ./chaincode/$CC_NAME.tar.gz
fi

if [ "$1" == "approve" ]; then
  docker exec cli-${DOMAIN} peer lifecycle chaincode approveformyorg -o $ORDERER --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem \
  --channelID $APP_CHANNEL --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --waitForEvent --package-id $PACKAGE_ID
fi

if [ "$1" == "commit" ]; then
  docker exec cli-${DOMAIN} peer lifecycle chaincode checkcommitreadiness --channelID $APP_CHANNEL --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE

  ARGS=()

  for (( i=0; i<${2}; i++ ))
  do
    CURRENT_DOMAIN=$(($i + 3))
    CURRENT_PEER_PORT=$(($i + 3 + ${2}))
    ARGS+=('--peerAddresses peer-'${!CURRENT_DOMAIN}':'${!CURRENT_PEER_PORT}' --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/'${!CURRENT_DOMAIN}'/peers/peer-'${!CURRENT_DOMAIN}'/tls/ca.crt')
  done

  docker exec cli-${DOMAIN} peer lifecycle chaincode commit -o $ORDERER --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/organizations/$DOMAIN/peers/orderer-$DOMAIN/msp/tlscacerts/tlsca.$DOMAIN-cert.pem ${ARGS[@]} --channelID $APP_CHANNEL --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE
fi
