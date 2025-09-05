#!/bin/zsh

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# and then kubectl apply -f argo-cd-configuration.yml

# obtaining password
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
printf found_password | base64 --decode

docker container inspect kind-control-plane --format '{{ .NetworkSettings.Networks.kind.IPAddress }}'

 # adding istio
istioctl install
kubectl label namespace namespace-where-manifests-are-deployed istio-injection=enabled