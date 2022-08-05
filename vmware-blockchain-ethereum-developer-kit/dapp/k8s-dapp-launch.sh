#!/bin/bash

set -e

cd ../vmbc/script

. ./utils.sh

# Souce proper env
sourceEnv

# Check Pre-requisites
checkPreReqs

# Get the options
getOptions
cd -

# Check minikube status
if $ENABLE_MINIKUBE; then
  isMinikubeRunning
fi

NAMESPACE="vmbc-dapp"

if [ ! -f ../vmbc/.env.config ]; then
   infoln ''
   fatalln '---------------- file ../vmbc/.env.config does not exist. ----------------'
fi

cp erc20-swap-dapp.yml.tmpl erc20-swap-dapp.yml

sed $OPTS "s!erc20swap_repo!${erc20swap_repo}!ig
        s!erc20swap_tag!${erc20swap_tag}!ig"  erc20-swap-dapp.yml;

# registry login
registryLogin
if $ENABLE_MINIKUBE; then
  infoln ''
  infoln "---------------- Pulling image  ${erc20swap_repo}:${erc20swap_tag}, this may take several minutes... ----------------"
  minikube ssh "docker pull ${erc20swap_repo}:${erc20swap_tag}"
fi

infoln ''
infoln '---------------- Creating DAPP Configmaps ----------------'
kubectl create namespace ${NAMESPACE}
kubectl create cm dapp-configmap --from-env-file=../vmbc/.env.config --namespace ${NAMESPACE}
kubectl create secret docker-registry regcred-dapp --docker-server=vmwaresaas.jfrog.io --docker-username='${benzeneu}' --docker-password='${benzene}' --docker-email=ask_VMware_blockchain@VMware.com --namespace=${NAMESPACE}
sleep 5 

infoln ''
infoln '---------------- Creating DAPP PoD ----------------'
kubectl apply -f erc20-swap-dapp.yml --namespace ${NAMESPACE}
sleep 10
infoln ''
infoln '---------------- Get the URL   ----------------'
minikube service erc20-swap --url --namespace ${NAMESPACE}
successln '========================== DONE ==========================='
infoln ''