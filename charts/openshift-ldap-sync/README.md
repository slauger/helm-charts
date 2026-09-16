# openshift-ldap-sync

Automated LDAP/Active Directory group synchronization for OpenShift

The connection settings are not configured twice: the sync job reads the LDAP
identity provider from the cluster wide `OAuth` resource and derives URL, base
DN, bind DN, bind password and CA bundle from it. The only thing left to
configure is which groups to sync.

## How It Works

The CronJob runs `oc adm groups sync` and, before that, resolves its
configuration:

1. Read `spec.identityProviders[]` of `oauth/cluster`, select the entry named
   `ldap` and verify that it is of type `LDAP`
2. Split its `ldap.url`, which follows RFC 4516:

   ```
   ldaps://lan.example.corp.int:636/dc=foo,dc=bar,dc=de?sAMAccountName?sub?(objectClass=user)
   \_____________________________/ \_________________/ \____________/ \_/ \________________/
                 url                      baseDN           attribute  scope      filter
   ```

3. Read the bind password from the secret and the CA bundle from the config map
   that `ldap.bindPassword` and `ldap.ca` reference
4. Write the resulting `LDAPSyncConfig` and sync the groups of the whitelist

Resolving happens inside the job, not while rendering the chart. This keeps the
chart usable with `helm template` and Argo CD, and a change of the identity
provider is picked up on the next run without a redeploy.

The identity provider only describes the user side of the directory, it knows
nothing about groups. `groupUIDAttribute`, `groupNameAttributes`,
`groupMembershipAttributes` and the group query therefore default to Active
Directory conventions and can be overridden through the values below.

## Installation

```bash
helm repo add slauger https://slauger.github.io/helm-charts

helm install ldap-sync slauger/openshift-ldap-sync -n openshift-config \
  --set whitelist="CN=OpenShift-Admins,OU=Groups,DC=corp,DC=example,DC=com"
```

Every object carries an explicit `metadata.namespace`, taken from the
`namespace` value and not from `.Release.Namespace`. `helm template` without
`-n` would otherwise fall back to the namespace of the current kubectl context,
which leaves the role bindings pointing at a service account that does not
exist there. Install the release into the same namespace the value names.

## Permissions

The service account created by the chart gets

- `get`, `list`, `create` and `update` on `groups.user.openshift.io`,
- `get` on the `OAuth` resource named in `oauth.name`, and
- `get` on secrets and config maps in `oauth.configNamespace`.

The last one also covers the credentials of the other identity providers in
`openshift-config`. To avoid it, set `rbac.create: false`, bind your own role
and pass `params.bindDN`, `params.bindPassword` and `cabundle` instead.

## Troubleshooting

The job logs the generated `LDAPSyncConfig` before it starts syncing, which
shows what was derived from the identity provider. If it aborts because the
identity provider was not found, check the name:

```bash
oc get oauth cluster -o jsonpath='{range .spec.identityProviders[*]}{.name}{"\t"}{.type}{"\n"}{end}'
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| blacklist | string | `""` | Group DNs to skip, one per line, used with `mode: blacklist` |
| cabundle | string | the config map the identity provider references | CA certificate of the LDAP server |
| image.pullPolicy | string | `"Always"` | Image pull policy |
| image.repository | string | `"image-registry.openshift-image-registry.svc:5000/openshift/cli"` | Container image repository |
| image.tag | string | `"latest"` | Image tag |
| ldap.groupMembershipAttributes | string | `"memberOf"` | Attribute holding the group membership |
| ldap.groupNameAttributes | string | `"sAMAccountName"` | Attribute the OpenShift group is named after |
| ldap.groupUIDAttribute | string | `"dn"` | Attribute used as group UID |
| ldap.groupsFilter | string | `""` | Additional filter of the group query |
| ldap.pageSize | int | `0` | Page size of the LDAP queries, `0` disables paging |
| ldap.scope | string | scope of the identity provider URL, `sub` if it carries none | Search scope |
| ldap.userNameAttributes | string | attribute of the identity provider URL, `sAMAccountName` if it carries none | Attribute the OpenShift user is named after |
| ldap.usersFilter | string | filter of the identity provider URL, `(objectclass=person)` if it carries none | Filter of the user query |
| mode | string | `"whitelist"` | Sync mode, either `whitelist` or `blacklist` |
| namespace | string | `"openshift-config"` | Namespace all objects are created in |
| oauth.configNamespace | string | `"openshift-config"` | Namespace holding the bind password secret and the CA config map the identity provider references |
| oauth.identityProvider | string | `"ldap"` | Name of the entry in `spec.identityProviders` the connection settings are read from |
| oauth.name | string | `"cluster"` | Name of the OAuth resource |
| params.bindDN | string | `ldap.bindDN` of the identity provider | DN of the bind user |
| params.bindPassword | string | the secret the identity provider references | Password of the bind user, stored in a secret |
| params.groupsBaseDN | string | base DN of the identity provider URL | Base DN of the group query |
| params.usersBaseDN | string | base DN of the identity provider URL | Base DN of the user query |
| rbac.create | bool | `true` | Create ClusterRole, ClusterRoleBinding, Role and RoleBinding |
| schedule | string | `"42 * * * *"` | Cron schedule of the sync job |
| serviceAccount.annotations | object | `{}` | Annotations of the service account |
| serviceAccount.create | bool | `true` | Create the service account |
| serviceAccount.name | string | the release name | Name of the service account |
| whitelist | string | `"cn=foo,cn=bar\n"` | Group DNs to sync, one per line, used with `mode: whitelist` |

## Requirements

- OpenShift 4.x with an identity provider of type `LDAP`
- Helm 3.0+

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Simon Lauger | <simon@lauger.de> |  |

## Source Code

* <https://github.com/slauger/helm-charts>

## References

- [OpenShift LDAP Group Sync Documentation](https://docs.openshift.com/container-platform/latest/authentication/ldap-syncing.html)
