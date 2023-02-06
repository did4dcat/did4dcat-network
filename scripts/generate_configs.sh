touch ./crypto-config.yaml

echo "PeerOrgs:" > ./crypto-config.yaml

for (( i=0; i<${1}; i++ ))
do
  CURRENT_NAME=$(($i + 2))
  CURRENT_DOMAIN=$(($i + 2 + ${1}))

  echo "  - Name: ${!CURRENT_NAME}" >> ./crypto-config.yaml
  echo "    Domain: ${!CURRENT_DOMAIN}" >> ./crypto-config.yaml
  echo "    EnableNodeOUs: true" >> ./crypto-config.yaml
  echo "    Specs:" >> ./crypto-config.yaml
  echo "      - Hostname: orderer" >> ./crypto-config.yaml
  echo "      - Hostname: peer" >> ./crypto-config.yaml
  echo "    Users:" >> ./crypto-config.yaml
  echo "      Count: 1" >> ./crypto-config.yaml
done

SEC_ORGS=""
SEC_ORGS=$SEC_ORGS"Organizations:\n"

SEC_ORDERER_ADDRESSES=""
SEC_ORDERER_ADDRESSES=$SEC_ORDERER_ADDRESSES"  Addresses:\n"

SEC_PROFILES_ADDRESSES=""
SEC_PROFILES_ADDRESSES=$SEC_PROFILES_ADDRESSES"      Addresses:\n"

SEC_PROFILES_ORGS_1=""
SEC_PROFILES_ORGS_1=$SEC_PROFILES_ORGS_1"      Organizations:\n"

SEC_PROFILES_ORGS_2=""
SEC_PROFILES_ORGS_2=$SEC_PROFILES_ORGS_2"        Organizations:\n"

SEC_PROFILES_CONSENTERS=""
SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"        Consenters:\n"

AFFILIATIONS=""
AFFILIATIONS=$AFFILIATIONS"affiliations:\n"

for (( i=0; i<${1}; i++ ))
do
  CURRENT_ID=$(($i + 1))
  CURRENT_NAME=$(($i + 2))
  CURRENT_DOMAIN=$(($i + 2 + ${1}))
  CURRENT_MSP=$(($i + 2 + 2*${1}))
  CURRENT_PEER_PORT=$(($i + 2 + 3*${1}))
  CURRENT_ORDERER_PORT=$(($i + 2 + 4*${1}))

  SEC_ORGS=$SEC_ORGS"\n"
  SEC_ORGS=$SEC_ORGS"  - &Org$CURRENT_ID\n" # ${!CURRENT_NAME}"
  SEC_ORGS=$SEC_ORGS"    Name: ${!CURRENT_MSP}\n"
  SEC_ORGS=$SEC_ORGS"    ID: ${!CURRENT_MSP}\n"
  SEC_ORGS=$SEC_ORGS"    MSPDir: crypto/organizations/${!CURRENT_DOMAIN}/msp\n"
  SEC_ORGS=$SEC_ORGS"    Policies: &${!CURRENT_MSP}Policies\n"
  SEC_ORGS=$SEC_ORGS"      Readers:\n"
  SEC_ORGS=$SEC_ORGS"        Type: Signature\n"
  SEC_ORGS=$SEC_ORGS"        Rule: \"OR('${!CURRENT_MSP}.member')\"\n"
  SEC_ORGS=$SEC_ORGS"      Writers:\n"
  SEC_ORGS=$SEC_ORGS"        Type: Signature\n"
  SEC_ORGS=$SEC_ORGS"        Rule: \"OR('${!CURRENT_MSP}.member')\"\n"
  SEC_ORGS=$SEC_ORGS"      Admins:\n"
  SEC_ORGS=$SEC_ORGS"        Type: Signature\n"
  SEC_ORGS=$SEC_ORGS"        Rule: \"OR('${!CURRENT_MSP}.admin')\"\n"
  SEC_ORGS=$SEC_ORGS"      Endorsement:\n"
  SEC_ORGS=$SEC_ORGS"        Type: Signature\n"
  SEC_ORGS=$SEC_ORGS"        Rule: \"OR('${!CURRENT_MSP}.peer')\"\n"
  SEC_ORGS=$SEC_ORGS"    AnchorPeers:\n"
  SEC_ORGS=$SEC_ORGS"      - Host: peer-${!CURRENT_DOMAIN}\n"
  SEC_ORGS=$SEC_ORGS"        Port: ${!CURRENT_PEER_PORT}\n"
  SEC_ORGS=$SEC_ORGS"    OrdererEndpoints:\n"
  SEC_ORGS=$SEC_ORGS"      - \"orderer-${!CURRENT_DOMAIN}:${!CURRENT_ORDERER_PORT}\"\n"

  SEC_ORDERER_ADDRESSES=$SEC_ORDERER_ADDRESSES"    - orderer-${!CURRENT_DOMAIN}:${!CURRENT_ORDERER_PORT}"
  SEC_PROFILES_ADDRESSES=$SEC_PROFILES_ADDRESSES"        - orderer-${!CURRENT_DOMAIN}:${!CURRENT_ORDERER_PORT}"
  SEC_PROFILES_ORGS_1=$SEC_PROFILES_ORGS_1"        - *Org$CURRENT_ID"
  SEC_PROFILES_ORGS_2=$SEC_PROFILES_ORGS_2"          - *Org$CURRENT_ID"

  SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"          - Host: orderer-${!CURRENT_DOMAIN}\n"
  SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"            Port: ${!CURRENT_ORDERER_PORT}\n"
  SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"            ClientTLSCert: crypto/organizations/${!CURRENT_DOMAIN}/peers/orderer-${!CURRENT_DOMAIN}/tls/server.crt\n"
  SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"            ServerTLSCert: crypto/organizations/${!CURRENT_DOMAIN}/peers/orderer-${!CURRENT_DOMAIN}/tls/server.crt"

  if (($i<$((${1}-1)))); then
    SEC_ORDERER_ADDRESSES=$SEC_ORDERER_ADDRESSES"\n"
    SEC_PROFILES_ADDRESSES=$SEC_PROFILES_ADDRESSES"\n"
    SEC_PROFILES_ORGS_1=$SEC_PROFILES_ORGS_1"\n"
    SEC_PROFILES_ORGS_2=$SEC_PROFILES_ORGS_2"\n"
    SEC_PROFILES_CONSENTERS=$SEC_PROFILES_CONSENTERS"\n"
  fi

  AFFILIATIONS=$AFFILIATIONS"  org$CURRENT_ID:\n"
  AFFILIATIONS=$AFFILIATIONS"    - department1\n"
done

echo -e "$SEC_ORGS" > temp-input.yaml
sed -e '/###section-organizations###/r temp-input.yaml' ./crypto-config/configtx-skeleton.yaml > ./configtx.yaml
sed -i -e '/###section-organizations###/d' ./configtx.yaml

rm temp-input.yaml

echo -e "$SEC_ORDERER_ADDRESSES" > temp-input.yaml
sed -i -e '/###section-orderer-addresses###/r temp-input.yaml' ./configtx.yaml
sed -i -e '/###section-orderer-addresses###/d' ./configtx.yaml

rm temp-input.yaml

echo -e "$SEC_PROFILES_ADDRESSES" > temp-input.yaml
sed -i -e '/###section-profiles-addresses###/r temp-input.yaml' ./configtx.yaml
sed -i -e '/###section-profiles-addresses###/d' ./configtx.yaml

rm temp-input.yaml

echo -e "$SEC_PROFILES_ORGS_1" > temp-input.yaml
sed -i -e '/###section-profiles-organizations-1###/r temp-input.yaml' ./configtx.yaml
sed -i -e '/###section-profiles-organizations-1###/d' ./configtx.yaml

rm temp-input.yaml

echo -e "$SEC_PROFILES_ORGS_2" > temp-input.yaml
sed -i -e '/###section-profiles-organizations-2###/r temp-input.yaml' ./configtx.yaml
sed -i -e '/###section-profiles-organizations-2###/d' ./configtx.yaml

rm temp-input.yaml

echo -e "$SEC_PROFILES_CONSENTERS" > temp-input.yaml
sed -i -e '/###section-profiles-consenters###/r temp-input.yaml' ./configtx.yaml
sed -i -e '/###section-profiles-consenters###/d' ./configtx.yaml

rm temp-input.yaml

for (( i=0; i<${1}; i++ ))
do
  CURRENT_ID=$(($i + 1))
  CURRENT_DOMAIN=$(($i + 2 + ${1}))

  mkdir -p ./crypto-config/organizations/${!CURRENT_DOMAIN}

  echo -e "$AFFILIATIONS" > temp-input.yaml
  sed -e '/###affiliations###/r temp-input.yaml' ./crypto-config/fabric-ca-server-config-skeleton.yaml \
  > ./crypto-config/organizations/${!CURRENT_DOMAIN}/fabric-ca-server-config-gen.yaml
  sed -i -e '/###affiliations###/d' ./crypto-config/organizations/${!CURRENT_DOMAIN}/fabric-ca-server-config-gen.yaml
  sed -i -e 's/###ca-domain###/'${!CURRENT_DOMAIN}'/g' ./crypto-config/organizations/${!CURRENT_DOMAIN}/fabric-ca-server-config-gen.yaml
  sed -i -e 's/###ca-name###/'$CURRENT_ID'/g' ./crypto-config/organizations/${!CURRENT_DOMAIN}/fabric-ca-server-config-gen.yaml

  rm temp-input.yaml
done
