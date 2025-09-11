# Deployment Order Guide

Deploy the Kubernetes manifests in the following order to ensure dependencies are met:

## Phase 1: Foundation
1. `chalk-board-namespace.yml` - Create the namespace first
2. `chalk-board-secret.yml` - Create secrets for passwords
3. `chalk-board-shared-configmap.yml` - Shared configuration
4. `postgres-configmap.yml` - PostgreSQL configuration
5. `redis-configuration.yml` - Redis configuration (not needed for single instance)
6. `logback-configmap.yml` - Logging configuration

## Phase 2: Infrastructure Services
7. `postgres-deployment-service.yml` - PostgreSQL database
8. `redis-deployment-service-fixed.yml` - Redis cache (use the fixed version)

## Phase 3: Authentication & Configuration
9. `chalk-keycloak-configuration.yml` - Keycloak realm configuration
10. `chalk-keycloak-deployment.yml` - Keycloak authentication server

## Phase 4: Application Configuration
11. `gateway-application_yml.yml` - Gateway service config
12. `learning-application_yml.yml` - Learning service config (newly created)
13. `learning-ui-application_yml.yml` - Learning UI config (newly created)

## Phase 5: Application Services
14. `learning-service-deployment-fixed.yml` - Learning service (use the fixed version)
15. `learning-ui-deployment-fixed.yml` - Learning UI service (use the fixed version)
16. `gateway-service-deployment-fixed.yml` - Gateway service (use the fixed version)

## Phase 6: Monitoring & Observability (Optional)
17. Deploy monitoring stack files (Grafana, Prometheus, Loki, etc.) if needed

## Phase 7: Backup & Maintenance
18. `db-backup-script-configuration.yml` - Backup script configuration
19. `db-backup-cronjob.yml` - Database backup cron job

## Files to Remove/Ignore:
- `redis-init-job.yml` - Not needed for single Redis instance
- Original deployment files (without -fixed suffix) - Use the fixed versions instead
- `redi-configuration.yml` - Already renamed to `redis-configuration.yml`

## Verification Commands:
After each phase, verify with:
```bash
kubectl get pods -n chalk-board-namespace
kubectl get svc -n chalk-board-namespace
kubectl logs -n chalk-board-namespace <pod-name>
```

## Health Check URLs (after deployment):
- Gateway: http://gateway-service:8082/gateway-service-management/health
- Learning Service: http://learning-service:8081/learning-service-management/health  
- Learning UI: http://learning-ui:8083/learning-ui-management/health
- Keycloak: http://chalk-keycloak:7080/health
