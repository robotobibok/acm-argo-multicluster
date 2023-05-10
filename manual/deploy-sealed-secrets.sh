#!/bin/bash

[ $# -eq 0 ] && { echo "Usage: $0 cluster-name"; exit 1; }

DEPLOYED_CLUSER_NAME=$1
INFRA_CLUSTER_API_URL="https://api.infra.eskom.demo"
TLS_SECRET_NAME="prod-keys"

# Login infra cluster
echo "Logowanie do clustra infra"
read -p "Username: " infra_username
read -s -p "Password: " infra_password

oc login  --username=$infra_username --password=$infra_password \
       ${INFRA_CLUSTER_API_URL}:6443 > /dev/null

[ $? -eq 0 ] || { echo -e "\nError: Nie udało się zalogwać do clustra infra"; exit 1; }

echo -e

# Ensure deployed cluster namespace exist
oc project $DEPLOYED_CLUSER_NAME > /dev/null

[ $? -eq 0 ] || { echo -e "\nError: Projekt dla powołanego klastra nie istnieje"; exit 1; }

# Get cert and key for seled secret
temp_tls_dir=$(mktemp -d ${PWD}/tls.XXXXX)
oc extract secret/${DEPLOYED_CLUSER_NAME}-tls-sealed-secrets \
       --to $temp_tls_dir -n $DEPLOYED_CLUSER_NAME > /dev/null

[ $? -eq 0 ] || { echo "Error: Brak TLS dla powołanego klastra"; rm -rf $temp_tls_dir; exit 1; }

# Get kubeconfig to deployed cluster
temp_kubeconfig_dir=$(mktemp -d ${PWD}/auth.XXXXX)
oc extract secret/$(oc get secrets -n prod | grep -o -e "${DEPLOYED_CLUSER_NAME}-.*-kubeconfig") \
       --to $temp_kubeconfig_dir -n $DEPLOYED_CLUSER_NAME > /dev/null

[ $? -eq 0 ] || { echo "Error: Brak kubeconfig dla powołanego klastra"; rm -rf $temp_kubeconfig_dir; exit 1; }

oc logout

# Apply seled-secrets on deployed cluster
set -e
export KUBECONFIG=${temp_kubeconfig_dir}/kubeconfig

oc apply -f deploy-sealed-secrets.yaml
oc create secret tls $TLS_SECRET_NAME -n sealed-secrets \
        --cert="${temp_tls_dir}/tls.crt" --key="${temp_tls_dir}/tls.key"
oc label secret/$TLS_SECRET_NAME sealedsecrets.bitnami.com/sealed-secrets-key=active -n sealed-secrets
oc delete pod -l name=sealed-secrets-controller -n sealed-secrets
oc logout

rm -rf $temp_tls_dir
rm -rf $temp_kubeconfig_dir

echo "KONIEC!"