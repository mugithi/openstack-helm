#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -ex

# Exit if run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script cannot be run as root" 1>&2
   exit 1
fi

export WORK_DIR=$(pwd)
source ${WORK_DIR}/tools/gate/vars.sh
source ${WORK_DIR}/tools/gate/funcs/common.sh
source ${WORK_DIR}/tools/gate/funcs/network.sh
source ${WORK_DIR}/tools/gate/funcs/helm.sh
source ${WORK_DIR}/tools/gate/funcs/kube.sh

# Setup the logging location: by default use the working dir as the root.
rm -rf ${LOGS_DIR} || true
mkdir -p ${LOGS_DIR}

function dump_logs () {
  ${WORK_DIR}/tools/gate/dump_logs.sh
}
trap 'dump_logs "$?"' ERR

# Moving the ws-linter here to avoid it blocking all the jobs just for ws
if [ "x$INTEGRATION_TYPE" == "xlinter" ]; then
  bash ${WORK_DIR}/tools/gate/whitespace.sh
fi

# Do the basic node setup for running the gate
gate_base_setup

# We setup the network for pre kube here, to enable cluster restarts on
# development machines
net_resolv_pre_kube
net_hosts_pre_kube

# Setup helm
helm_install
helm_serve
helm_lint

# In the linter, we also run the helm template plugin to get a sanity check
# of the chart without verifying against the k8s API
if [ "x$INTEGRATION_TYPE" == "xlinter" ]; then
  helm_build > ${LOGS_DIR}/helm_build
  helm_plugin_template_install
  helm_template_run
else
  cd ${WORK_DIR}; make pull-all-images
  # Setup the K8s Cluster
  if [ "x$INTEGRATION" == "xaio" ]; then
   bash ${WORK_DIR}/tools/gate/kubeadm_aio.sh
  elif [ "x$INTEGRATION" == "xmulti" ]; then
   bash ${WORK_DIR}/tools/gate/kubeadm_aio.sh
   bash ${WORK_DIR}/tools/gate/setup_gate_worker_nodes.sh
  fi
  if [ "x$LOOPBACK_CREATE" == "xtrue" ]; then
    # loopback_dev_info_collect will assemble device info
    # from each node, merge it all into a values yaml file,
    # and label gate nodes for the OSD pods they support.
    loopback_dev_info_collect
  else
    kube_label_node_directories
  fi
  # Deploy OpenStack-Helm
  if ! [ "x$INTEGRATION_TYPE" == "x" ]; then
    bash ${WORK_DIR}/tools/gate/helm_dry_run.sh
    bash ${WORK_DIR}/tools/gate/launch-osh/common.sh
    if [ "x$INTEGRATION_TYPE" == "xbasic" ]; then
      bash ${WORK_DIR}/tools/gate/launch-osh/basic.sh
    elif [ "x$INTEGRATION_TYPE" == "xarmada" ]; then
      bash ${WORK_DIR}/tools/gate/launch-osh/armada.sh
    fi
  fi

  if ! [ "x$INTEGRATION_TYPE" == "x" ]; then
    # Run Basic Full Stack Tests
    if [ "x$INTEGRATION" == "xaio" ] && [ "x$RALLY_CHART_ENABLED" == "xfalse" ]; then
     bash ${WORK_DIR}/tools/gate/openstack/network_launch.sh
     bash ${WORK_DIR}/tools/gate/openstack/vm_cli_launch.sh
     bash ${WORK_DIR}/tools/gate/openstack/vm_heat_launch.sh
    fi
    # Collect all logs from the environment
    bash ${WORK_DIR}/tools/gate/dump_logs.sh 0
  fi
fi
