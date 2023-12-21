#!/bin/bash
 
set -xe
 
for NODE in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do
  oc debug node/$NODE -- chroot /host/ bash -c "sync ; echo 3 > /proc/sys/vm/drop_caches"
done
