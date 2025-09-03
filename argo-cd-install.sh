#!/bin/zsh

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# obtaining password
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
printf found_password | base64 --decode