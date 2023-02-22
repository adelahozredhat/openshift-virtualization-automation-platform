#!/bin/bash
##
# Script to install AAP in Openshift
##

# Variables
AAP_PASS=ansible

# Functions
waitpodup(){
  x=1
  test=""
  while [ -z "${test}" ]
  do 
    echo "Waiting ${x} times for pod ${1} in ns ${2}" $(( x++ ))
    sleep 1 
    test=$(oc get po -n ${2} | grep ${1})
  done
}

waitpodansibleautomationplatform() {
  NS=ansible-automation-platform
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

waitpodocpvir() {
  NS=openshift-cnv
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

# Install AAP operator
echo "## INFO - Creating AAP Namespace..."
oc new-project ansible-automation-platform

echo "## INFO - Installing AAP Operators..."
oc apply -f ./setup/files/aap_operator.yaml
waitpodansibleautomationplatform automation-controller-operator
waitpodansibleautomationplatform automation-hub-operator
waitpodansibleautomationplatform resource-operator

## Install AAP and Hub
echo "## INFO - Installing AAP..."
oc create secret generic aap-admin-credential --from-literal=password=${AAP_PASS}
oc apply -f setup/files/aap.yaml
waitpodansibleautomationplatform aap-postgres
waitpodansibleautomationplatform aap

echo "## INFO - Installing AAP Hub..."
oc apply -f setup/files/hub.yaml
waitpodansibleautomationplatform hub-postgres
waitpodansibleautomationplatform hub-redis
waitpodansibleautomationplatform hub-content
waitpodansibleautomationplatform hub-worker
waitpodansibleautomationplatform hub-web
waitpodansibleautomationplatform hub-api

AAP_ROUTE=$(oc get route aap -o jsonpath='{.status.ingress[0].host}')
HUB_ROUTE=$(oc get route hub -o jsonpath='{.status.ingress[0].host}')
echo "## AAP INFO ##"
echo " - AAP: ${AAP_ROUTE} (User: admin/${AAP_PASS})"
echo " - AAP Hub: ${HUB_ROUTE} (User: admin/${AAP_PASS})"




echo "## INFO - Installing AAP Operators..."
oc apply -f ./setup/files/ocp_virt_operator.yaml
waitpodocpvir bridge-marker
waitpodocpvir cdi-apiserver
waitpodocpvir cdi-deployment
waitpodocpvir cdi-operator
waitpodocpvir cdi-uploadproxy
waitpodocpvir cluster-network-addons-operator
waitpodocpvir hco-operator
waitpodocpvir hco-webhook
waitpodocpvir hostpath-provisioner-operator
waitpodocpvir hyperconverged-cluster-cli-download
waitpodocpvir kube-cni-linux-bridge-plugin
waitpodocpvir kubemacpool-cert-manager
waitpodocpvir kubemacpool-mac-controller-manager
waitpodocpvir nmstate-cert-manager
waitpodocpvir nmstate-handler
waitpodocpvir nmstate-webhook
waitpodocpvir node-maintenance-operator
waitpodocpvir ssp-operator
waitpodocpvir virt-api
waitpodocpvir virt-controller
waitpodocpvir virt-handler
waitpodocpvir virt-operator
waitpodocpvir virt-template-validator



echo "## INFO - Installing AAP Operators..."
oc apply -f ./setup/files/hyper_converged.yaml