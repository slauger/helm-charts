# deployment

Kubernetes deployment chart with Envoy proxy sidecar for TLS termination. This chart provides a complete solution for deploying containerized applications with automatic TLS termination via Envoy proxy, service account management, and high availability features.

## Features

- **Envoy Proxy Sidecar** - Automatic TLS termination with Envoy v1.23.1
- **Dual Container Architecture** - Application container with Envoy sidecar
- **TLS Certificate Management** - Automatic mounting of TLS certificates from secrets
- **ConfigMap Support** - External configuration via ConfigMap
- **Service Account** - Dedicated service account for the application
- **Service and Ingress** - ClusterIP service and Ingress resources
- **Pod Disruption Budget** - Ensures minimum availability during disruptions
- **Topology Spread Constraints** - Automatic pod distribution across nodes
- **Environment Variable Injection** - Pod metadata available as environment variables

## Architecture

This chart deploys two containers in a single pod:

1. **Envoy Container** (`envoy`) - Listens on port 8443 (HTTPS) and terminates TLS
2. **Application Container** (`application`) - Your application listening on port 8080 (HTTP)

Envoy proxies incoming HTTPS requests to the application container over HTTP via localhost.

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
helm install my-app slauger/deployment
```

### Install with Custom Values

```bash
helm install my-app slauger/deployment -f values.yaml
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicas` | Number of replicas | `1` |
| `image.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `images.application` | Application container image | `quay.io/slauger/hello-openshift:latest` |
| `images.envoy` | Envoy proxy container image | `docker.io/envoyproxy/envoy:v1.23.1` |

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

The chart automatically injects the following environment variables into the application container:
- `MY_NODE_NAME` - Node name where the pod is running
- `MY_POD_NAME` - Pod name
- `MY_POD_NAMESPACE` - Pod namespace
- `MY_POD_IP` - Pod IP address
- `MY_POD_SERVICE_ACCOUNT` - Service account name

## TLS Configuration

This chart requires a TLS secret to be created before deployment. The secret should contain:

- `tls.crt` - TLS certificate
- `tls.key` - TLS private key

### Create TLS Secret

```bash
kubectl create secret tls <release-name>-tls-cert \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

Replace `<release-name>` with your Helm release name.

## Envoy Configuration

The Envoy proxy configuration is loaded from `files/envoy.yaml` in the chart. The default configuration:

- Listens on port **8443** (HTTPS)
- Terminates TLS using certificates from `/etc/envoy/tls.crt` and `/etc/envoy/tls.key`
- Proxies traffic to **127.0.0.1:8080** (application container)
- Admin interface on port **9901**
- Connection limit: **500** concurrent connections

To customize the Envoy configuration, modify the `files/envoy.yaml` file before deploying.

## Examples

### Deploy with Custom Images

```yaml
images:
  application: "myregistry.io/myapp:v1.0.0"
  envoy: "docker.io/envoyproxy/envoy:v1.28.0"
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

- **Deployment** - Main application deployment with Envoy sidecar and rolling update strategy
- **ConfigMap** - Envoy configuration from `files/envoy.yaml`
- **Service** - ClusterIP service for internal communication
- **ServiceAccount** - Dedicated service account for the application
- **Ingress** - HTTP/HTTPS ingress for external access
- **PodDisruptionBudget** - Ensures minimum availability during disruptions

## Requirements

- Kubernetes 1.19+
- Helm 3.0+
- TLS certificate secret (must be created before deployment)

## Port Reference

| Container | Port | Protocol | Description |
|-----------|------|----------|-------------|
| Envoy | 8443 | HTTPS | External TLS endpoint |
| Envoy | 9901 | HTTP | Admin interface |
| Application | 8080 | HTTP | Application (internal only) |

## Troubleshooting

### Check Envoy Logs

```bash
kubectl logs <pod-name> -c envoy
```

### Check Application Logs

```bash
kubectl logs <pod-name> -c application
```

### Access Envoy Admin Interface

```bash
kubectl port-forward <pod-name> 9901:9901
curl http://localhost:9901/stats
```

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
