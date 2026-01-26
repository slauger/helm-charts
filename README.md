# helm-charts

Collection of Helm charts for Kubernetes deployments.

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
