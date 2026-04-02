# CourseLIT Helm Chart

A Helm chart for deploying [CourseLIT](https://courselit.app) Learning Management System on Kubernetes.

## Overview

This chart deploys a production-ready CourseLIT instance with support for:
- Main CourseLIT application
- MongoDB (via Community Operator or external)
- Optional queue service with Valkey/Redis
- Optional MediaLit file storage service with AWS S3 integration
- Ingress or Gateway API for external access

## Prerequisites

### Required

- Kubernetes 1.24+
- Helm 3.8+
- External Secrets Operator for secret management
- MongoDB Community Operator (if using in-cluster MongoDB)
- Ingress controller OR Gateway API implementation

### Installation Commands

```bash
# External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system --create-namespace

# MongoDB Community Operator (if using in-cluster MongoDB)
helm repo add mongodb https://mongodb.github.io/helm-charts
helm install mongodb-operator mongodb/community-operator

# Nginx Ingress Controller (recommended)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# Cert-Manager (for TLS)
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace --set installCRDs=true
```

## Installation

### 1. Add Helm repository

```bash
# If published to a Helm repository
helm repo add courselit https://your-helm-repo.com
helm repo update
```

### 2. Create secrets

```bash
# Create namespace
kubectl create namespace courselit

# Auth secret
kubectl create secret generic courselit-auth -n courselit \
  --from-literal=auth-secret=$(openssl rand -base64 32)

# Email credentials
kubectl create secret generic courselit-email -n courselit \
  --from-literal=email-user=your-email@example.com \
  --from-literal=email-pass=your-password \
  --from-literal=email-host=smtp.example.com \
  --from-literal=email-from=noreply@example.com

# MongoDB password (if using in-cluster MongoDB)
kubectl create secret generic courselit-mongodb -n courselit \
  --from-literal=password=$(openssl rand -base64 32)
```

### 3. Create values file

Create `values-production.yaml`:

```yaml
app:
  config:
    superAdminEmail: admin@example.com

  smtp:
    host: smtp-relay.example.com
    port: 587
    user: smtp-user
    from: noreply@example.com

  ingress:
    enabled: true
    hosts:
      - host: courselit.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: courselit-tls
        hosts:
          - courselit.example.com

mongodb:
  enabled: true
```

### 4. Install the chart

```bash
# Update dependencies (for Valkey subchart)
helm dependency update

# Install
helm install courselit ./courselit -n courselit -f values-production.yaml
```

## Configuration

### Main Application

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.replicaCount` | Number of app replicas | `1` |
| `app.image.repository` | App image repository | `codelit/courselit-app` |
| `app.image.tag` | App image tag | `latest` |
| `app.config.superAdminEmail` | Super admin email (required) | `""` |
| `app.smtp.host` | SMTP server hostname | `""` |
| `app.smtp.port` | SMTP server port | `587` |
| `app.secrets.authSecretRef.name` | Secret containing AUTH_SECRET | `courselit-auth` |
| `app.ingress.enabled` | Enable Ingress | `true` |
| `app.ingress.className` | Ingress class name | `nginx` |
| `app.gateway.enabled` | Enable Gateway API (mutually exclusive with Ingress) | `false` |

### MongoDB

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Deploy MongoDB via operator | `true` |
| `mongodb.external.connectionString` | External MongoDB connection string | `""` |
| `mongodb.version` | MongoDB version | `7.0.0` |
| `mongodb.type` | Deployment type (ReplicaSet/Standalone) | `ReplicaSet` |
| `mongodb.members` | Number of replica set members | `3` |
| `mongodb.auth.existingSecret` | Secret containing MongoDB password | `courselit-mongodb` |
| `mongodb.storage.size` | Storage size for each MongoDB instance | `10Gi` |

### Queue Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `queue.enabled` | Enable queue service | `false` |
| `queue.config.domain` | Domain for email links | `courselit.example.com` |
| `redis.external.enabled` | Use external Redis | `false` |
| `redis.external.host` | External Redis hostname | `""` |
| `valkey.enabled` | Deploy Valkey subchart | `true` |

### MediaLit Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `medialit.enabled` | Enable MediaLit service | `false` |
| `medialit.config.s3.bucketName` | S3 bucket name (required when enabled) | `""` |
| `medialit.config.s3.region` | S3 region (required when enabled) | `""` |
| `medialit.config.cloudfront.enabled` | Enable CloudFront | `false` |
| `medialit.serviceAccount.annotations` | IRSA annotation for AWS IAM role | `{}` |
| `medialit.externalSecrets.enabled` | Use External Secrets Operator | `true` |

## Usage Examples

### Minimal Deployment

```bash
helm install courselit ./courselit -n courselit \
  --set app.config.superAdminEmail=admin@example.com
```

### With Queue Service

```bash
helm install courselit ./courselit -n courselit \
  --set app.config.superAdminEmail=admin@example.com \
  --set queue.enabled=true \
  --set queue.config.domain=courselit.example.com
```

### With External MongoDB

```yaml
mongodb:
  enabled: false
  external:
    connectionString: "mongodb+srv://user:pass@cluster.mongodb.net/courselit?retryWrites=true&w=majority"
```

### With MediaLit and AWS IRSA

```yaml
medialit:
  enabled: true
  config:
    s3:
      bucketName: my-courselit-media
      region: us-east-1
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/courselit-medialit"
  externalSecrets:
    enabled: true
    secretStore:
      name: aws-secrets-manager
      kind: ClusterSecretStore
```

### With Gateway API

```yaml
app:
  ingress:
    enabled: false
  gateway:
    enabled: true
    gatewayClassName: "eg"  # Envoy Gateway
    hostnames:
      - courselit.example.com
```

## Post-Installation

### 1. Verify Deployment

```bash
kubectl get pods -n courselit
kubectl get svc -n courselit
kubectl get ingress -n courselit
```

### 2. Access Application

Via port-forward (testing):
```bash
kubectl port-forward -n courselit svc/courselit-app 8080:80
```

Via ingress (production):
```
https://courselit.example.com
```

### 3. Retrieve Admin Login

Check logs for magic login link:
```bash
kubectl logs -n courselit -l app.kubernetes.io/component=app | grep -i "magic link"
```

### 4. Configure SSO (Optional)

SSO/SAML must be configured via the web UI:
1. Login as super admin
2. Navigate to Settings → Miscellaneous → Login providers
3. Configure your IdP settings

See: https://courselit.app/docs/en/schools/sso

## Upgrading

```bash
helm upgrade courselit ./courselit -n courselit -f values-production.yaml
```

### Enable Queue Service

```bash
helm upgrade courselit ./courselit -n courselit -f values-production.yaml \
  --set queue.enabled=true
```

## Troubleshooting

### Pods Not Starting

Check MongoDB connectivity:
```bash
kubectl logs -n courselit <pod-name> -c wait-for-mongodb
```

### Email Not Working

Verify SMTP configuration:
```bash
kubectl get cm -n courselit courselit-app -o yaml
kubectl get secret -n courselit courselit-email -o yaml
```

### MediaLit S3 Access Issues

Check IRSA annotation:
```bash
kubectl describe sa -n courselit courselit-medialit
```

Verify ExternalSecret:
```bash
kubectl get externalsecret -n courselit
kubectl describe externalsecret -n courselit courselit-medialit-secrets
```

## Uninstallation

```bash
helm uninstall courselit -n courselit
kubectl delete namespace courselit
```

**Note**: This will delete all data. Backup MongoDB before uninstalling.

## Support

- Documentation: https://courselit.app/docs
- GitHub: https://github.com/codelitdev/courselit
- Discord: https://discord.com/invite/GR4bQsN

## License

This Helm chart is provided under the MIT License.
CourseLIT itself is licensed under its own terms - see the project repository for details.
