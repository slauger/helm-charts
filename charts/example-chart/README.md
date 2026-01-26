# example-chart

Example Helm chart demonstrating common Kubernetes deployment patterns. This chart serves as a template and reference implementation for deploying applications to Kubernetes with best practices including autoscaling, ingress, security contexts, and resource management.

## Features

- **Standard Deployment** - Basic Kubernetes deployment with configurable replicas
- **Horizontal Pod Autoscaling (HPA)** - Automatic scaling based on CPU/memory utilization
- **Service Account** - Dedicated service account with configurable annotations
- **Service and Ingress** - ClusterIP service and optional Ingress for external access
- **Health Checks** - Liveness and readiness probes
- **Security Contexts** - Pod and container-level security configurations
- **Resource Management** - CPU and memory limits/requests
- **Node Affinity** - Node selectors, tolerations, and affinity rules
- **Image Pull Secrets** - Support for private container registries

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
helm install my-app slauger/example-chart
```

### Install with Custom Values

```bash
helm install my-app slauger/example-chart -f values.yaml
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas (ignored if autoscaling is enabled) | `1` |
| `image.repository` | Container image repository | `nginx` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag (overrides chart appVersion) | `""` |
| `imagePullSecrets` | Image pull secrets for private registries | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full name | `""` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name (generated if not set) | `""` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | Not set |

### Security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Pod annotations | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources` | CPU/memory resource requests/limits | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |

## Examples

### Deploy with Custom Image

```yaml
image:
  repository: myregistry.io/myapp
  tag: v1.0.0
  pullPolicy: Always
replicaCount: 3
```

### Enable Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

### Enable Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### Configure Security Context

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Use Private Registry

```yaml
imagePullSecrets:
  - name: registry-credentials

image:
  repository: private.registry.io/myapp
  tag: latest
```

### Node Affinity Example

```yaml
nodeSelector:
  kubernetes.io/os: linux

tolerations:
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - example-chart
          topologyKey: kubernetes.io/hostname
```

## Resources Created

This chart creates the following Kubernetes resources:

- **Deployment** - Main application deployment
- **Service** - ClusterIP service for internal communication
- **ServiceAccount** - Dedicated service account (if enabled)
- **Ingress** - HTTP/HTTPS ingress (if enabled)
- **HorizontalPodAutoscaler** - Automatic scaling (if enabled)

## Health Checks

The chart includes default health checks:

- **Liveness Probe** - HTTP GET on port 80 at path `/`
- **Readiness Probe** - HTTP GET on port 80 at path `/`

Customize these in your application's values if your app uses different ports or paths.

## Requirements

- Kubernetes 1.19+
- Helm 3.0+

## Use Cases

This example chart is ideal for:

- Learning Helm chart development
- Starting point for new applications
- Reference for Kubernetes best practices
- Testing Helm deployments
- CI/CD pipeline templates

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
