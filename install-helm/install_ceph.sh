#!/bin/bash

#Label Network
export OSD_CLUSTER_NETWORK=10.20.44.0/24
export OSD_PUBLIC_NETWORK=10.20.44.0/24
export CEPH_RGW_KEYSTONE_ENABLED=true

function waitForStatusOpenstack() {
  if ! [[ $HEALTH == "DEPLOY_COMPLETE" || $COUNT == 120 ]];
   then
     HEALTH=`./waitForStatusOpenstack.py`
     COUNT=$((COUNT+1))
     echo "Still Waiting for services to come up ${COUNT} retries"
     sleep 5
  fi
}

function waitForStatusCeph() {
  if ! [[ $HEALTH == "DEPLOY_COMPLETE" || $COUNT == 120 ]];
   then
     HEALTH=`./waitForStatusCeph.py`
     COUNT=$((COUNT+1))
     echo "Still Waiting for services to come up ${COUNT} retries"
     sleep 5
  fi
}

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


MON_POD=$(kubectl get pods \
--namespace=ceph \
--selector="application=ceph" \
--selector="component=mon" \
--no-headers | awk '{ print $1; exit }')


if ! [[ $HEALTH == "HEALTH_OK" || $COUNT == 20 ]];
 then
   HEALTH=`kubectl exec -n ceph ${MON_POD} -- ceph -s | grep -I HEALTH_OK | awk '{print $2}'`
   COUNT=$((COUNT+1))
   sleep 5
fi

helm install --namespace=openstack ${DIR}/ceph --name=ceph-openstack-config \
  --set endpoints.identity.namespace=openstack \
  --set endpoints.object_store.namespace=ceph \
  --set endpoints.ceph_mon.namespace=ceph \
  --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
  --set network.public=${OSD_PUBLIC_NETWORK} \
  --set network.cluster=${OSD_CLUSTER_NETWORK} \
  --set deployment.storage_secrets=false \
  --set deployment.ceph=false \
  --set deployment.rbd_provisioner=false \
waitForStatusOpenstack
                                                                                                                                                                                                                    1,1           Top
helm install --name=rabbitmq ${DIR}/rabbitmq --namespace=openstack
waitForStatusOpenstack

echo "installing ngnix ingress controller"
helm install --name=ingress ${DIR}/ingress --namespace=openstack
waitForStatusOpenstack

echo "installing libvirt"
helm install --name=libvirt ${DIR}/libvirt --namespace=openstack
waitForStatusOpenstack

echo "installing openvswitch"
helm install --name=openvswitch ${DIR}/openvswitch --namespace=openstack
waitForStatusOpenstack

helm install --namespace=openstack ${DIR}/ceph --name=radosgw-openstack \
  --set endpoints.identity.namespace=openstack \
  --set endpoints.object_store.namespace=ceph \
  --set endpoints.ceph_mon.namespace=ceph \
  --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
  --set network.public=${OSD_PUBLIC_NETWORK} \
  --set network.cluster=${OSD_CLUSTER_NETWORK} \
  --set deployment.storage_secrets=false \
  --set deployment.ceph=false \
  --set deployment.rbd_provisioner=false \
  --set deployment.client_secrets=false \
  --set deployment.rgw_keystone_user_and_endpoints=true

                                                                                                                                                                                                                                            79,1          98%
echo "Installling rabbitmq"
helm install --name=rabbitmq ${DIR}/rabbitmq --namespace=openstack
waitForStatusOpenstack

echo "installing ngnix ingress controller"
helm install --name=ingress ${DIR}/ingress --namespace=openstack
waitForStatusOpenstack

echo "installing libvirt"
helm install --name=libvirt ${DIR}/libvirt --namespace=openstack
waitForStatusOpenstack

echo "installing openvswitch"
helm install --name=openvswitch ${DIR}/openvswitch --namespace=openstack
waitForStatusOpenstack

helm install --namespace=openstack ${DIR}/ceph --name=radosgw-openstack \
  --set endpoints.identity.namespace=openstack \
  --set endpoints.object_store.namespace=ceph \
  --set endpoints.ceph_mon.namespace=ceph \
  --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
  --set network.public=${OSD_PUBLIC_NETWORK} \
  --set network.cluster=${OSD_CLUSTER_NETWORK} \
  --set deployment.storage_secrets=false \
  --set deployment.ceph=false \
  --set deployment.rbd_provisioner=false \
  --set deployment.client_secrets=false \
  --set deployment.rgw_keystone_user_and_endpoints=true
waitForStatusOpenstack

echo "installing horizon"
helm install --namespace=openstack --name=horizon ${DIR}/horizon \
  --set network.enable_node_port=true
waitForStatusOpenstack


echo "intalling glance"
export GLANCE_BACKEND=radosgw
helm install --namespace=openstack --name=glance ${DIR}/glance \
  --set pod.replicas.api=2 \
  --set pod.replicas.registry=2 \
  --set storage=${GLANCE_BACKEND}
waitForStatusOpenstack


echo "intalling heat"
helm install --namespace=openstack --name=heat ${DIR}/heat
waitForStatusOpenstack

echo "installing neutron"
helm install --namespace=openstack --name=neutron ${DIR}/neutron \
  --set pod.replicas.server=2
waitForStatusOpenstack

echo "intalling cinder"
helm install --namespace=openstack --name=cinder ${DIR}/cinder \
  --set pod.replicas.api=2
waitForStatusOpenstack
