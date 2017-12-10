#!/bin/bash
#set -x 
#Label Network
export OSD_CLUSTER_NETWORK=10.20.44.0/24
export OSD_PUBLIC_NETWORK=10.20.44.0/24
export CEPH_RGW_KEYSTONE_ENABLED=true
DIR="/openstack-helm/"
START=1
END=60
waitForStatusOpenstack () {
  COUNT=0
  HEALTH="DEPLOY_FAILED"
  for (( i=$START; i<=$END; i++))
  do 
    HEALTH=`./waitForStatusOpenstack.py`
    if [ $HEALTH == "DEPLOY_COMPLETE" ]; 
    then 
       break
    fi
    if (( $i % 5 == 0 ));
    then 
       kubectl get pods -n $1 | grep -i $2
    fi
    echo "Still Waiting for $1 $2 service to come up $i out of ${END}  retries"
    sleep 5
  done 
 }

waitForStatusCeph () {
  COUNT=0
  HEALTH="DEPLOY_FAILED"
  for (( i=$START; i<=$END; i++))
  do
    HEALTH=`./waitForStatusCeph.py`
    if [ $HEALTH == "DEPLOY_COMPLETE" ];
    then
       break
    fi
    if (( $i % 5 == 0 ));
    then
       kubectl get pods -n $1 | grep -i $2
    fi
    echo "Still Waiting for $1 $2  services to come up $i out of ${END} retries"
    sleep 5
  done
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
waitForStatusCeph ceph ceph


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
  --set deployment.client_secrets=true \
  --set deployment.rgw_keystone_user_and_endpoints=false
waitForStatusOpenstack openstack ceph
                                                                                                                                                                                                                    1,1           Top
echo "installing mariadb"
helm install --name=mariadb ${DIR}/mariadb --namespace=openstack
waitForStatusOpenstack openstack mariadb

echo "insalling memcached"
helm install --name=memcached ${DIR}/memcached --namespace=openstack
waitForStatusOpenstack openstack memcached


echo "insalling etcd-rabbitmq"
helm install --name=etcd-rabbitmq ${DIR}/etcd --namespace=openstack
waitForStatusOpenstack openstack etcd-rabbitmq

echo "Installling rabbitmq"
helm install --name=rabbitmq ${DIR}/rabbitmq --namespace=openstack
waitForStatusOpenstack openstack rabbitmq

echo "installing ngnix ingress controller"
helm install --name=ingress ${DIR}/ingress --namespace=openstack
waitForStatusOpenstack openstack ingress

echo "installing libvirt"
helm install --name=libvirt ${DIR}/libvirt --namespace=openstack
waitForStatusOpenstack openstack libvirt

echo "installing openvswitch"
helm install --name=openvswitch ${DIR}/openvswitch --namespace=openstack
waitForStatusOpenstack openstack openvswitch

echo "installing keystone"
helm install --namespace=openstack --name=keystone ${DIR}/keystone \
  --set pod.replicas.api=2
witForStatusOpenstack openstack keystone


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
waitForStatusOpenstack openstack ceph

echo "installing horizon"
helm install --namespace=openstack --name=horizon ${DIR}/horizon \
  --set network.enable_node_port=true
waitForStatusOpenstack openstack horizon


echo "intalling glance"
export GLANCE_BACKEND=radosgw
helm install --namespace=openstack --name=glance ${DIR}/glance \
  --set pod.replicas.api=2 \
  --set pod.replicas.registry=2 \
  --set storage=${GLANCE_BACKEND}
waitForStatusOpenstack opnestack glance


echo "intalling heat"
helm install --namespace=openstack --name=heat ${DIR}/heat
waitForStatusOpenstack openstack heat

echo "installing neutron"
helm install --namespace=openstack --name=neutron ${DIR}/neutron \
  --set pod.replicas.server=2
waitForStatusOpenstack openstack neutron

helm install --namespace=openstack --name=nova ${DIR}/nova \
  --set pod.replicas.api_metadata=2 \
  --set pod.replicas.osapi=2 \
  --set pod.replicas.conductor=2 \
  --set pod.replicas.consoleauth=2 \
  --set pod.replicas.scheduler=2 \
  --set pod.replicas.novncproxy=2
itForStatusOpenstack openstack nova


echo "intalling cinder"
helm install --namespace=openstack --name=cinder ${DIR}/cinder \
  --set pod.replicas.api=2
waitForStatusOpenstack openstack cinder
