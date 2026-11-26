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
- 🤖 **Dependency Updates** — Renovate keeps image tags, `appVersion` and GitHub Actions current and bumps the chart version with each update

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
| [openshift-virtualmachine](charts/openshift-virtualmachine/) | KubeVirt VirtualMachine and VirtualMachinePool resources for OpenShift Virtualization |
| [renovate-cronjob](charts/renovate-cronjob/) | Renovate bot as Kubernetes CronJob |
| [unifi](charts/unifi/) | UniFi Network Application with optional Multus LAN IP and cert-manager certificate |
| [iobroker](charts/iobroker/) | ioBroker with optional InfluxDB 1.x and Multus LAN IP |
| [lab-vm](charts/lab-vm/) | Opinionated KubeVirt VM with static LAN IP, cloud-init base setup and DNS record |
| [openshift-hostpath-provisioner](charts/openshift-hostpath-provisioner/) | Local dynamic storage on OpenShift via the KubeVirt HostPath Provisioner CSI driver |
| [squid](charts/squid/) | Squid forward proxy with domain allowlist and NetworkPolicy, one instance per use case |
| [eibtalio](charts/eibtalio/) | Eibtalio PMS, hotel management system with CloudNativePG database |
| [shelve](charts/shelve/) | Shelve, personal library management (FastAPI, React, CloudNativePG) |
| [example-chart](charts/example-chart/) | Example chart demonstrating common Kubernetes deployment patterns |

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

# Same check as the CI: lints all charts changed against main and requires a version bump
ct lint --config ct.yaml
```

Every change to a chart needs a new `version` in its `Chart.yaml`. The release workflow only publishes versions that have no release yet, and `ct lint` fails on pull requests that change a chart without bumping it.

### Testing

```bash
# Template rendering
helm template my-release charts/chart-name

# Dry-run installation
helm install my-release charts/chart-name --dry-run --debug
```

## Publishing

Charts are published automatically when changes are pushed to the `main` branch. The [release workflow](.github/workflows/release.yml):

1. Packages all charts
2. Creates a GitHub release `<chart>-<version>` with the chart package for every version that has no release yet (existing releases are never changed)
3. Builds the Helm repository index from the packages of all releases, so every released version stays installable
4. Force-pushes the `index.yaml` to the `gh-pages` branch, which GitHub Pages serves at https://slauger.github.io/helm-charts

**Requirements:**
- GitHub Pages enabled with source `Deploy from a branch`, branch `gh-pages`, folder `/`

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Bump the chart version and test your chart (`helm lint`, `helm template`, `ct lint`)
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainer

- Simon Lauger ([@slauger](https://github.com/slauger))
  - Email: simon@lauger.de
  - Website: https://lauger.de
