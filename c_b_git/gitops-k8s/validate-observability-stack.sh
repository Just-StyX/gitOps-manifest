#!/bin/bash

# Observability Stack Validation Script
# This script validates the health and connectivity of the observability stack

set -e

NAMESPACE="chalk-board-namespace"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Observability Stack in namespace: $NAMESPACE"
echo "=================================================="

# Function to check if a pod is running
check_pod_status() {
    local pod_name=$1
    local status=$(kubectl get pods -n $NAMESPACE -l app=$pod_name -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$status" = "Running" ]; then
        echo -e "✅ ${GREEN}$pod_name pod is running${NC}"
        return 0
    elif [ "$status" = "NotFound" ]; then
        echo -e "❌ ${RED}$pod_name pod not found${NC}"
        return 1
    else
        echo -e "⚠️  ${YELLOW}$pod_name pod status: $status${NC}"
        return 1
    fi
}

# Function to check if a service exists and has endpoints
check_service() {
    local service_name=$1
    local port=$2
    
    if kubectl get svc $service_name -n $NAMESPACE >/dev/null 2>&1; then
        local endpoints=$(kubectl get endpoints $service_name -n $NAMESPACE -o jsonpath='{.subsets[0].addresses}' 2>/dev/null || echo "[]")
        if [ "$endpoints" != "[]" ] && [ "$endpoints" != "" ]; then
            echo -e "✅ ${GREEN}$service_name service has endpoints${NC}"
            return 0
        else
            echo -e "⚠️  ${YELLOW}$service_name service exists but has no endpoints${NC}"
            return 1
        fi
    else
        echo -e "❌ ${RED}$service_name service not found${NC}"
        return 1
    fi
}

# Function to check PVC status
check_pvc() {
    local pvc_name=$1
    local status=$(kubectl get pvc $pvc_name -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$status" = "Bound" ]; then
        echo -e "✅ ${GREEN}$pvc_name PVC is bound${NC}"
        return 0
    elif [ "$status" = "NotFound" ]; then
        echo -e "❌ ${RED}$pvc_name PVC not found${NC}"
        return 1
    else
        echo -e "⚠️  ${YELLOW}$pvc_name PVC status: $status${NC}"
        return 1
    fi
}

echo "📦 Checking Pod Status..."
echo "-------------------------"
check_pod_status "prometheus"
check_pod_status "grafana" 
check_pod_status "loki"
check_pod_status "tempo"
check_pod_status "otel-collector"
check_pod_status "jaeger"
check_pod_status "zipkin"
check_pod_status "memcached"

echo ""
echo "🌐 Checking Service Status..."
echo "-----------------------------"
check_service "prometheus" "9090"
check_service "grafana" "3000"
check_service "loki" "3100"
check_service "tempo" "3200"
check_service "otel-collector" "4317"
check_service "jaeger-all-in-one" "16686"
check_service "zipkin-all-in-one" "9411"
check_service "memcached" "11211"

echo ""
echo "💾 Checking Persistent Volume Claims..."
echo "---------------------------------------"
check_pvc "prometheus-pvc"
check_pvc "grafana-pvc"
check_pvc "loki-pvc"
check_pvc "tempo-pvc"

echo ""
echo "🔗 Testing Service Connectivity..."
echo "----------------------------------"

# Test internal connectivity using kubectl exec
test_connectivity() {
    local from_pod=$1
    local to_service=$2
    local port=$3
    local description=$4
    
    # Get the first pod of the specified type
    local pod_name=$(kubectl get pods -n $NAMESPACE -l app=$from_pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod_name" ]; then
        echo -e "⚠️  ${YELLOW}Cannot test $description - $from_pod pod not available${NC}"
        return 1
    fi
    
    if timeout 5 kubectl exec $pod_name -n $NAMESPACE -- wget -q --spider http://$to_service:$port 2>/dev/null; then
        echo -e "✅ ${GREEN}$description connectivity OK${NC}"
        return 0
    else
        echo -e "❌ ${RED}$description connectivity FAILED${NC}"
        return 1
    fi
}

# Test key connectivity paths
test_connectivity "grafana" "prometheus" "9090" "Grafana -> Prometheus"
test_connectivity "grafana" "loki" "3100" "Grafana -> Loki"
test_connectivity "grafana" "tempo" "3200" "Grafana -> Tempo"
test_connectivity "otel-collector" "prometheus" "9090" "OTEL -> Prometheus"
test_connectivity "otel-collector" "loki" "3100" "OTEL -> Loki"
test_connectivity "otel-collector" "tempo" "4317" "OTEL -> Tempo"

echo ""
echo "📊 Checking ConfigMaps..."
echo "-------------------------"
configmaps=("prometheus-config" "grafana-datasource-config" "grafana-dashboard-provisioning" "grafana-dashboards" "loki-config" "tempo-config" "otel-collector-config" "memcached-config")

for cm in "${configmaps[@]}"; do
    if kubectl get configmap $cm -n $NAMESPACE >/dev/null 2>&1; then
        echo -e "✅ ${GREEN}$cm ConfigMap exists${NC}"
    else
        echo -e "❌ ${RED}$cm ConfigMap missing${NC}"
    fi
done

echo ""
echo "🔐 Checking Secrets..."
echo "----------------------"
if kubectl get secret chalkboard-secret -n $NAMESPACE >/dev/null 2>&1; then
    echo -e "✅ ${GREEN}chalkboard-secret exists${NC}"
else
    echo -e "❌ ${RED}chalkboard-secret missing (needed for Grafana)${NC}"
fi

echo ""
echo "📈 Resource Usage Summary..."
echo "----------------------------"
echo "Pod Resource Usage:"
kubectl top pods -n $NAMESPACE --no-headers 2>/dev/null | grep -E "prometheus|grafana|loki|tempo|otel|jaeger|zipkin|memcached" || echo "⚠️  Metrics server not available"

echo ""
echo "🏁 Validation Complete!"
echo "======================="

# Summary
echo ""
echo "📋 Quick Access URLs (if using port-forward):"
echo "----------------------------------------------"
echo "Grafana: http://localhost:3000"
echo "Prometheus: http://localhost:9090"
echo "Jaeger: http://localhost:16686"
echo "Zipkin: http://localhost:9411"
echo ""
echo "🚀 Port Forward Commands:"
echo "-------------------------"
echo "kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE"
echo "kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE"
echo "kubectl port-forward svc/jaeger-all-in-one 16686:16686 -n $NAMESPACE"
echo "kubectl port-forward svc/zipkin-all-in-one 9411:9411 -n $NAMESPACE"