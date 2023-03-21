#!/bin/bash

########################################################################################################################
### ENVIRONMENT ########################################################################################################
########################################################################################################################

export $(cat .credentials-env | xargs)

GROUP=did4dcat
WORKDIR=/home/did4dcat
FOLDER=did4dcat-network

FABRIC_VERSION=2.4.7
FABRIC_CA_VERSION=1.5

SYS_CHANNEL=did4dcat-sys-channel
APP_CHANNEL=did4dcat

PACKAGE_ID=did4dcat_1.0.0:76236e47ab20f2a0437ed32de8bad591c4f927c770a48f625798d7cb35edf24f
CC_NAME=did4dcat
CC_VERSION=1.0.0
CC_SEQUENCE=1

ORG_IDS=(0 1 2 3 4)
ORG_NAMES=(org1 org2 org3 org4 org5)
ORG_MSPS=(Org1MSP Org2MSP Org3MSP Org4MSP Org5MSP)
ORG_DOMAINS=(did4dcat.example-org1.org did4dcat.example-org2.org did4dcat.example-org3.org did4dcat.example-org4.org did4dcat.example-org5.org)
ORG_ORDERER_PORTS_1=(7050 8050 9050 10050 11050)
ORG_PEER_PORTS_1=(7051 8051 9051 10051 11051)
ORG_PEER_PORTS_2=(7052 8052 9052 10052 11052)
ORG_CA_PORTS_1=(7054 8054 9054 10054 11054)
ORG_CA_PORTS_2=(17054 18054 19054 20054 21054)

GIT_REPOSITORY=https://github.com/did4dcat/did4dcat-network.git

GREEN='\033[0;32m'
NC='\033[0m'

########################################################################################################################
### HELP ###############################################################################################################
########################################################################################################################

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  printf "${GREEN}[DEPLOY] Help ${NC}\n"

  printf "./deploy.sh generate-configs \t\t\t: Generate config files\n"
  printf "./deploy.sh quick-start [\$ORG_NAME]\t\t: Do all necessary steps\n"
  printf "./deploy.sh quick-remove \t\t\t: Stop all and remove all\n"
  printf "./deploy.sh get-certs-for-app [\$ORG_NAME]\t: Get necessary certs for app\n"
  printf "./deploy.sh init-docker-swarm [\$ORG_NAME]\t: Initialize docker swarm environment\n"
  printf "./deploy.sh remove-docker-swarm \t\t: Remove docker swarm environment\n"
  printf "./deploy.sh open-ports \t\t\t\t: Open necessary ports\n"
  printf "./deploy.sh close-ports \t\t\t: Close necessary ports\n"
  printf "./deploy.sh up-containers \t\t\t: Bring up containers\n"
  printf "./deploy.sh down-containers \t\t\t: Bring down containers (Removes all containers and all images with dev-*)\n"
  printf "./deploy.sh stop-containers \t\t\t: Stop containers\n"
  printf "./deploy.sh remove-containers \t\t\t: Remove containers\n"
  printf "./deploy.sh init-environment \t\t\t: Initialize environment on machines\n"
  printf "./deploy.sh init-crypto \t\t\t: Generate crypto material and exchange between orgs\n"
  printf "./deploy.sh init-channel-artifacts [\$ORG_NAME] \t: Generate channel artifacts and exchange between orgs\n"
  printf "./deploy.sh init-channel [\$ORG_NAME] \t\t: Create channel on-chain with orgx and join all orgs\n"
  printf "./deploy.sh deploy-cc [\$ORG_NAME] \t\t: Install+approve chaincode for all orgs and commit with orgx\n"
  printf "./deploy.sh test-cc [\$ORG_NAME] \t\t: Test chaincode functionality with orgx\n"
  printf "./deploy.sh discover peers [\$ORG_NAME] \t\t: Discover the network with orgx\n"
  exit 0
fi

########################################################################################################################
### HELPER #############################################################################################################
########################################################################################################################

ExchangeCrypto() {
  for i in "${ORG_IDS[@]}"; do
    if [ "$1" == "${ORG_NAMES[$i]}" ]; then
      scp $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/crypto-config/organizations/$2/$3 $1-$3
    fi
  done
  for i in "${ORG_IDS[@]}"; do
    if [ "$1" != "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && mkdir -p ./crypto-config/organizations/'$2
      scp $1-$3 $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/crypto-config/organizations/$2/$3
    fi
  done

  rm $1-$3
}

########################################################################################################################
### QUICK START ########################################################################################################
########################################################################################################################

if [ "$1" == "quick-start" ]; then
  ./deploy.sh init-folder &&
  ./deploy.sh open-ports && \
  ./deploy.sh init-docker-swarm $2 && \
  ./deploy.sh clone-repository && \
  ./deploy.sh init-environment && \
  ./deploy.sh down-containers && \
  ./deploy.sh clean-repository && \
  ./deploy.sh pull-repository && \
  ./deploy.sh generate-configs && \
  ./deploy.sh init-crypto && \
  ./deploy.sh init-channel-artifacts $2 && \
  ./deploy.sh up-containers && sleep 10 && \
  ./deploy.sh init-channel $2 && \
  ./deploy.sh deploy-cc $2 && \
  ./deploy.sh get-certs-for-app $2
fi

########################################################################################################################
### QUICK REMOVE #######################################################################################################
########################################################################################################################

if [ "$1" == "init-folder" ]; then
  printf "${GREEN}[DEPLOY] Init folder ${NC}\n"
  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo groupadd '$GROUP' || true' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo gpasswd -a '$SSH_USER' '$GROUP && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo mkdir -p '$WORKDIR && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo chown -R :'$GROUP' '$WORKDIR && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo chmod -R g+rwx '$WORKDIR &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished initialising folder ${NC}\n"
fi

########################################################################################################################
### QUICK REMOVE #######################################################################################################
########################################################################################################################

if [ "$1" == "quick-remove" ]; then
  ./deploy.sh remove-containers && \
  ./deploy.sh remove-repository && \
  ./deploy.sh remove-docker-swarm && \
  ./deploy.sh close-ports
fi

########################################################################################################################
### GENERATE CONFIGS ###################################################################################################
########################################################################################################################

if [ "$1" == "generate-configs" ]; then
  printf "${GREEN}[DEPLOY] Generate configs ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/generate_configs.sh '${#ORG_IDS[@]} \
    "${ORG_NAMES[@]}" "${ORG_DOMAINS[@]}" "${ORG_MSPS[@]}" "${ORG_PEER_PORTS_1[@]}" "${ORG_ORDERER_PORTS_1[@]}"
  done

  printf "${GREEN}[DEPLOY] Finished with generating configs ${NC}\n"
fi

########################################################################################################################
### INIT DOCKER SWARM ##################################################################################################
########################################################################################################################

if [ "$1" == "init-docker-swarm" ]; then
  printf "${GREEN}[DEPLOY] init-docker-swarm ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      printf "${GREEN}[DEPLOY] Create docker swarm on ${ORG_NAMES[$i]} ${NC}\n"

      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'docker swarm init --advertise-addr $(dig +short ' \
      ${ORG_DOMAINS[$i]}' | tail -n1)'
      JOIN=$(ssh $SSH_USER@${ORG_DOMAINS[$i]} \
      'docker swarm join-token manager | grep --line-buffered "docker swarm join --token" | xargs')
    fi
  done

  printf "${GREEN}[DEPLOY] Join docker swarm ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" != "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} $JOIN' --advertise-addr $(dig +short '${ORG_DOMAINS[$i]}' | tail -n1)'
    fi
  done

  printf "${GREEN}[DEPLOY] Create overlay network ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'docker network create --attachable --driver overlay '$APP_CHANNEL
    fi
  done

  printf "${GREEN}[DEPLOY] Disable generic ip checksum ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo ethtool -K ens160 tx-checksum-ip-generic off' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished init-docker-swarm ${NC}\n"
fi

########################################################################################################################
### REMOVE DOCKER SWARM ################################################################################################
########################################################################################################################

if [ "$1" == "remove-docker-swarm" ]; then
  printf "${GREEN}[DEPLOY] remove-docker-swarm ${NC}\n"

  printf "${GREEN}[DEPLOY] Leave swarm ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'docker swarm leave -f' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Prune docker networks ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'docker network prune -f' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished remove-docker-swarm ${NC}\n"
fi

########################################################################################################################
### GET CERTS FOR APP ##################################################################################################
########################################################################################################################

if [ "$1" == "get-certs-for-app" ]; then
  printf "${GREEN}[DEPLOY] Start get-certs-for-app ${NC}\n"
  printf "${GREEN}[DEPLOY] PEER CERT ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      CERT=$WORKDIR'/'$FOLDER
      CERT=$CERT'/crypto-config/organizations/'${ORG_DOMAINS[$i]}'/peers/peer-'${ORG_DOMAINS[$i]}'/tls/server.crt'
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cat '$CERT
    fi
  done

  printf "${GREEN}[DEPLOY] CA CERT ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      CERT=$WORKDIR'/'$FOLDER
      CERT=$CERT'/crypto-config/organizations/'${ORG_DOMAINS[$i]}'/ca-cert.pem'
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cat '$CERT
    fi
  done

  printf "${GREEN}[DEPLOY] Finished get-certs-for-app ${NC}\n"
fi

########################################################################################################################
### CLONE REPOSITORY ###################################################################################################
########################################################################################################################

if [ "$1" == "clone-repository" ]; then
  printf "${GREEN}[DEPLOY] Clone repository ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR' && git clone '$GIT_REPOSITORY \ &&
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo chown -R :'$GROUP' '$WORKDIR'/'$FOLDER \ &&
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'sudo chmod -R g+rwx '$WORKDIR'/'$FOLDER &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with cloning ${NC}\n"
fi

########################################################################################################################
### REMOVE REPOSITORY ##################################################################################################
########################################################################################################################

if [ "$1" == "remove-repository" ]; then
  printf "${GREEN}[DEPLOY] Remove repository ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR' && sudo rm -rf ./'$FOLDER &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with removing ${NC}\n"
fi

########################################################################################################################
### CLEAN REPOSITORY ###################################################################################################
########################################################################################################################

if [ "$1" == "clean-repository" ]; then
  printf "${GREEN}[DEPLOY] Clean repository ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && git clean -d -f' &
  done

  wait $(jobs -p)

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && git stash' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with cleaning ${NC}\n"
fi

########################################################################################################################
### PULL REPOSITORY ####################################################################################################
########################################################################################################################

if [ "$1" == "pull-repository" ]; then
  printf "${GREEN}[DEPLOY] Pull repository ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && git pull' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with pulling ${NC}\n"
fi

########################################################################################################################
### UP CONTAINERS ######################################################################################################
########################################################################################################################

if [ "$1" == "up-containers" ]; then
  printf "${GREEN}[DEPLOY] Bring up containers ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh up' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with bringing up containers ${NC}\n"
fi

########################################################################################################################
### DOWN CONTAINERS ####################################################################################################
########################################################################################################################

if [ "$1" == "down-containers" ]; then
  printf "${GREEN}[DEPLOY] Bring down containers ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh down' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with bringing down containers ${NC}\n"
fi

########################################################################################################################
### REMOVE CONTAINERS ##################################################################################################
########################################################################################################################

if [ "$1" == "remove-containers" ]; then
  printf "${GREEN}[DEPLOY] Remove containers ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh remove' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with removing containers ${NC}\n"
fi

########################################################################################################################
### STOP CONTAINERS ####################################################################################################
########################################################################################################################

if [ "$1" == "stop-containers" ]; then
  printf "${GREEN}[DEPLOY] Stop containers ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh stop' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with stopping containers ${NC}\n"
fi

########################################################################################################################
### OPEN PORTS #########################################################################################################
########################################################################################################################
### docker swarm ports: 2377/tcp, 7946, 4789/udp ###
####################################################

if [ "$1" == "open-ports" ]; then
  printf "${GREEN}[DEPLOY] Open ports ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} \
    'sudo ufw allow '${ORG_ORDERER_PORTS_1[$i]}' && ' \
    'sudo ufw allow '${ORG_PEER_PORTS_1[$i]}' && ' \
    'sudo ufw allow '${ORG_PEER_PORTS_2[$i]}' && ' \
    'sudo ufw allow '${ORG_CA_PORTS_1[$i]}' && ' \
    'sudo ufw allow '${ORG_CA_PORTS_2[$i]}' && ' \
    'sudo ufw allow 2377/tcp && ' \
    'sudo ufw allow 7946 && ' \
    'sudo ufw allow 4789/udp' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with opening ports ${NC}\n"
fi

########################################################################################################################
### CLOSE PORTS ########################################################################################################
########################################################################################################################

if [ "$1" == "close-ports" ]; then
  printf "${GREEN}[DEPLOY] Close ports ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} \
    'sudo ufw delete allow '${ORG_ORDERER_PORTS_1[$i]}' && ' \
    'sudo ufw delete allow '${ORG_PEER_PORTS_1[$i]}' && ' \
    'sudo ufw delete allow '${ORG_PEER_PORTS_2[$i]}' && ' \
    'sudo ufw delete allow '${ORG_CA_PORTS_1[$i]}' && ' \
    'sudo ufw delete allow '${ORG_CA_PORTS_2[$i]}' && ' \
    'sudo ufw delete allow 2377/tcp && ' \
    'sudo ufw delete allow 7946 && ' \
    'sudo ufw delete allow 4789/udp' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished with closing ports ${NC}\n"
fi

########################################################################################################################
### INIT ENVIRONMENT ###################################################################################################
########################################################################################################################

if [ "$1" == "init-environment" ]; then
  printf "${GREEN}[DEPLOY] Start init-environment\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo FABRIC_VERSION='$FABRIC_VERSION' > .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo FABRIC_CA_VERSION='$FABRIC_CA_VERSION' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo SYS_CHANNEL='$SYS_CHANNEL' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo APP_CHANNEL='$APP_CHANNEL' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo CC_NAME='$CC_NAME' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo CC_VERSION='$CC_VERSION' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo CC_SEQUENCE='$CC_SEQUENCE' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo PACKAGE_ID='$PACKAGE_ID' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo DOMAIN='${ORG_DOMAINS[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo ORG='${ORG_NAMES[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo MSP='${ORG_MSPS[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo ORDERER_PORT_1='${ORG_ORDERER_PORTS_1[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo PEER_PORT_1='${ORG_PEER_PORTS_1[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo PEER_PORT_2='${ORG_PEER_PORTS_2[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo CA_PORT_1='${ORG_CA_PORTS_1[$i]}' >> .env' && \
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && echo CA_PORT_2='${ORG_CA_PORTS_2[$i]}' >> .env' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Finished init-environment ${NC}\n"
fi

########################################################################################################################
### INIT CRYPTO ########################################################################################################
########################################################################################################################

if [ "$1" == "init-crypto" ]; then
  printf "${GREEN}[DEPLOY] Start init-crypto ${NC}\n"

  printf "${GREEN}[DEPLOY] Bring up ca container ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh up-ca' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Enroll entities ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/enroll.sh' &
  done

  wait $(jobs -p)

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && sudo chown -R :'$GROUP' ./crypto-config' &
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && sudo chmod -R g+rwx ./crypto-config' &
  done

  wait $(jobs -p)

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/prepare_crypto.sh' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Exchange crypto material between orgs ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/msp/cacerts \
    localhost-${ORG_CA_PORTS_1[$i]}-ca-${ORG_NAMES[$i]}.pem
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/msp config.yaml
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/msp/tlscacerts tlsca.${ORG_DOMAINS[$i]}-cert.pem
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/ca ca.${ORG_DOMAINS[$i]}-cert.pem
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/tlsca tlsca.${ORG_DOMAINS[$i]}-cert.pem
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/peers/peer-${ORG_DOMAINS[$i]}/tls ca.crt
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/peers/orderer-${ORG_DOMAINS[$i]}/tls server.crt
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/peers/orderer-${ORG_DOMAINS[$i]}/msp/cacerts \
    localhost-${ORG_CA_PORTS_1[$i]}-ca-${ORG_NAMES[$i]}.pem
  done

  for i in "${ORG_IDS[@]}"; do
    ExchangeCrypto ${ORG_NAMES[$i]} ${ORG_DOMAINS[$i]}/peers/orderer-${ORG_DOMAINS[$i]}/msp/tlscacerts \
    tlsca.${ORG_DOMAINS[$i]}-cert.pem
  done

  printf "${GREEN}[DEPLOY] Finished init-crypto ${NC}\n"
fi

########################################################################################################################
### INIT CHANNEL ARTIFACTS #############################################################################################
########################################################################################################################

if [ "$1" == "init-channel-artifacts" ]; then
  printf "${GREEN}[DEPLOY] Start init-channel-artifacts ${NC}\n"

  printf "${GREEN}[DEPLOY] Bring up cli container ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/host.sh up-cli' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Change file permissions of channel artifacts ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && sudo chown -R :'$GROUP' ./channel-artifacts' &
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && sudo chmod -R g+rwx ./channel-artifacts' &
  done

  wait $(jobs -p)

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      printf "${GREEN}[DEPLOY] Generate genesis.block and channel.tx${NC}\n"
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/generate_channel_artifacts.sh genesis'

      printf "${GREEN}[DEPLOY] Zip channel artifacts${NC}\n"
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && zip -q -r channel-artifacts.zip ./channel-artifacts'

      printf "${GREEN}[DEPLOY] Get channel artifacts from host${NC}\n"
      scp $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/channel-artifacts.zip channel-artifacts.zip
    fi
  done

  printf "${GREEN}[DEPLOY] Copy channel artifacts to other orgs${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" != "${ORG_NAMES[$i]}" ]; then
      scp channel-artifacts.zip $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/channel-artifacts.zip &
    fi
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Unzip channel artifacts on other orgs ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" != "${ORG_NAMES[$i]}" ]; then
      scp channel-artifacts.zip $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/channel-artifacts.zip &
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && unzip -q channel-artifacts.zip' &
    fi
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep for 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Generate anchor files ${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/generate_channel_artifacts.sh anchor' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Remove channel artifacts zip ${NC}\n"

  rm channel-artifacts.zip

  printf "${GREEN}[DEPLOY] Finished init-channel-artifacts ${NC}\n"
fi

########################################################################################################################
### INIT CHANNEL #######################################################################################################
########################################################################################################################

if [ "$1" == "init-channel" ]; then
  printf "${GREEN}[DEPLOY] Start init-channel${NC}\n"

  printf "${GREEN}[DEPLOY] Create channel and get "$APP_CHANNEL".block${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/join_channel.sh create'
      scp $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/$APP_CHANNEL.block $APP_CHANNEL.block
    fi
  done

  printf "${GREEN}[DEPLOY] Copy "$APP_CHANNEL".block to other orgs${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" != "${ORG_NAMES[$i]}" ]; then
      scp $APP_CHANNEL.block $SSH_USER@${ORG_DOMAINS[$i]}:$WORKDIR/$FOLDER/$APP_CHANNEL.block &
    fi
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep for 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Join channel${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/join_channel.sh join' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep for 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Update channel${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/join_channel.sh update' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Remove $APP_CHANNEL.block${NC}\n"

  rm $APP_CHANNEL.block

  printf "${GREEN}[DEPLOY] Finished init-channel ${NC}\n"
fi

########################################################################################################################
### DEPLOY CC ##########################################################################################################
########################################################################################################################

if [ "$1" == "deploy-cc" ]; then
  printf "${GREEN}[DEPLOY] Start deploy-cc${NC}\n"

  printf "${GREEN}[DEPLOY] Install chaincode on orgs${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/deploy_cc.sh install' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep for 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Approve chaincode on orgs${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/deploy_cc.sh approve' &
  done

  wait $(jobs -p)

  printf "${GREEN}[DEPLOY] Sleep for 5 seconds ${NC}\n"

  sleep 5

  printf "${GREEN}[DEPLOY] Commit chaincode on '$2'${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/deploy_cc.sh commit ' \
      ${#ORG_IDS[@]} "${ORG_DOMAINS[@]}" "${ORG_PEER_PORTS_1[@]}"
    fi
  done

  printf "${GREEN}[DEPLOY] Finished deploy-cc${NC}\n"
fi

########################################################################################################################
### TEST CC ############################################################################################################
########################################################################################################################

if [ "$1" == "test-cc" ]; then
  printf "${GREEN}[DEPLOY] Start test-cc${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$2" == "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/test_cc.sh ' \
      $3 $4 ${#ORG_IDS[@]} "${ORG_DOMAINS[@]}" "${ORG_PEER_PORTS_1[@]}"
    fi
  done

  printf "${GREEN}[DEPLOY] Finished test-cc${NC}\n"
fi

########################################################################################################################
### DISCOVER ###########################################################################################################
########################################################################################################################

if [ "$1" == "discover" ]; then
  printf "${GREEN}[DISCOVER] Start discovery${NC}\n"

  for i in "${ORG_IDS[@]}"; do
    if [ "$3" == "${ORG_NAMES[$i]}" ]; then
      ssh $SSH_USER@${ORG_DOMAINS[$i]} 'cd '$WORKDIR'/'$FOLDER' && bash ./scripts/discover.sh '$2
    fi
  done

  printf "${GREEN}[DISCOVER] Finished discovery${NC}\n"
fi
