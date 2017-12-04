#!/bin/bash +x 

# Create a Tiller Account
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'      
helm init --service-account tiller --upgrade

# Create cluster role binding
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

# Disable RBACK
kubectl apply -f https://raw.githubusercontent.com/openstack/openstack-helm/master/tools/kubeadm-aio/assets/opt/rbac/dev.yaml


# Serve local helm charts

helm serve &
helm repo add local http://localhost:8879/charts
make


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



#Label Network
export OSD_CLUSTER_NETWORK=10.20.44.0/24
export OSD_PUBLIC_NETWORK=10.20.44.0/24
export CEPH_RGW_KEYSTONE_ENABLED=true


helm install --namespace=ceph ${PWD}/ceph --name=ceph  \
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




