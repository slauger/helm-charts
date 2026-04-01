# helm-charts

Collection of Helm charts for Kubernetes deployments.

## ✨ Features

- 📦 **Ready-to-use Charts** — Generic, reusable Helm charts for common Kubernetes patterns
- 🔐 **TLS Certificate Management** — Declarative cert-manager Certificate resources via `certificate` chart
- 🌐 **DNS Record Management** — Declarative ExternalDNS DNSEndpoint resources via `dns-endpoint` chart
- 🚀 **Flexible Deployments** — Simple and advanced deployment charts with HPA, services, and ingress
- 🏗️ **Hugo Static Sites** — Production-ready Hugo sites served with nginx
- ☁️ **Hetzner Cloud Integration** — Private Docker registry with Hetzner S3 backend
- 🔄 **Automated Publishing** — Charts are automatically packaged and published via GitHub Actions
- 📋 **Helm Repository** — Hosted on GitHub Pages, ready to add with `helm repo add`

## Available Charts

| Chart | Description |
|-------|-------------|
| [certificate](charts/certificate/) | Generic cert-manager Certificate resources |
| [dns-endpoint](charts/dns-endpoint/) | Generic ExternalDNS DNSEndpoint resources |
| [deployment](charts/deployment/) | Kubernetes Deployment with service, ingress, and HPA |
| [deployment-simple](charts/deployment-simple/) | Simplified Kubernetes Deployment |
| [hugo-nginx](charts/hugo-nginx/) | Hugo static site served with nginx |
| [hcloud-registry](charts/hcloud-registry/) | Private Docker registry with Hetzner S3 backend |
| [openshift-autoupdate](charts/openshift-autoupdate/) | OpenShift automatic update CronJob |
| [openshift-cacheclear](charts/openshift-cacheclear/) | OpenShift cache clearing CronJob |
| [openshift-ldap-sync](charts/openshift-ldap-sync/) | OpenShift LDAP synchronization CronJob |
| [renovate-cronjob](charts/renovate-cronjob/) | Renovate bot as Kubernetes CronJob |

## Usage

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Search Charts

```bash
helm search repo slauger
```

### Install a Chart

```bash
helm install my-release slauger/<chart-name>
```

See individual chart directories in [charts/](charts/) for detailed documentation.

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

Charts are automatically published to GitHub Pages when changes are pushed to the `main` branch. The workflow:

1. Packages Helm charts
2. Creates GitHub releases with chart packages
3. Generates Helm repository index
4. Deploys to GitHub Pages via artifacts (no branch needed)

**Requirements:**
- GitHub Pages must be enabled in repository settings
- Source: `GitHub Actions`

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
