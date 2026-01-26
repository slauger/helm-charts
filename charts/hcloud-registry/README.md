# hcloud-registry

Docker Registry v2 with Hetzner Cloud S3 storage backend.

## Features

- 🐳 Docker Registry v2 (registry:2.8.3)
- 📦 Hetzner Cloud S3 as storage backend
- 🔒 Basic Authentication with htpasswd
- 🌐 Ingress support with TLS
- ✅ Health checks
- 🔧 Fully configurable

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Hetzner Cloud Object Storage bucket
- Ingress controller (e.g., Traefik, nginx-ingress)

## Installation

### 1. Create Hetzner Cloud S3 Bucket

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Navigate to "Object Storage"
3. Create a new bucket (e.g., `my-registry-bucket`)
4. Create S3 credentials (Access Key + Secret Key)
5. Note the endpoint URL (e.g., `https://fsn1.your-objectstorage.com`)

### 2. Generate htpasswd credentials

```bash
# Generate htpasswd for user "admin"
docker run --rm --entrypoint htpasswd registry:2 -Bbn admin <YOUR_PASSWORD>

# Output example:
# admin:$2y$05$...

# Base64 encode the htpasswd output
echo -n 'admin:$2y$05$...' | base64

# Output example (use this in values.yaml):
# YWRtaW46JDJ5JDA1JC4uLg==
```

### 3. Install the chart

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update

helm install my-registry slauger/hcloud-registry \
  --set auth.htpasswd="YWRtaW46JDJ5JDA1JC4uLg==" \
  --set storage.s3.bucket="my-registry-bucket" \
  --set storage.s3.endpoint="https://fsn1.your-objectstorage.com" \
  --set storage.s3.accessKey="YOUR_ACCESS_KEY" \
  --set storage.s3.secretKey="YOUR_SECRET_KEY" \
  --set ingress.hosts[0].host="registry.example.com"
```

### 4. Using a values file (recommended)

Create a `values.yaml`:

```yaml
auth:
  htpasswd: "YWRtaW46JDJ5JDA1JC4uLg=="

storage:
  s3:
    bucket: "my-registry-bucket"
    region: "eu-central"
    endpoint: "https://fsn1.your-objectstorage.com"
    accessKey: "YOUR_ACCESS_KEY"
    secretKey: "YOUR_SECRET_KEY"

ingress:
  enabled: true
  className: "traefik"
  hosts:
    - host: registry.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: registry-tls
      hosts:
        - registry.example.com
```

Install:

```bash
helm install my-registry slauger/hcloud-registry -f values.yaml
```

## Usage

### Login to registry

```bash
docker login registry.example.com
# Username: admin
# Password: <YOUR_PASSWORD>
```

### Push an image

```bash
# Tag your image
docker tag myapp:latest registry.example.com/myapp:latest

# Push to registry
docker push registry.example.com/myapp:latest
```

### Pull an image

```bash
docker pull registry.example.com/myapp:latest
```

## Using with Kubernetes

### Create ImagePullSecret

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.example.com \
  --docker-username=admin \
  --docker-password=<YOUR_PASSWORD> \
  --docker-email=you@example.com
```

### Use in deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      imagePullSecrets:
        - name: registry-credentials
      containers:
        - name: myapp
          image: registry.example.com/myapp:latest
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | Docker image registry | `docker.io` |
| `image.repository` | Docker image repository | `registry` |
| `image.tag` | Docker image tag | `2.8.3` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `5000` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `traefik` |
| `ingress.hosts` | Ingress hosts | `[{host: registry.example.com}]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |
| `auth.htpasswd` | Base64 encoded htpasswd | `""` |
| `storage.s3.bucket` | S3 bucket name | `my-registry-bucket` |
| `storage.s3.region` | S3 region | `eu-central` |
| `storage.s3.endpoint` | S3 endpoint URL | `https://fsn1.your-objectstorage.com` |
| `storage.s3.accessKey` | S3 access key | `""` |
| `storage.s3.secretKey` | S3 secret key | `""` |
| `storage.s3.encrypt` | Enable encryption at rest | `true` |
| `storage.s3.secure` | Use HTTPS | `true` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

See `values.yaml` for full configuration options.

## Hetzner Cloud Object Storage Endpoints

| Location | Endpoint |
|----------|----------|
| Falkenstein | `https://fsn1.your-objectstorage.com` |
| Nuremberg | `https://nbg1.your-objectstorage.com` |
| Helsinki | `https://hel1.your-objectstorage.com` |

## Troubleshooting

### Check registry logs

```bash
kubectl logs -l app.kubernetes.io/name=hcloud-registry -f
```

### Test registry connectivity

```bash
# From inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -u admin:<PASSWORD> http://my-registry-hcloud-registry:5000/v2/_catalog
```

### Verify S3 connection

Check deployment logs for S3-related errors:

```bash
kubectl logs -l app.kubernetes.io/name=hcloud-registry | grep -i s3
```

Common issues:
- Incorrect endpoint URL
- Wrong S3 credentials
- Bucket doesn't exist
- Network policy blocking egress to S3

## Security Considerations

- Always use HTTPS/TLS for ingress (enable cert-manager)
- Store credentials in Kubernetes Secrets (not in values files)
- Use strong passwords for htpasswd authentication
- Consider using RBAC for S3 bucket access
- Enable encryption at rest (`storage.s3.encrypt: true`)

## License

This Helm chart is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/slauger/helm-charts).

## Maintainers

- Simon Lauger ([@slauger](https://github.com/slauger))
