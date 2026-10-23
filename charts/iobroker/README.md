# iobroker

ioBroker smart home platform based on the official image [buanet/iobroker](https://github.com/buanet/ioBroker.docker), optionally with its own LAN IP (Multus) and an InfluxDB 1.x for the influxdb adapter.

## Features

- **StatefulSet** - single instance; the pod name (`<fullname>-0`) is the ioBroker hostname
- **Persistent `/opt/iobroker`** - js-controller, adapters, objects/states and backups live on the volume; the image only provides Debian and Node.js
- **LAN IP via Multus** - bridge CNI with a single fixed address and MAC, required for adapters contacted by devices (shelly MQTT/CoAP, sonos) or using multicast (yahka/HomeKit mDNS, discovery)
- **Debian packages** - `packages` is passed as `PACKAGES` and installed on every new container (defaults: OS dependencies of yahka)
- **InfluxDB 1.x** - optional second StatefulSet, reachable as `<fullname>-influxdb:8086`
- **Ingress** - optional, for the admin UI (port 8081)
- **Health** - liveness uses the image's `healthcheck.sh`, so the maintenance mode (`maint on`) does not restart the pod

## Installation

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm install iobroker slauger/iobroker -n iobroker --create-namespace \
  --set lan.enabled=true,lan.subnet=10.0.0.0/23,lan.address=10.0.0.4,lan.mac=02:00:00:00:00:04 \
  --set influxdb.enabled=true \
  --set ingress.enabled=true,ingress.host=iobroker.example.com
```

## Configuration

| Key | Default | Description |
|-----|---------|-------------|
| `image.repository` / `image.tag` | `buanet/iobroker` / appVersion | Image |
| `timezone` | `Europe/Berlin` | `TZ` |
| `packages` | yahka dependencies | Debian packages (`PACKAGES`) |
| `extraEnv` | `[]` | Additional environment variables |
| `persistence.size` | `10Gi` | Volume for `/opt/iobroker` |
| `lan.enabled` | `false` | Attach to the LAN via Multus |
| `lan.subnet` / `lan.address` / `lan.mac` | `""` | LAN subnet, fixed address and MAC |
| `lan.bridge` | `br0` | Host bridge |
| `service.ports.admin` / `.web` | `8081` / `8082` | ClusterIP service ports |
| `ingress.enabled` / `ingress.host` | `false` / `""` | Ingress for the admin UI |
| `influxdb.enabled` | `false` | Deploy InfluxDB 1.x |
| `influxdb.persistence.size` | `5Gi` | InfluxDB volume |

## Operations

### Run commands as the iobroker user

`gosu` (used by the image) spins at 100% CPU when started through `kubectl exec` on some hosts. Use `setpriv` instead:

```bash
kubectl -n iobroker exec iobroker-0 -- \
  setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/opt/iobroker \
  iob list instances </dev/null
```

`iob start|stop|restart` is blocked inside the image; use the maintenance script (as user iobroker):

```bash
... maint on -y    # stop ioBroker, container keeps running (pod stays healthy)
... maint off -y   # leave maintenance; the container exits and Kubernetes restarts it
```

### Restore a backup from another host

1. Copy the backitup archive (`*_backupiobroker.tar.gz`) to `/opt/iobroker/backups/` and `chown iobroker:iobroker` it.
2. `maint on -y`
3. `iob restore /opt/iobroker/backups/<file> [--force]` - `--force` is needed if the js-controller version differs; adapters are reinstalled in the versions of the backup, upgrade them afterwards (`iob upgrade -y`).
4. `maint off -y` - on start the image renames the ioBroker host to the pod name.

backitup does not include `iobroker-data/<adapter>.hapdata` (yahka pairing keys); copy that directory separately.

### Editing the jsonl databases offline

`iobroker-data/objects.jsonl` and `states.jsonl` are append-only logs (`{"k":"<id>","v":{...}}`, deletion = `{"k":"<id>"}`). The loader matches the exact prefix `{"k":"`, so records written by hand must be compact JSON without spaces. Only edit while ioBroker is stopped (`maint on`).
