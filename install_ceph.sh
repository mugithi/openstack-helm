#!/bin/bash
set -x 
wait 10

#Label Network
export OSD_CLUSTER_NETWORK=10.20.44.0/24
export OSD_PUBLIC_NETWORK=10.20.44.0/24
export CEPH_RGW_KEYSTONE_ENABLED=true


helm install --namespace=ceph /openstack-helm/ceph --name=ceph  \
--set endpoints.identity.namespace=openstack \
--set endpoints.object_store.namespace=ceph \
--set endpoints.ceph_mon.namespace=ceph \
--set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
--set network.public=${OSD_PUBLIC_NETWORK} \
--set network.cluster=${OSD_CLUSTER_NETWORK} \
--set deployment.storage_secrets=true \
--set deployment.ceph=true \
--set deployment.rbd_provisioner=true \
--set deployment.client_secrets=true \
--set deployment.rgw_keystone_user_and_endpoints=false \
--set bootstrap.enabled=true

