# deployment-simple

Simple Kubernetes deployment chart with minimal configuration. This chart provides a straightforward way to deploy containerized applications to Kubernetes with common features like ingress, service accounts, and pod disruption budgets.

## Features

- Kubernetes Deployment with configurable replicas
- Service Account creation
- Service and Ingress resources
- Pod Disruption Budget for high availability
- Topology spread constraints for node distribution
- Environment variable injection with pod metadata

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
helm install my-app slauger/deployment-simple
```

### Install with Custom Values

```bash
helm install my-app slauger/deployment-simple -f values.yaml
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicas` | Number of replicas | `1` |
| `image.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `images.application` | Application container image | `quay.io/slauger/hello-openshift:latest` |

### Route Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `route.prefix` | Route prefix for hostname | `deployment` |
| `route.baseDomain` | Base domain for the route | `cluster.example.tld` |
| `route.host` | Full hostname (computed) | `{{ .Values.route.prefix }}.{{ .Values.route.baseDomain }}` |

### Environment Variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env` | Additional environment variables | `[]` |

The chart automatically injects the following environment variables into pods:
- `MY_NODE_NAME` - Node name where the pod is running
- `MY_POD_NAME` - Pod name
- `MY_POD_NAMESPACE` - Pod namespace
- `MY_POD_IP` - Pod IP address
- `MY_POD_SERVICE_ACCOUNT` - Service account name

## Examples

### Deploy with Custom Image

```yaml
images:
  application: "myregistry.io/myapp:v1.0.0"
replicas: 3
```

### Deploy with Custom Environment Variables

```yaml
env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: url
```

### Deploy with Custom Domain

```yaml
route:
  prefix: "myapp"
  baseDomain: "example.com"
```

## Resources Created

This chart creates the following Kubernetes resources:

- **Deployment** - Main application deployment with rolling update strategy
- **Service** - ClusterIP service for internal communication
- **ServiceAccount** - Dedicated service account for the application
- **Ingress** - HTTP/HTTPS ingress for external access
- **PodDisruptionBudget** - Ensures minimum availability during disruptions

## Requirements

- Kubernetes 1.19+
- Helm 3.0+

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
