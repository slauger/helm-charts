# openshift-cacheclear

Scheduled cache clearing for OpenShift cluster nodes. This chart deploys a Kubernetes CronJob that periodically clears the page cache on all cluster nodes to free up memory and improve performance.

## Features

- **Automated Cache Clearing** - Executes `echo 3 > /proc/sys/vm/drop_caches` on all nodes
- **CronJob Scheduling** - Default daily execution at 4:00 AM
- **Concurrency Control** - Prevents overlapping cache clear jobs
- **Security Hardened** - Runs with minimal privileges and security context
- **Service Account Support** - Uses specified service account with node debugging permissions
- **ConfigMap-based Script** - Cache clearing script loaded from ConfigMap

## How It Works

The chart creates a CronJob that:

1. Lists all nodes in the cluster using `oc get nodes`
2. For each node, runs `oc debug node/<node>` to access the node
3. Executes `sync` to flush file system buffers
4. Writes `3` to `/proc/sys/vm/drop_caches` to clear:
   - Page cache
   - Dentries and inodes
   - All caches

This helps reclaim memory used by cached data that is no longer actively needed.

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Prerequisites

Before installing this chart, ensure you have:

1. **Service Account with Node Debugging Permissions** - The chart requires a service account that can debug nodes
2. **OpenShift Cluster** - This chart is designed for OpenShift clusters only

### Create Service Account (if needed)

```bash
oc create serviceaccount openshift-admin -n <namespace>
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-admin -n <namespace>
```

### Install Chart

```bash
helm install cache-clear slauger/openshift-cacheclear -n openshift-config
```

### Install with Custom Values

```bash
helm install cache-clear slauger/openshift-cacheclear -f values.yaml -n openshift-config
```

## Configuration

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `registry.redhat.io/openshift4/ose-cli` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `image.tag` | Image tag | `latest` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.name` | Service account name (uses release name if empty) | `openshift-admin` |

## CronJob Schedule

The default schedule runs the cache clear job daily at 4:00 AM:

```yaml
schedule: "0 4 * * *"
```

To customize the schedule, edit the chart's CronJob template or fork the chart.

### Common Cron Schedules

| Schedule | Description |
|----------|-------------|
| `0 4 * * *` | Daily at 4:00 AM (default) |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * 0` | Weekly on Sunday at midnight |
| `0 2 * * 1-5` | Weekdays at 2:00 AM |

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

## Cache Clearing Details

### What Gets Cleared

Writing `3` to `/proc/sys/vm/drop_caches` clears:

- **Page Cache** - File data cached in memory
- **Dentries** - Directory entry cache
- **Inodes** - File metadata cache

### Impact

- **Positive**: Frees up memory for applications
- **Temporary Performance Hit**: First access to cached files will be slower until re-cached
- **Non-Destructive**: No data loss, only caches are cleared

### When to Use

This is useful for:

- Memory-constrained clusters
- Debugging memory issues
- Performance testing
- Periodic cleanup maintenance

## Security

The CronJob runs with a hardened security context:

```yaml
securityContext:
  capabilities:
    drop:
      - "ALL"
  seccompProfile:
    type: "RuntimeDefault"
  allowPrivilegeEscalation: false
  runAsNonRoot: true
```

However, it requires cluster-admin permissions to debug nodes and access `/proc/sys/vm/drop_caches`.

## Monitoring

### View CronJob Status

```bash
kubectl get cronjob -n <namespace>
```

### View Recent Jobs

```bash
kubectl get jobs -n <namespace> | grep cache-clear
```

### View Job Logs

```bash
kubectl logs job/<job-name> -n <namespace>
```

### Manual Trigger

Manually trigger a cache clear job:

```bash
kubectl create job --from=cronjob/<cronjob-name> manual-cache-clear-$(date +%s) -n <namespace>
```

## Troubleshooting

### Job Fails with Permission Errors

Check the service account has cluster-admin permissions:

```bash
oc describe clusterrolebinding | grep <service-account-name>
```

### Image Pull Errors

If using Red Hat registry, ensure you have pull secrets configured:

```bash
oc get secret pull-secret -n openshift-config -o yaml
```

### Node Debug Fails

Ensure `oc debug` functionality is available:

```bash
oc debug node/<node-name>
```

## Script Details

The cache clearing script (`files/cache-clear.sh`):

```bash
#!/bin/bash
set -xe

for NODE in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo ${NODE}
  oc debug node/$NODE -- chroot /host/ bash -c "sync ; echo 3 > /proc/sys/vm/drop_caches"
done
```

## Resources Created

This chart creates the following Kubernetes resources:

- **CronJob** - Scheduled job for cache clearing
- **ConfigMap** - Contains the cache-clear.sh script

## Requirements

- OpenShift 4.x
- Kubernetes 1.19+
- Helm 3.0+
- Service account with cluster-admin or equivalent permissions

## Warnings

- **Production Use**: Test thoroughly before using in production
- **Performance Impact**: Cache clearing causes temporary performance degradation
- **Maintenance Windows**: Consider scheduling during low-traffic periods
- **Monitoring**: Monitor cluster performance after cache clearing

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
