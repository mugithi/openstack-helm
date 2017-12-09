#!/usr/bin/python

import  subprocess
import time
timeout=1
DEPLOY_STATUS="DEPLOY_FAILED"
value = "0/1"
for i in range(timeout):
    time.sleep(1)
    isInstallCompleleteList = subprocess.check_output("kubectl get pods -n ceph | awk '{print $2}'", stderr=subprocess.STDOUT, shell=True).split("\n")[1:-1]
    if value not in isInstallCompleleteList:
        DEPLOY_STATUS="DEPLOY_COMPLETE"

print DEPLOY_STATUS
