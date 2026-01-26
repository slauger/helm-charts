# openshift-autoupdate

Automated OpenShift cluster upgrade via scheduled CronJob. This chart deploys a Kubernetes CronJob that automatically upgrades an OpenShift cluster to the latest available version using the `oc adm upgrade` command.

## Features

- **Automated Upgrades** - Runs `oc adm upgrade --to-latest=true` on a schedule
- **CronJob Scheduling** - Default daily execution at 4:00 AM
- **Concurrency Control** - Prevents overlapping upgrade jobs
- **Service Account Support** - Uses specified service account with cluster-admin permissions
- **Configurable Container Image** - Uses OpenShift CLI image from internal registry

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Prerequisites

Before installing this chart, ensure you have:

1. **Service Account with Cluster Admin Permissions** - The chart requires a service account with sufficient permissions to upgrade the cluster
2. **OpenShift Cluster** - This chart is designed for OpenShift clusters only

### Create Service Account (if needed)

```bash
oc create serviceaccount openshift-admin -n <namespace>
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-admin -n <namespace>
```

### Install Chart

```bash
helm install auto-upgrade slauger/openshift-autoupdate -n openshift-config
```

### Install with Custom Values

```bash
helm install auto-upgrade slauger/openshift-autoupdate -f values.yaml -n openshift-config
```

## Configuration

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `image-registry.openshift-image-registry.svc:5000/openshift/cli` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `image.tag` | Image tag | `latest` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.name` | Service account name (uses release name if empty) | `openshift-admin` |

## CronJob Schedule

The default schedule runs the upgrade job daily at 4:00 AM:

```yaml
schedule: "0 4 * * *"
```

To customize the schedule, edit the chart's CronJob template or fork the chart.

### Common Cron Schedules

| Schedule | Description |
|----------|-------------|
| `0 4 * * *` | Daily at 4:00 AM (default) |
| `0 2 * * 0` | Weekly on Sunday at 2:00 AM |
| `0 3 1 * *` | Monthly on the 1st at 3:00 AM |
| `0 0 * * 1-5` | Weekdays at midnight |

## Examples

### Use Custom Service Account

```yaml
serviceAccount:
  name: my-admin-account
```

### Use Different OpenShift CLI Image

```yaml
image:
  repository: quay.io/openshift/origin-cli
  tag: "4.14"
  pullPolicy: IfNotPresent
```

## How It Works

This chart creates a CronJob that:

1. Runs according to the configured schedule (default: daily at 4:00 AM)
2. Spins up a pod with the OpenShift CLI (`oc`) image
3. Executes `oc adm upgrade --to-latest=true`
4. Terminates the pod after completion or failure

### Job Configuration

- **Concurrency Policy**: `Forbid` - Only one upgrade job can run at a time
- **Backoff Limit**: `0` - No retries on failure
- **Active Deadline**: `500 seconds` - Job timeout
- **Restart Policy**: `Never` - Pod does not restart on failure

## Security Considerations

**WARNING**: This chart grants cluster-admin permissions and automatically upgrades your cluster. Use with caution:

- Only deploy in non-production clusters or with careful planning
- Consider using a specific version tag instead of `latest`
- Review OpenShift upgrade schedules and maintenance windows
- Monitor upgrade jobs and cluster health after automated upgrades
- Consider implementing additional approval gates for production clusters

## Monitoring

### View CronJob Status

```bash
kubectl get cronjob -n <namespace>
```

### View Recent Jobs

```bash
kubectl get jobs -n <namespace> | grep auto-update
```

### View Job Logs

```bash
kubectl logs job/<job-name> -n <namespace>
```

### Manual Trigger

Manually trigger an upgrade job:

```bash
kubectl create job --from=cronjob/<cronjob-name> manual-upgrade-$(date +%s) -n <namespace>
```

## Troubleshooting

### Job Fails Immediately

Check the service account has cluster-admin permissions:

```bash
oc describe clusterrolebinding | grep <service-account-name>
```

### Image Pull Errors

Ensure the namespace has access to the internal registry:

```bash
oc policy add-role-to-user system:image-puller system:serviceaccount:<namespace>:<service-account> -n openshift
```

### Upgrade Command Fails

Check the OpenShift cluster upgrade status manually:

```bash
oc adm upgrade
```

## Resources Created

This chart creates the following Kubernetes resources:

- **CronJob** - Scheduled job for cluster upgrades

## Requirements

- OpenShift 4.x
- Kubernetes 1.19+
- Helm 3.0+
- Service account with cluster-admin permissions

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
