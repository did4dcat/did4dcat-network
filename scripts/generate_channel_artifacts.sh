export $(cat .env | xargs)

if [ "$1" == "genesis" ]; then
  docker exec cli-${DOMAIN} configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./channel-artifacts/genesis.block -channelID $SYS_CHANNEL -configPath .
  docker cp cli-${DOMAIN}:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/genesis.block ./channel-artifacts/genesis.block

  docker exec cli-${DOMAIN} configtxgen -profile FourOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $APP_CHANNEL -configPath .
  docker cp cli-${DOMAIN}:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx ./channel-artifacts/channel.tx
fi

if [ "$1" == "anchor" ]; then
  docker exec cli-${DOMAIN} configtxgen -profile FourOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${MSP}anchors.tx -channelID $APP_CHANNEL -asOrg $MSP -configPath .
fi
