# renovate-cronjob

Scheduled Renovate bot for automated dependency updates. This chart deploys Kubernetes CronJobs that run Renovate to automatically update dependencies in your GitHub, GitLab, or other Git repositories.

## Features

- **Multiple Jobs** - Configure separate CronJobs for different platforms or repository groups
- **GitHub Support** - Native GitHub integration
- **GitLab Support** - Support for GitLab.com and self-hosted GitLab instances
- **Flexible Scheduling** - Configure individual cron schedules per job
- **ConfigMap-based Configuration** - Renovate configuration via ConfigMaps
- **Secret Management** - Secure token storage in Kubernetes Secrets
- **Namespace Management** - Creates dedicated `renovate` namespace
- **Job Control** - Enable/disable individual jobs without removing them

## What is Renovate?

Renovate is an automated dependency update tool that:
- Detects outdated dependencies in your projects
- Creates pull/merge requests with updates
- Supports multiple languages and package managers
- Maintains changelogs and release notes
- Can auto-merge based on configured rules

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Prerequisites

Before installing this chart, you need to create secrets containing access tokens for your Git platforms.

#### Create GitHub Token Secret

```bash
kubectl create namespace renovate
kubectl create secret generic github-credentials \
  --from-literal=password=ghp_your_github_token_here \
  -n renovate
```

#### Create GitLab Token Secret

```bash
kubectl create secret generic gitlab-credentials \
  --from-literal=password=glpat-your_gitlab_token_here \
  -n renovate
```

### Install Chart

```bash
helm install renovate slauger/renovate-cronjob -n renovate
```

### Install with Custom Values

```bash
helm install renovate slauger/renovate-cronjob -f values.yaml -n renovate
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Renovate container image | `docker.io/renovate/renovate:latest` |
| `serviceaccount` | Optional service account name | `""` |

### Job Configuration

Each job in the `jobs` array supports the following parameters:

| Parameter | Description | Required |
|-----------|-------------|----------|
| `name` | Job identifier (must be unique) | Yes |
| `secretName` | Name of secret containing access token | Yes |
| `configName` | ConfigMap key for Renovate config | Yes |
| `schedule` | Cron schedule expression | Yes |
| `enabled` | Enable or disable the job | Yes |
| `platform` | Git platform (github, gitlab, etc.) | No (defaults to github) |
| `repositories` | List of repositories to process | Yes |

## Examples

### GitHub Example

```yaml
image: docker.io/renovate/renovate:latest

jobs:
  - name: github-repos
    secretName: github-credentials
    configName: config-github.js
    schedule: "0 2 * * *"  # Daily at 2 AM
    enabled: true
    platform: github
    repositories:
      - myorg/frontend
      - myorg/backend
      - myorg/infrastructure
```

### GitLab Self-Hosted Example

```yaml
jobs:
  - name: gitlab-selfhosted
    secretName: gitlab-selfhosted-credentials
    configName: config-gitlab.js
    schedule: "0 3 * * 1-5"  # Weekdays at 3 AM
    enabled: true
    platform: gitlab
    repositories:
      - group/project1
      - group/project2
```

### Multiple Jobs Example

```yaml
jobs:
  # GitHub public repos
  - name: github-public
    secretName: github-credentials
    configName: config-github.js
    schedule: "0 2 * * *"
    enabled: true
    repositories:
      - myorg/public-repo1
      - myorg/public-repo2

  # GitLab private repos
  - name: gitlab-private
    secretName: gitlab-credentials
    configName: config-gitlab.js
    schedule: "0 4 * * *"
    enabled: true
    platform: gitlab
    repositories:
      - private-group/app1
      - private-group/app2

  # Disabled job for testing
  - name: test-repos
    secretName: github-credentials
    configName: config-github.js
    schedule: "0 0 * * 0"
    enabled: false
    repositories:
      - myorg/test-repo
```

## Renovate Configuration

The chart includes default Renovate configurations in the ConfigMap:

### GitHub Configuration (`config-github.js`)

```javascript
module.exports = {
  "platform": "github",
  "extends": [
    "config:recommended"
  ],
  "timezone": "Europe/Berlin",
  "automerge": false,
  "labels": ["dependencies"]
}
```

### GitLab Configuration (`config-gitlab.js`)

```javascript
module.exports = {
  "platform": "gitlab",
  "endpoint": "https://gitlab.example.com/api/v4/",
  "extends": [
    "config:recommended"
  ],
  "timezone": "Europe/Berlin",
  "automerge": false,
  "labels": ["dependencies"]
}
```

### Customizing Renovate Configuration

To customize Renovate's behavior, modify the `templates/configmap.yaml` file with your desired configuration. Common options:

- **Automerge**: `"automerge": true` - Automatically merge updates
- **Schedule**: `"schedule": ["after 10pm", "before 5am"]` - When to create PRs
- **Assignees**: `"assignees": ["username"]` - Auto-assign reviewers
- **Labels**: `"labels": ["renovate", "dependencies"]` - PR labels
- **Semantic Commits**: `"semanticCommits": "enabled"` - Use conventional commits

See [Renovate Docs](https://docs.renovatebot.com/configuration-options/) for all options.

## Cron Schedule Examples

| Schedule | Description |
|----------|-------------|
| `0 2 * * *` | Daily at 2:00 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * 0` | Weekly on Sunday at midnight |
| `0 3 * * 1-5` | Weekdays at 3:00 AM |
| `0 4 1 * *` | Monthly on the 1st at 4:00 AM |
| `*/30 * * * *` | Every 30 minutes |

## Token Permissions

### GitHub Token

Required permissions:
- **repo** - Full control of private repositories
- **workflow** - Update GitHub Action workflows

Create a Personal Access Token or GitHub App token with these scopes.

### GitLab Token

Required permissions:
- **api** - Full API access
- **write_repository** - Write to repositories

Create a Project Access Token or Personal Access Token with these scopes.

## Monitoring

### View CronJob Status

```bash
kubectl get cronjob -n renovate
```

### View Recent Jobs

```bash
kubectl get jobs -n renovate
```

### View Job Logs

```bash
# List recent job pods
kubectl get pods -n renovate

# View logs
kubectl logs <pod-name> -n renovate
```

### Manual Trigger

Manually trigger a Renovate job:

```bash
kubectl create job --from=cronjob/renovate-cronjob-github-example manual-run-$(date +%s) -n renovate
```

## Troubleshooting

### Authentication Errors

Verify the secret contains the correct token:

```bash
kubectl get secret github-credentials -n renovate -o jsonpath='{.data.password}' | base64 -d
```

### No Pull Requests Created

Check the job logs for errors:

```bash
kubectl logs -l job-name=<job-name> -n renovate
```

Common issues:
- Token lacks required permissions
- Repository list format incorrect
- Renovate configuration syntax errors
- No outdated dependencies found

### Job Not Running

Verify the CronJob is not suspended:

```bash
kubectl get cronjob -n renovate -o yaml | grep suspend
```

If `suspend: true`, the job is disabled. Set `enabled: true` in values.yaml.

### Rate Limiting

GitHub API rate limits may affect frequent runs. Consider:
- Reducing schedule frequency
- Using GitHub App tokens (higher limits)
- Splitting repositories across multiple jobs

## Environment Variables

The chart automatically sets these environment variables:

- `RENOVATE_TOKEN` - Git platform access token (from secret)
- `GITHUB_COM_TOKEN` - GitHub token for fetching public configs (from github-credentials secret)
- `RENOVATE_REPOSITORIES` - Comma-separated list of repositories
- `LOG_LEVEL` - Set to `debug` for verbose logging

## Resources Created

This chart creates the following Kubernetes resources:

- **Namespace** - Dedicated `renovate` namespace
- **CronJob** - One per job configuration
- **ConfigMap** - Renovate configuration per job

The chart does **not** create Secrets - you must create them manually before installation.

## Security Considerations

- **Token Security**: Store tokens in Kubernetes Secrets, never in values.yaml
- **Least Privilege**: Use tokens with minimum required permissions
- **Network Policies**: Consider restricting egress to Git platform APIs only
- **Token Rotation**: Regularly rotate access tokens
- **Audit Logs**: Monitor Renovate activity via job logs

## Requirements

- Kubernetes 1.19+
- Helm 3.0+
- Access tokens for GitHub/GitLab with appropriate permissions

## Advanced Configuration

### Using Shared Renovate Config

Reference a shared configuration preset:

```javascript
module.exports = {
  "platform": "github",
  "extends": [
    "github>myorg/renovate-config"
  ]
}
```

### Adding Assignees

```javascript
module.exports = {
  "platform": "github",
  "extends": ["config:recommended"],
  "assignees": ["username1", "username2"]
}
```

### Enabling Automerge

```javascript
module.exports = {
  "platform": "github",
  "extends": ["config:recommended"],
  "automerge": true,
  "automergeType": "pr",
  "automergeStrategy": "squash"
}
```

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
- <https://github.com/renovatebot/renovate>

## References

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Renovate Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Renovate Presets](https://docs.renovatebot.com/presets/)
