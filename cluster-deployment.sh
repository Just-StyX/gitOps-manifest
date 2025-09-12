#!/bin/zsh
SECRET_NAME="argocd-initial-admin-secret"
SECRET_NAMESPACE="argocd"

kind delete cluster

printf "Starting new cluster ...\n"
kind create cluster

printf "Installing istio ...\n"
istioctl install -y

printf "Applying namespace ...\n"
kubectl apply -f c_b_git/gitops-k8s/chalk-board-namespace.yml

printf "Installing ArgoCD ...\n"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sleep 40
printf "ArgoCD services create ...\n"
kubectl get pod -n $SECRET_NAMESPACE

printf "\n"

printf "Processing istio-injection ...\n"
kubectl label namespace chalk-board-namespace istio-injection=enabled

printf "Processing ArgoCD password ...\n"
# Extract the base64-encoded password using jsonpath
ENCODED_PASSWORD=$(kubectl get secret $SECRET_NAME -n $SECRET_NAMESPACE -o jsonpath='{.data.password}')

# Decode the password and echo it to the console
DECODED_PASSWORD=$(printf '%s\n', "$ENCODED_PASSWORD" | base64 --decode)

printf "The decoded password is: %s\n", "$DECODED_PASSWORD"

printf "Applying ArgoCD configuration file ...\n"
kubectl apply -f c_b_argocd-config.yml

printf "Finally, port forwarding argocd route ...\n"
kubectl port-forward -n argocd svc/argocd-server 8080:80