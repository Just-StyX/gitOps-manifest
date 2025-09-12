#!/bin/zsh

SECRET_NAME="argocd-initial-admin-secret"
SECRET_NAMESPACE="argocd"

# Use tput for bold output. Check if it's available.
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold)
  NORMAL=$(tput sgr0)
else
  BOLD=""
  NORMAL=""
fi

printf "\n%s  Deleting existing cluster...${NORMAL}\n", "${BOLD}🗑️"
kind delete cluster || { printf "⚠️ Failed to delete cluster. Exiting.\n"; exit 1; }

printf "\n%s  Starting new cluster...${NORMAL}\n", "${BOLD}🚀"
kind create cluster || { printf "❌ Failed to create cluster. Exiting.\n"; exit 1; }

printf "\n%s  Installing Istio...${NORMAL}\n", "${BOLD}🛠️"
istioctl install -y || { printf "❌ Failed to install Istio. Exiting.\n"; exit 1; }

printf "\n%s  Applying namespace configuration...${NORMAL}\n", "${BOLD}📁"
kubectl apply -f c_b_git/gitops-k8s/chalk-board-namespace.yml || { printf "❌ Failed to apply namespace. Exiting.\n"; exit 1; }

printf "\n%s  Installing ArgoCD...${NORMAL}\n", "${BOLD}🚢"
kubectl create namespace argocd || { printf "❌ Failed to create argocd namespace. Exiting.\n"; exit 1; }
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || { printf "❌ Failed to install ArgoCD. Exiting.\n"; exit 1; }

printf "\n%s  Waiting for ArgoCD services to become ready...${NORMAL}\n", "${BOLD}⏱️"
kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || { printf "❌ ArgoCD pods not ready after 300s. Exiting.\n"; exit 1; }
kubectl get pod -n $SECRET_NAMESPACE

printf "\n%s  Processing Istio-injection...${NORMAL}\n", "${BOLD}💉"
kubectl label namespace chalk-board-namespace istio-injection=enabled --overwrite || { printf "❌ Failed to label namespace for istio-injection. Exiting.\n"; exit 1; }

printf "\n%s  Processing ArgoCD password...${NORMAL}\n", "${BOLD}🔑"
# Extract and decode the password
ENCODED_PASSWORD=$(kubectl get secret $SECRET_NAME -n $SECRET_NAMESPACE -o jsonpath='{.data.password}')
DECODED_PASSWORD=$(printf '%s\n', "$ENCODED_PASSWORD" | base64 --decode)
printf "The decoded password is: ${BOLD}%s${NORMAL}\n", "$DECODED_PASSWORD"

printf "\n%s  Applying ArgoCD configuration file...${NORMAL}\n", "${BOLD}📄"
kubectl apply -f c_b_argocd-config.yml || { printf "❌ Failed to apply ArgoCD configuration. Exiting.\n"; exit 1; }

printf "\n%s  Finally, port forwarding ArgoCD server...${NORMAL}\n", "${BOLD}➡️"
printf "Access ArgoCD on your browser at http://localhost:8080\n"
kubectl port-forward -n argocd svc/argocd-server 8080:80 || { printf "❌ Port forwarding failed. Exiting.\n"; exit 1; }
