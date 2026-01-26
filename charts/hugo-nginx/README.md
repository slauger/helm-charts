# hugo-nginx

Generic Helm chart for deploying Hugo static sites with nginx.

## Features

- 🚀 Deploy Hugo static sites to Kubernetes
- 🌐 nginx webserver (official nginx:alpine image)
- 🔒 Security best practices (non-root, dropped capabilities)
- 📈 Horizontal Pod Autoscaler support
- 🛡️ Pod Disruption Budget support
- ✅ Health checks (liveness & readiness probes)
- 🔧 Fully configurable

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- A Docker image containing your Hugo site served by nginx

## Usage

### Installation

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update

helm install my-site slauger/hugo-nginx \
  --set image.repository=myregistry.com/mysite \
  --set image.tag=latest \
  --set ingress.hosts[0].host=example.com
```

### Using a values file

Create a `values.yaml`:

```yaml
image:
  repository: registry.example.com/mysite
  tag: "v1.0.0"
  pullPolicy: Always

imagePullSecrets:
  - name: registry-credentials

ingress:
  enabled: true
  className: traefik
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: example-tls
      hosts:
        - example.com

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
```

Install:

```bash
helm install my-site slauger/hugo-nginx -f values.yaml
```

## Building Your Docker Image

This chart expects a Docker image with:
- Hugo static site built in `/usr/share/nginx/html`
- nginx serving on port 80
- Health check endpoint at `/health`

### Example Dockerfile

```dockerfile
# Build stage
FROM hugomods/hugo:exts AS builder
WORKDIR /build
COPY . .
RUN hugo --minify

# Runtime stage
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /build/public /usr/share/nginx/html
RUN chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
USER nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Example nginx.conf

```nginx
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /tmp/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ $uri.html =404;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docker image repository | `myapp` |
| `image.tag` | Docker image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `replicaCount` | Number of replicas | `2` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `traefik` |
| `ingress.hosts` | Ingress hosts | `[{host: example.com}]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `64Mi` |
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `80` |
| `podDisruptionBudget.enabled` | Enable PDB | `false` |
| `podDisruptionBudget.minAvailable` | Minimum available pods | `1` |

See `values.yaml` for all available options.

## Examples

### With private registry

```yaml
image:
  repository: registry.example.com/mysite
  tag: "latest"
  pullPolicy: Always

imagePullSecrets:
  - name: registry-credentials
```

Create the secret:

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword
```

### With autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### With TLS and cert-manager

```yaml
ingress:
  enabled: true
  className: traefik
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: example-tls
      hosts:
        - example.com
```

## Health Checks

The chart includes health checks that expect:
- **Liveness probe**: `GET /health` returns 200
- **Readiness probe**: `GET /health` returns 200

Make sure your nginx configuration includes a `/health` endpoint.

## Security

The chart follows security best practices:
- Runs as non-root user (nginx user, UID 101)
- Drops all capabilities
- No privilege escalation
- Security context enforced

## Troubleshooting

### Check pod logs

```bash
kubectl logs -l app.kubernetes.io/name=hugo-nginx -f
```

### Test locally

```bash
# Port forward to the service
kubectl port-forward svc/my-site-hugo-nginx 8080:80

# Visit http://localhost:8080
```

### Check health endpoint

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://my-site-hugo-nginx/health
```

## License

This Helm chart is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/slauger/helm-charts).

## Maintainers

- Simon Lauger ([@slauger](https://github.com/slauger))
