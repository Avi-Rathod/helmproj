#!/bin/bash

#
# Copyright (c) 2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
#

set -euf

namespace="${1:-}"

if [ -z "${namespace}" ]
then
  echo "Error: namespace required"
  echo "Usage: $0 <namespace>"
  exit 1
fi

echo "Checking namespace ${namespace}"
kubectl api-resources --namespaced -o name --verbs list| while read kind
do
  echo "Checking resources of kind ${kind}"
  kubectl -n "${namespace}" get "${kind}" -o json | jq -r '.items[] | select(.metadata.ownerReferences | length!=0) | select(.metadata.ownerReferences[] | .kind=="SASDeployment") | .metadata.name' | while read name
  do
    echo "Disassociating resource ${kind}/${name}"
    kubectl -n "${namespace}" apply view-last-applied "${kind}" "${name}" -o json | \
      jq 'del(.metadata.ownerReferences[] | select(.kind == "SASDeployment"))' | \
      kubectl -n "${namespace}" apply set-last-applied "${kind}" "${name}" -f -
    references=$(kubectl -n "${namespace}" get "${kind}" "${name}" -o json | jq '(.metadata.ownerReferences) | del(.[]|select(.kind=="SASDeployment"))')
    kubectl -n "${namespace}" patch "${kind}" "${name}" --type merge -p "{\"metadata\":{\"ownerReferences\":${references}}}"
  done
done

kubectl -n "${namespace}" get sasdeployment -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read name
do
  echo "Deleting SASDeployment CR ${name}"
  kubectl -n "${namespace}" delete sasdeployment "${name}"
done

echo ""
echo "Complete"
