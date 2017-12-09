#!/bin/bash
set -x 

# Label Nodes roles
kubectl label nodes ceph-mon=enabled --all
kubectl label nodes ceph-osd=enabled --all
kubectl label nodes ceph-mds=enabled --all
kubectl label nodes ceph-rgw=enabled --all
kubectl label nodes ceph=enabled --all
kubectl label nodes openvswitch=enabled --all
kubectl label nodes openstack-compute-node=enabled --all
kubectl label nodes openstack-control-plane=enabled --all


# Label nodes devices
kubectl label node fat-14 cephosd-device-scsi-0-0.0.5=enabled
kubectl label node fat-15 cephosd-device-scsi-0-0.0.5=enabled
kubectl label node fat-16 cephosd-device-scsi-0-0.0.5=enabled
kubectl label node fat-17 cephosd-device-scsi-0-0.0.5=enabled

kubectl label node fat-14 cephosd-device-scsi-0-0.0.6=enabled
kubectl label node fat-15 cephosd-device-scsi-0-0.0.6=enabled
kubectl label node fat-16 cephosd-device-scsi-0-0.0.6=enabled
kubectl label node fat-17 cephosd-device-scsi-0-0.0.6=enabled

kubectl label node fat-14 cephosd-device-scsi-0-0.0.7=enabled
kubectl label node fat-15 cephosd-device-scsi-0-0.0.7=enabled
kubectl label node fat-16 cephosd-device-scsi-0-0.0.7=enabled
kubectl label node fat-17 cephosd-device-scsi-0-0.0.7=enabled
