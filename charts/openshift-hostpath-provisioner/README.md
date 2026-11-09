# openshift-hostpath-provisioner

Local dynamic storage on OpenShift via the KubeVirt HostPath Provisioner (HPP) CSI driver. This chart deploys only the resources that sit on top of an already-installed HPP operator: the `HostPathProvisioner` custom resource, one or more `StorageClass` objects, an optional `MachineConfig` that prepares the node directory, and an optional verification pod. It does not install the operator, a subscription, cert-manager, or the CSI driver.

## Features

- **Dynamic local storage** - Provisions PVs as subdirectories on the node filesystem; no dedicated disk or partition required
- **Unprivileged workloads** - Workload pods consume a normal CSI volume and run under `restricted-v2`; only the operator-managed CSI DaemonSet touches the host
- **Configurable storage pools** - Basic pools or `pvcTemplate` pools, each exposed through its own StorageClass
- **RHCOS-ready directory prep** - Optional MachineConfig creates the pool path and sets the SELinux context persistently
- **Built-in verification** - Optional PVC and unprivileged pod to confirm the end-to-end path

## Warning: storage on the RHCOS root disk

With a basic storage pool the path (default `/var/hpvolumes`) lives on the RHCOS root disk, shared with the OS, etcd, container images, and logs. Red Hat advises against placing the storage pool on the OS partition: if it fills up, the node can become unstable or unusable. This setup is fine for testing and PoC with monitored usage. For anything durable, attach a dedicated disk and prefer LVM Storage (LVMS), or point a `pvcTemplate` pool at a block-backed StorageClass.

## Prerequisites

This chart assumes the HPP operator and CSI driver are already present. Install the operator first by one of:

1. **OpenShift Virtualization (CNV)** - The HPP operator ships with CNV via OLM. Set the release namespace to `openshift-cnv`.
2. **Standalone upstream operator** - Requires cert-manager, then the operator manifests (see the [kubevirt/hostpath-provisioner-operator](https://github.com/kubevirt/hostpath-provisioner-operator) project). Use namespace `hostpath-provisioner`.

Verify the driver is available before installing this chart:

```bash
oc get csidriver kubevirt.io.hostpath-provisioner
```

## Installation

### Add Helm Repository

```bash
helm repo add slauger https://slauger.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
# Standalone operator
helm install hpp slauger/openshift-hostpath-provisioner -n hostpath-provisioner

# With OpenShift Virtualization (CNV)
helm install hpp slauger/openshift-hostpath-provisioner -n openshift-cnv
```

The `MachineConfig` (enabled by default) triggers a rolling node reboot via the Machine Config Operator. Watch progress with `oc get mcp -w`.

## Configuration

### HostPathProvisioner

| Parameter | Description | Default |
|-----------|-------------|---------|
| `hostPathProvisioner.enabled` | Render the HostPathProvisioner CR | `true` |
| `hostPathProvisioner.name` | Name of the CR | `hostpath-provisioner` |
| `hostPathProvisioner.imagePullPolicy` | Image pull policy for the provisioner | `IfNotPresent` |
| `hostPathProvisioner.storagePools` | List of storage pools (`name`, `path`, optional `pvcTemplate`) | one `local` pool at `/var/hpvolumes` |
| `hostPathProvisioner.workload.nodeSelector` | Node selector for the CSI DaemonSet | `kubernetes.io/os: linux` |
| `hostPathProvisioner.workload.tolerations` | Tolerations for the CSI DaemonSet | unset |
| `hostPathProvisioner.workload.affinity` | Affinity for the CSI DaemonSet | unset |

### StorageClasses

`storageClasses` is a list; each entry renders one StorageClass.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storageClasses[].name` | StorageClass name | `hostpath-csi` |
| `storageClasses[].storagePool` | Pool name referenced from `hostPathProvisioner.storagePools` | `local` |
| `storageClasses[].isDefault` | Mark as cluster default StorageClass | `false` |
| `storageClasses[].reclaimPolicy` | Reclaim policy | `Delete` |
| `storageClasses[].volumeBindingMode` | Binding mode | `WaitForFirstConsumer` |
| `storageClasses[].allowVolumeExpansion` | Allow volume expansion | `false` |

### MachineConfig

| Parameter | Description | Default |
|-----------|-------------|---------|
| `machineConfig.enabled` | Render the MachineConfig (triggers node reboot) | `true` |
| `machineConfig.role` | Target MachineConfigPool role (`worker`, or `master` for SNO) | `worker` |
| `machineConfig.path` | Node path to create and SELinux-label | `/var/hpvolumes` |

### Test workload

| Parameter | Description | Default |
|-----------|-------------|---------|
| `test.enabled` | Render the verification PVC and pod | `false` |
| `test.storageClassName` | StorageClass the test PVC uses | `hostpath-csi` |
| `test.size` | Requested size of the test PVC | `1Gi` |
| `test.image` | Image for the test pod | `registry.access.redhat.com/ubi9/ubi-minimal` |

## Examples

### Single-node OpenShift (SNO)

```yaml
machineConfig:
  role: master
hostPathProvisioner:
  workload:
    nodeSelector:
      node-role.kubernetes.io/master: ""
```

### Default StorageClass plus verification

```yaml
storageClasses:
  - name: hostpath-csi
    storagePool: local
    isDefault: true
test:
  enabled: true
```

### Block-backed pool via pvcTemplate

```yaml
hostPathProvisioner:
  storagePools:
    - name: local
      path: /var/hpvolumes
      pvcTemplate:
        storageClassName: my-block-sc
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 50Gi
machineConfig:
  enabled: false
```

## How It Works

1. The `HostPathProvisioner` CR tells the operator which storage pools to serve and where on each node.
2. The operator runs the HPP CSI driver as a DaemonSet (managed outside this chart) with its own SecurityContextConstraints.
3. Each `StorageClass` maps to a pool; `WaitForFirstConsumer` binds a PV only once a consuming pod is scheduled, keeping PV and pod on the same node.
4. The optional `MachineConfig` creates the pool directory on RHCOS and labels it `container_file_t` so unprivileged pods can write.

## Verification

```bash
oc get pods -n <namespace>                                   # CSI DaemonSet Running
oc get sc
oc get hostpathprovisioner -o jsonpath='{.items[0].status.conditions}{"\n"}'

# with test.enabled=true
oc get pvc <release>-hpp-test                                # Bound after scheduling
oc get pod <release>-hpp-test -o jsonpath='{.metadata.annotations.openshift\.io/scc}{"\n"}'   # restricted-v2
oc exec <release>-hpp-test -- cat /data/test.txt             # hpp-ok
```

## Resources Created

- **HostPathProvisioner** - The HPP custom resource (optional)
- **StorageClass** - One per entry in `storageClasses`
- **MachineConfig** - Prepares the node directory and SELinux label (optional)
- **PersistentVolumeClaim + Pod** - Verification workload (optional)

## Requirements

- OpenShift 4.x (Kubernetes 1.21+)
- Helm 3.0+
- HPP operator and `kubevirt.io.hostpath-provisioner` CSI driver already installed

## Maintainers

| Name | Email |
|------|-------|
| Simon Lauger | simon@lauger.de |

## Source Code

- <https://github.com/slauger/helm-charts>
- <https://github.com/kubevirt/hostpath-provisioner-operator>
