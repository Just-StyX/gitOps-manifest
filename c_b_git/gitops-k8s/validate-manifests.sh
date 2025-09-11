#!/bin/bash
# Kubernetes Manifest Validation Script

echo "=== Kubernetes Manifest Validation ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

echo "✅ kubectl is available"

# Directory containing the manifests
MANIFEST_DIR="."

echo ""
echo "=== Validating Fixed Manifests ==="

# List of fixed/corrected files to validate
FILES=(
    "chalk-board-namespace.yml"
    "chalk-board-secret.yml" 
    "chalk-board-shared-configmap.yml"
    "postgres-configmap.yml"
    "postgres-deployment-service.yml"
    "redis-deployment-service-fixed.yml"
    "chalk-keycloak-configuration.yml"
    "chalk-keycloak-deployment.yml"
    "gateway-application_yml.yml"
    "learning-application_yml.yml"
    "learning-ui-application_yml.yml"
    "logback-configmap.yml"
    "gateway-service-deployment-fixed.yml"
    "learning-service-deployment-fixed.yml"
    "learning-ui-deployment-fixed.yml"
    "db-backup-script-configuration.yml"
    "db-backup-cronjob.yml"
)

echo "Validating ${#FILES[@]} files..."

valid_count=0
invalid_count=0

for file in "${FILES[@]}"; do
    if [ -f "$MANIFEST_DIR/$file" ]; then
        echo -n "Validating $file... "
        if kubectl apply --dry-run=client -f "$MANIFEST_DIR/$file" &>/dev/null; then
            echo "✅ Valid"
            ((valid_count++))
        else
            echo "❌ Invalid"
            ((invalid_count++))
            # Show the error
            kubectl apply --dry-run=client -f "$MANIFEST_DIR/$file"
        fi
    else
        echo "⚠️  File $file not found"
        ((invalid_count++))
    fi
done

echo ""
echo "=== Validation Summary ==="
echo "✅ Valid files: $valid_count"
echo "❌ Invalid files: $invalid_count"

if [ $invalid_count -eq 0 ]; then
    echo ""
    echo "🎉 All manifests are valid!"
    echo "You can proceed with deployment using the order in DEPLOYMENT_ORDER.md"
else
    echo ""
    echo "⚠️  Please fix the invalid files before deployment"
fi

echo ""
echo "=== Files to Remove/Ignore ==="
echo "- redis-init-job.yml (not needed for single Redis)"
echo "- Original deployment files (use -fixed versions)"
echo "- Any files with commented code blocks"

echo ""
echo "=== Quick Deployment Test ==="
echo "To test deployment in a specific order:"
echo "kubectl apply -f chalk-board-namespace.yml"
echo "kubectl apply -f chalk-board-secret.yml"
echo "kubectl apply -f chalk-board-shared-configmap.yml"
echo "# ... continue with DEPLOYMENT_ORDER.md"
