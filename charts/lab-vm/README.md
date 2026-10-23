# lab-vm

Opinionated KubeVirt virtual machine for a home lab: Ubuntu cloud image as root disk, a pod network NIC plus a bridged LAN NIC (Multus) with a static address, a minimal cloud-init base setup and an optional external-dns record. Software inside the VM is meant to be managed afterwards (e.g. Ansible).

## What the chart creates

- `VirtualMachine` with a CDI `DataVolume` template importing `disk.image`
- NICs: `pod0` (masquerade, only cluster CIDRs routed via it) and `lan0` (bridge, default route)
- cloud-init: hostname/FQDN, static LAN address, root login with SSH keys only, `qemu-guest-agent` (KubeVirt then reports the LAN IP), `python3` for Ansible
- optional `NetworkAttachmentDefinition` (bridge without IPAM) and `DNSEndpoint`

## Example

```yaml
cpu:
  cores: 4
memory: 8Gi
disk:
  size: 60Gi
podNetwork:
  mac: "02:00:00:01:01:c9"
lan:
  createNetworkAttachment: false
  networkName: lan
  mac: "02:00:00:00:01:c9"
  address: 10.0.0.201/23
  gateway: 10.0.0.1
  nameservers: [10.0.0.1]
ssh:
  authorizedKeys:
    - ssh-ed25519 AAAA...
dns:
  enabled: true
  hostname: vm01.example.com
```

## Notes

- cloud-init network config is only applied on the first boot of an instance. Changing `lan.address` later requires recreating the VM (or changing it inside the guest).
- MAC addresses must be set explicitly and kept stable; the network config matches on them.
- Additional cloud-config can be merged via `cloudInit.extraUserData` (top-level keys overwrite the generated ones).
