export $(cat .env | xargs)

docker exec ca-$DOMAIN fabric-ca-client enroll -u https://admin:adminpw@localhost:$CA_PORT_1 --caname ca-$ORG --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem

docker exec ca-$DOMAIN fabric-ca-client register --caname ca-$ORG --id.name peer --id.secret peerpw --id.type peer --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
docker exec ca-$DOMAIN fabric-ca-client enroll -u https://peer:peerpw@localhost:$CA_PORT_1 --caname ca-$ORG -M /etc/hyperledger/fabric-ca-server/peers/peer-$DOMAIN/msp --csr.hosts peer-$DOMAIN --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
docker exec ca-$DOMAIN fabric-ca-client enroll -u https://peer:peerpw@localhost:$CA_PORT_1 --caname ca-$ORG -M /etc/hyperledger/fabric-ca-server/peers/peer-$DOMAIN/tls --enrollment.profile tls --csr.hosts peer-$DOMAIN --csr.hosts $DOMAIN --csr.hosts localhost --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem

docker exec ca-$DOMAIN fabric-ca-client register --caname ca-$ORG --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
docker exec ca-$DOMAIN fabric-ca-client enroll -u https://orderer:ordererpw@localhost:$CA_PORT_1 --caname ca-$ORG -M /etc/hyperledger/fabric-ca-server/peers/orderer-$DOMAIN/msp --csr.hosts orderer-$DOMAIN --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
docker exec ca-$DOMAIN fabric-ca-client enroll -u https://orderer:ordererpw@localhost:$CA_PORT_1 --caname ca-$ORG -M /etc/hyperledger/fabric-ca-server/peers/orderer-$DOMAIN/tls --enrollment.profile tls --csr.hosts orderer-$DOMAIN --csr.hosts $DOMAIN --csr.hosts localhost --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem

docker exec ca-$DOMAIN fabric-ca-client register --caname ca-$ORG --id.name $ORG-admin --id.secret $ORG-adminpw --id.type admin --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
docker exec ca-$DOMAIN fabric-ca-client enroll -u https://$ORG-admin:$ORG-adminpw@localhost:$CA_PORT_1 --caname ca-$ORG -M /etc/hyperledger/fabric-ca-server/users/Admin@$DOMAIN/msp --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
