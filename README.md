# helm-charts

Collection of Helm charts for Kubernetes deployments.

## Usage

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

## Available Charts

### hcloud-registry

Docker Registry v2 with Hetzner Cloud S3 storage backend.

**Features:**
- Docker Registry v2.8.3
- Hetzner Cloud Object Storage as backend
- Basic authentication with htpasswd
- Ingress support with TLS
- Health checks and resource management

**Installation:**

```bash
helm install my-registry slauger/hcloud-registry \
  --set auth.htpasswd="BASE64_ENCODED_HTPASSWD" \
  --set storage.s3.bucket="my-bucket" \
  --set storage.s3.endpoint="https://fsn1.your-objectstorage.com" \
  --set storage.s3.accessKey="YOUR_KEY" \
  --set storage.s3.secretKey="YOUR_SECRET" \
  --set ingress.hosts[0].host="registry.example.com"
```

**Documentation:** [charts/hcloud-registry/README.md](charts/hcloud-registry/README.md)

### deployment-simple

Simple Kubernetes deployment chart.

### deployment

Generic deployment chart for Kubernetes applications.

### example-chart

Example Helm chart template.

### openshift-autoupdate

Automatic update controller for OpenShift.

### openshift-cacheclear

Cache clearing utility for OpenShift.

### openshift-ldap-sync

LDAP synchronization for OpenShift.

## Development

### Chart Structure

```
charts/
├── chart-name/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ...
│   └── README.md
```

### Linting

```bash
helm lint charts/chart-name
```

### Testing

```bash
# Template rendering
helm template my-release charts/chart-name

# Dry-run installation
helm install my-release charts/chart-name --dry-run --debug
```

## Publishing

Charts are automatically published to GitHub Pages when changes are pushed to the `main` branch. The workflow uses [chart-releaser-action](https://github.com/helm/chart-releaser-action) to:

1. Package charts
2. Create GitHub releases
3. Update the Helm repository index
4. Publish to GitHub Pages

**Requirements:**
- GitHub Pages must be enabled in repository settings
- Source: `gh-pages` branch

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your chart (`helm lint`, `helm template`)
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainer

- Simon Lauger ([@slauger](https://github.com/slauger))
  - Email: simon@lauger.de
  - Website: https://lauger.de
