#!/bin/bash


function display_usage() {
  echo
  echo "********************************************************************************"
  echo
  echo "Execute scale-up-cas.sh for scaling up the cas deployments in namespace where restore operation is performed"
  echo
  echo "Usage:"
  echo "./scale-up-cas.sh [namespace] [CAS instances list]"
  echo
  echo "Arguments:"
  echo " namespace            : A Kubernetes namespace where CAS deployments are present."
  echo " CAS instances list   : A comma separated list of CAS instances. "
  echo
  echo

  echo 'Example : ./scale-up-cas.sh viya04 "default"  '
  echo
  echo "********************************************************************************"
  echo
}

function scaleUp(){
    for tenant in "${tenants[@]}"
    do
      tenant="$(echo -e "${tenant}" | tr -d '[:space:]')"
      if  [ "${tenant}" = "provider" ] || [ "${tenant}" = "default" ] ; then
        cas_deployment_list=$(kubectl -n "${namespace}" get casdeployment -l "sas.com/tenant=shared" |  tail -n  +2 |  awk '{print $1}')
      else
        cas_deployment_list=$(kubectl -n "${namespace}" get casdeployment -l "sas.com/tenant=${tenant}" |  tail -n  +2 |  awk '{print $1}')
      fi
      for cas_deployment in $cas_deployment_list
      do
        # kubectl commands to scale up the cas deployments

        kubectl -n "${namespace}" patch casdeployment "${cas_deployment}" --type json -p '[{"op": "replace", "path": "/spec/shutdown", "value": false}]'
      done
    done

}

function main() {
if (("$#")); then

  if [ "$1" = "help" ] || [ "$1" = "--help" ]; then
    display_usage
    exit 0
  fi

  if [ -z "$1" ]; then
    if [ -z "${KUBECONFIG}" ]; then
      echo "Error: namespace is not provided as an argument and KUBECONFIG is not set"
      display_usage
      exit 1
    fi
    namespace=$(grep -i "namespace" "${KUBECONFIG}"| awk '{print $2}')
  else
    namespace="$1"
  fi

  if [ -z "$2" ]; then
    echo "Error: Tenants list not provided."
    display_usage
    exit 1
  else
    TENANTS=$2
    IFS=',' read -ra tenants <<< "${TENANTS}"
    scaleUp
  fi
else
  display_usage
fi
}

main "$@"
