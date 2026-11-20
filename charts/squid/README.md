# squid

Squid forward proxy for HTTP and HTTPS (CONNECT) with a domain allowlist, no cache and no
authentication. Meant as one small instance per use case, for example as the only egress of
a namespace whose NetworkPolicy allows nothing else.

- Image: [ubuntu/squid](https://hub.docker.com/r/ubuntu/squid) (Canonical rock, rebuilt with Ubuntu security updates)
- Runs as non-root with a read-only root filesystem, compatible with Pod Security `restricted`
- Access log on stdout, no disk cache

## Usage

```bash
helm install egress slauger/squid -n my-namespace \
  --set 'allowedDomains={.github.com,api.example.org}'
```

Clients use `http://egress-squid:3128` as `HTTP_PROXY` and `HTTPS_PROXY`.

## Access rules

In this order:

1. Clients outside `allowedClients` are denied.
2. Ports outside `allowedPorts` are denied; CONNECT only to `connectPorts` (empty disables CONNECT).
3. Destinations resolving to `privateDestinations` (private, loopback, link-local incl. cloud metadata, CGNAT) are denied while `denyPrivateDestinations` is true.
4. `extraConfig` is inserted here.
5. Domains in `allowedDomains` are allowed (`example.com` the host only, `.example.com` including subdomains).
6. Everything else is denied. An empty `allowedDomains` denies everything.

## NetworkPolicy

With `networkPolicy.enabled` (default) the proxy pod accepts connections on the proxy port
from all pods of its namespace (or the peers in `networkPolicy.from`) and may only reach DNS
in `kube-system` plus `allowedPorts` on public IPv4 addresses (`privateDestinations` are
excluded again on the network level).

Clients still need an egress rule to the proxy in their own policy.

## Image updates

The `_edge` tags of the rock move with every rebuild. Either pin `image.digest` (and let
Renovate update it) or set `image.pullPolicy: Always` so restarts pick up patched builds.

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `image.repository` | `ubuntu/squid` | Image |
| `image.tag` | appVersion | Image tag |
| `image.digest` | `""` | Optional digest pin |
| `replicaCount` | `1` | Replicas |
| `port` | `3128` | Proxy port (container and service) |
| `maxFiledescriptors` | `4096` | Upper bound for concurrent connections |
| `allowedDomains` | `[]` | Allowed destination domains |
| `allowedPorts` | `[80, 443]` | Allowed destination ports |
| `connectPorts` | `[443]` | Ports CONNECT may go to |
| `allowedClients` | RFC 1918, `fc00::/7` | Source networks allowed to use the proxy |
| `denyPrivateDestinations` | `true` | Deny destinations in `privateDestinations` |
| `privateDestinations` | private ranges | Denied destination networks |
| `extraConfig` | `""` | Additional squid.conf lines before the final deny |
| `networkPolicy.enabled` | `true` | Create a NetworkPolicy for the proxy pod |
| `networkPolicy.from` | `[]` | Ingress peers; empty means all pods of the namespace |
| `networkPolicy.dns` | kube-system, 53 | DNS egress |
| `networkPolicy.egressCIDR` | `0.0.0.0/0` | Egress range (minus private IPv4 destinations) |
| `resources` | 10m / 32Mi, limit 128Mi | Resources |
