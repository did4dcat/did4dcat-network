export $(cat .env | xargs)

ORG_PATH=${PWD}/crypto-config/organizations/${DOMAIN}
CACERT=localhost-${CA_PORT_1}-ca-${ORG}.pem

mkdir -p "$ORG_PATH/msp"

echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/'$CACERT'
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/'$CACERT'
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/'$CACERT'
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/'$CACERT'
    OrganizationalUnitIdentifier: orderer' >"$ORG_PATH/msp/config.yaml"

mkdir -p "$ORG_PATH/msp/tlscacerts"
cp "$ORG_PATH/ca-cert.pem" "$ORG_PATH/msp/tlscacerts/tlsca.${DOMAIN}-cert.pem"

mkdir -p "$ORG_PATH/tlsca"
cp "$ORG_PATH/ca-cert.pem" "$ORG_PATH/tlsca/tlsca.${DOMAIN}-cert.pem"

mkdir -p "$ORG_PATH/ca"
cp "$ORG_PATH/ca-cert.pem" "$ORG_PATH/ca/ca.${DOMAIN}-cert.pem"

cp "$ORG_PATH/msp/config.yaml" "$ORG_PATH/peers/peer-${DOMAIN}/msp/config.yaml"

cp "$ORG_PATH/peers/peer-${DOMAIN}/tls/tlscacerts/"* "$ORG_PATH/peers/peer-${DOMAIN}/tls/ca.crt"
cp "$ORG_PATH/peers/peer-${DOMAIN}/tls/signcerts/"* "$ORG_PATH/peers/peer-${DOMAIN}/tls/server.crt"
cp "$ORG_PATH/peers/peer-${DOMAIN}/tls/keystore/"* "$ORG_PATH/peers/peer-${DOMAIN}/tls/server.key"

mkdir -p "$ORG_PATH/peers/orderer-${DOMAIN}/tls"
cp "$ORG_PATH/peers/orderer-${DOMAIN}/tls/tlscacerts/"* "$ORG_PATH/peers/orderer-${DOMAIN}/tls/ca.crt"
cp "$ORG_PATH/peers/orderer-${DOMAIN}/tls/signcerts/"* "$ORG_PATH/peers/orderer-${DOMAIN}/tls/server.crt"
cp "$ORG_PATH/peers/orderer-${DOMAIN}/tls/keystore/"* "$ORG_PATH/peers/orderer-${DOMAIN}/tls/server.key"

mkdir -p "${PWD}/crypto-config/organizations/${DOMAIN}/peers/orderer-${DOMAIN}/msp/tlscacerts"
cp "$ORG_PATH/peers/orderer-${DOMAIN}/tls/tlscacerts/"* "$ORG_PATH/peers/orderer-${DOMAIN}/msp/tlscacerts/tlsca.${DOMAIN}-cert.pem"

cp "$ORG_PATH/msp/config.yaml" "$ORG_PATH/peers/orderer-${DOMAIN}/msp/config.yaml"
cp "$ORG_PATH/msp/config.yaml" "$ORG_PATH/users/Admin@${DOMAIN}/msp/config.yaml"
