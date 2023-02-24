#!/bin/bash

export NAMESPACE="nephe-system"
export ANTREA_K3S_NAMESPACE="kube-system"
## Deploy CAs
envsubst < final_yamls/aio/ca.yml | kubectl apply -f -

## Deploy K3s Server in the cluster
envsubst < final_yamls/k3s_server.yml | kubectl apply -f - 

## Create certificate for K3s privileged user
envsubst < final_yamls/aio/k3s-admin_cert.yml | kubectl apply -f -
export SERVER_IP=`kubectl get pods -n $NAMESPACE -l app=antrea -l component=k3s-apiserver -ojson | jq -r .items[0].status.podIP`
export CA_DATA=`kubectl get secret -n $NAMESPACE server-ca-secret -o json | jq -r .data.'"tls.crt"'`
export TLS_CRT=`kubectl get secret -n $NAMESPACE k3s-admin-tls-secret -o json | jq -r .data.'"tls.crt"'`
export TLS_KEY=`kubectl get secret -n $NAMESPACE k3s-admin-tls-secret -o json | jq -r .data.'"tls.key"'`
envsubst < admin_kubeconfig.tplt > admin.kubeconfig

## Deploy Antrea Controller in the cluster
envsubst < final_yamls/aio/aio_antrea_k8s.yml | kubectl apply -f -

## Deploy Antrea CRDs/APIServices in K3s server
export ANTREA_SERVICE_IP=`kubectl get services -n $NAMESPACE antrea -o json | jq -r .spec.clusterIP`
envsubst < final_yamls/aio/aio_antrea_k3s.yml | kubectl --kubeconfig=admin.kubeconfig apply -f -

# Deploy Nephe Controller in the cluser
envsubst <  /home/ubuntu/vdp_test/final_yamls/aio/aio_nephe_k8s.yml | kubectl apply -f -

# Deploy Nephe Controller in K3s
export NEPHE_CONTROLLER_SERVICE=`kubectl get services -n $NAMESPACE nephe-controller-service -o json | jq -r .spec.clusterIP`
envsubst < final_yamls/aio/aio_nephe_k3s.yml | kubectl --kubeconfig=admin.kubeconfig apply -f -
