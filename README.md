# DID4DCAT Network

This repository supports the installation of the DID4DCAT Hyberledger Fabric network with at least four servers.

## Prerequisites
- SSH access to the servers
- A GitLab access token to this repository

## Server Setup
- Git
- Docker
  * `sudo apt install docker.io`
- Docker Compose (Version 1)
  * `sudo apt install docker-compose`
- Zip
  * `sudo apt install zip`
    
### Docker configuration

- Docker without root:
  * `sudo groupadd docker`
  * `sudo gpasswd -a $USER docker`

## Preparation

* Change `ORG_NAMES`, `ORG_MSPS` and `ORG_DOMAINS` to your environment
* Each node must be reachable via the configured domain respectively
* Besides configured domains each node must also be reachable via `peer-` and `orderer-` prefix
  * e.g. when a node is reachable via `did4dcat.exmaple-org1.org` it must also be reachable via `peer-did4dcat.exmaple-org1.org` and `orderer-did4dcat.exmaple-org1.org`

## Hints

* Line 25 of `./deploy.sh` shows all available `ORG_NAMES`, pick one for deployment.

### For the first time

Set `SSH_USER` in `.credentials-env`

```bash
$ echo $'SSH_USER=' > .credentials-env
$ nano .credentials-env
```

Clones this repository on all servers.

```bash
$ ./deploy.sh clone-repository
```

Init docker swarm.

```bash
$ ./deploy.sh init-docker-swarm
```

Open ports

```bash
$ ./deploy.sh open-ports
```

### For the other times

```bash
$ ./deploy.sh down
$ ./deploy.sh clean-repository
$ ./deploy.sh pull-repository
```

### Remove everything

```bash
$ ./deploy.sh down
$ ./deploy.sh remove-repository
$ ./deploy.sh remove-docker-swarm
$ ./deploy.sh close-ports
```

## Quick Start
Execute all commands

```bash
$ ./deploy.sh quick-start [$ORG_NAME]
```

## Quick Clean up
Sets each server into its initial state.

```bash
$ ./deploy.sh quick-remove
```

## Deployment and Setup

### Initialize environment

Creates an .env file on each server with the respective configuration. Values and configuration can be pre-defined in .deployment-env, configtx.yaml, crypto-config.yaml and the crypto-config directory.

```bash
$ ./deploy.sh init-environment
```

### Generate configs on all hosts

- Creates `configtx.yaml` from skeleton
- Creates `crypto_config.yaml` from skeleton
- Creates `fabric-ca-server-config.yaml` from skeleton

```bash 
$ ./deploy.sh generate-configs
```

### Generate crypto material and exchange between orgs

- Starts a Fabric CA on each server 
- Generates the certificates for the peers, orderers and the organization admin users.
- Copies the certificates to different directories (ToDo Why?)
- Synchronize the certificates and configurations on all servers

```bash
$ ./deploy.sh init-crypto
```

### Generate channel artifacts and exchange between orgs

- Starts a Fabric CLI on each server
- Initializes the Ledger with a system channel and an app channel on Org 1
- Synchronize the Ledger with all other servers (aka Orgs)
- Anchors the channel artifacts

```bash
$ ./deploy.sh init-channel-artifacts
```

### Bring up containers

Starts peers, orderers, CAs, and CLIs on all servers with Docker Compose.

```bash
$ ./deploy.sh up
```

### Create channel on-chain with orgx and join all orgs

- Creates the app channel on one Org and synchronizes it with all other Orgs
- All Orgs join the channel
- This only needs to be executed for a single Org!

```bash
$ ./deploy.sh init-channel [$ORG_NAME]
```

### Install+approve chaincode for all orgs and commit with orgx

- Installs, approves and commits the chaincode on all Orgs.

```bash
$ ./deploy.sh deploy-cc [$ORG_NAME]
```

## Further Commands

### Test chaincode functionality with orgx

- Executes the chaincode
- Can only be executed once!

```bash
$ ./deploy.sh test-cc [$ORG_NAME]
```

### Stop containers

```bash
$ ./deploy.sh stop
```

### Bring down containers 

**Note:** Removes all containers and all images with dev-*

```bash
$ ./deploy.sh down
```

### Execute Discovery on a Peer

```bash
$ ./deploy.sh discover peers [$ORG_NAME]
```

### Init docker swarm

```bash
$ ./deploy.sh init-docker-swarm [$ORG_NAME]
```

### Remove docker swarm

```bash
$ ./deploy.sh remove-docker-swarm
```

### Open ports

```bash
$ ./deploy.sh open-ports
```

### Close ports

```bash
$ ./deploy.sh open-ports
```

### Get the Certificates

In order to configure a client for communication with the network you need the peer and CA certificate. 

```bash
$ ./deploy.sh get-certs-for-app [$ORG_NAME]
```

## Additional Server Setup
You may need to open up specific ports on the hosts to use the network from outside, for example:

```bash
$ sudo ufw allow 7051
```
