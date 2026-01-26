# openshift-ldap-sync

Automated LDAP/Active Directory group synchronization for OpenShift. This chart deploys a Kubernetes CronJob that periodically synchronizes LDAP/AD groups and users to OpenShift, enabling centralized identity management and RBAC.

## Features

- **Automated LDAP Sync** - Periodic synchronization of LDAP/AD groups to OpenShift
- **Augmented Active Directory Support** - Optimized for Active Directory environments
- **Whitelist/Blacklist Support** - Control which groups to synchronize
- **CronJob Scheduling** - Default sync every 15 minutes
- **RBAC Management** - Automatic creation of necessary ClusterRole and ClusterRoleBinding
- **Service Account** - Dedicated service account with group management permissions
- **TLS/SSL Support** - Optional CA bundle for secure LDAP connections
- **Secure Credentials** - LDAP bind password stored in Kubernetes Secret

## How It Works

The chart creates a CronJob that:

1. Connects to your LDAP/Active Directory server
2. Queries for groups based on the configured base DN
3. Filters groups using whitelist or blacklist
4. Creates or updates corresponding OpenShift groups
5. Syncs group memberships to OpenShift users

This enables you to manage user permissions centrally in LDAP/AD and have them automatically reflected in OpenShift.

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Prerequisites

Before installing this chart, ensure you have:

1. **LDAP/Active Directory Server** - Accessible from the cluster
2. **LDAP Bind Account** - Service account with read access to users and groups
3. **OpenShift Cluster** - This chart is designed for OpenShift only

### Install Chart

```bash
helm install ldap-sync slauger/openshift-ldap-sync \
  --set params.url="ldaps://ldap.example.com:636" \
  --set params.bindDN="CN=bind-user,OU=Service Accounts,DC=example,DC=com" \
  --set params.bindPassword="your-password" \
  --set params.baseDN="DC=example,DC=com" \
  --set whitelist="cn=admins,ou=groups,dc=example,dc=com" \
  -n openshift-authentication
```

### Install with Custom Values

Create a `values.yaml` file:

```yaml
params:
  url: "ldaps://ldap.example.com:636"
  bindDN: "CN=sync-user,OU=Service Accounts,DC=example,DC=com"
  bindPassword: "SecurePassword123"
  baseDN: "DC=example,DC=com"

mode: "whitelist"

whitelist: |
  cn=cluster-admins,ou=groups,dc=example,dc=com
  cn=developers,ou=groups,dc=example,dc=com
  cn=viewers,ou=groups,dc=example,dc=com
```

Then install:

```bash
helm install ldap-sync slauger/openshift-ldap-sync -f values.yaml -n openshift-authentication
```

## Configuration

### LDAP Connection Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `params.url` | LDAP server URL (ldaps://host:636 or ldap://host:389) | Yes |
| `params.bindDN` | DN of the bind user | Yes |
| `params.bindPassword` | Password for the bind user | Yes |
| `params.baseDN` | Base DN for searches | Yes |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `image-registry.openshift-image-registry.svc:5000/openshift/cli` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `image.tag` | Image tag | `latest` |

### Synchronization Mode

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mode` | Sync mode: "whitelist" or "blacklist" | `whitelist` |
| `whitelist` | List of group DNs to sync (one per line) | `cn=foo,cn=bar` |

### RBAC and Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Create ClusterRole and ClusterRoleBinding | `true` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name (generated if empty) | `""` |
| `serviceAccount.annotations` | Service account annotations | `{}` |

### TLS/SSL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cabundle` | CA certificate bundle for LDAP server | `""` |

## CronJob Schedule

The default schedule syncs groups every 15 minutes:

```yaml
schedule: "*/15 * * * *"
```

To customize the schedule, edit the chart's CronJob template or fork the chart.

### Common Cron Schedules

| Schedule | Description |
|----------|-------------|
| `*/15 * * * *` | Every 15 minutes (default) |
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour |
| `0 */6 * * *` | Every 6 hours |

## Examples

### Active Directory with Whitelist

```yaml
params:
  url: "ldaps://ad.corp.example.com:636"
  bindDN: "CN=openshift-sync,OU=Service Accounts,DC=corp,DC=example,DC=com"
  bindPassword: "SecurePassword123"
  baseDN: "DC=corp,DC=example,DC=com"

mode: "whitelist"

whitelist: |
  CN=OpenShift-Admins,OU=Groups,DC=corp,DC=example,DC=com
  CN=OpenShift-Developers,OU=Groups,DC=corp,DC=example,DC=com
  CN=OpenShift-Viewers,OU=Groups,DC=corp,DC=example,DC=com
```

### With Custom CA Bundle

```yaml
params:
  url: "ldaps://ldap.example.com:636"
  bindDN: "cn=sync-user,ou=service,dc=example,dc=com"
  bindPassword: "password"
  baseDN: "dc=example,dc=com"

cabundle: |
  -----BEGIN CERTIFICATE-----
  MIIDXTCCAkWgAwIBAgIJAKJ5...
  ...
  -----END CERTIFICATE-----
```

### With Custom Service Account

```yaml
serviceAccount:
  create: false
  name: custom-ldap-sync-sa

rbac:
  create: false
```

## RBAC Permissions

The chart creates a ClusterRole with the following permissions:

```yaml
rules:
  - apiGroups:
      - ''
      - user.openshift.io
    resources:
      - groups
    verbs:
      - get
      - list
      - create
      - update
```

This allows the sync job to manage OpenShift group objects.

## Monitoring

### View CronJob Status

```bash
kubectl get cronjob -n openshift-authentication
```

### View Recent Sync Jobs

```bash
kubectl get jobs -n openshift-authentication | grep ldap-group-sync
```

### View Sync Job Logs

```bash
kubectl logs job/<job-name> -n openshift-authentication
```

### Check Synced Groups

```bash
oc get groups
```

### Manual Trigger

Manually trigger a sync job:

```bash
kubectl create job --from=cronjob/<cronjob-name> manual-ldap-sync-$(date +%s) -n openshift-authentication
```

## Troubleshooting

### Connection Issues

Test LDAP connection from within the cluster:

```bash
oc run ldap-test --image=image-registry.openshift-image-registry.svc:5000/openshift/cli --restart=Never -- \
  ldapsearch -H ldaps://ldap.example.com:636 -D "CN=bind-user,DC=example,DC=com" -w "password" -b "DC=example,DC=com"
```

### Certificate Errors

If using self-signed certificates, ensure the CA bundle is configured:

```yaml
cabundle: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----
```

### Permission Errors

Verify the service account has the necessary permissions:

```bash
oc describe clusterrolebinding | grep ldap-group-sync
```

### No Groups Syncing

Check the whitelist configuration matches your LDAP group DNs exactly:

```bash
# View job logs
kubectl logs job/<job-name> -n openshift-authentication

# Verify LDAP group DNs
ldapsearch -H ldaps://ldap.example.com:636 -D "CN=bind,DC=example,DC=com" -w "password" \
  -b "DC=example,DC=com" "(objectClass=group)" dn
```

## LDAP Sync Configuration

The chart uses the Augmented Active Directory schema with the following defaults:

- **Group UID Attribute**: `dn`
- **Group Name Attributes**: `sAMAccountName`
- **User Name Attributes**: `sAMAccountName`
- **Group Membership Attributes**: `memberOf`
- **User Filter**: `(objectclass=person)`

These settings work well for Active Directory. For other LDAP servers, you may need to customize the `config.yaml` template.

## Resources Created

This chart creates the following Kubernetes resources:

- **CronJob** - Scheduled LDAP sync job
- **ConfigMap** - LDAP sync configuration and whitelist
- **ConfigMap** - CA bundle (if configured)
- **Secret** - LDAP bind password
- **ServiceAccount** - Dedicated service account (if enabled)
- **ClusterRole** - Group management permissions (if enabled)
- **ClusterRoleBinding** - Binds ClusterRole to ServiceAccount (if enabled)

## Security Considerations

- **Secure Password Storage**: Bind password is stored in a Kubernetes Secret
- **TLS Connections**: Always use `ldaps://` in production
- **Least Privilege**: Bind account should have read-only access to LDAP
- **Network Policies**: Consider restricting egress to LDAP server only
- **Secret Rotation**: Regularly rotate the bind account password

## Requirements

- OpenShift 4.x
- Kubernetes 1.19+
- Helm 3.0+
- LDAP/Active Directory server accessible from the cluster

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>

## References

- [OpenShift LDAP Group Sync Documentation](https://docs.openshift.com/container-platform/latest/authentication/ldap-syncing.html)
