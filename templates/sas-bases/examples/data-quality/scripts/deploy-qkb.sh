#!/bin/sh

usage()
{
    cat <<EOF
Usage: $0 IMAGE

Generates Kubernetes YAML that will deploy the given QKB image into the SAS Viya platform.

Mandatory arguments:
    IMAGE - The docker image location for the containerized QKB

EOF
    exit 1
}

generate_job()
{
    cat <<EOF

---
#
# Deployment job for QKB image "$QKB_IMAGE"
# Append this code block to $deploy/site-config/data-quality/custom-qkbs.yaml
#
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    sas.com/deployment: sas-viya
  name: $JOB_NAME
spec:
  template:
    metadata:
      labels:
        app: $JOB_NAME
        app.kubernetes.io/name: $JOB_NAME
        workload.sas.com/class: stateless
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: installer
        command:
          - sh
          - -c
          - /rdutil/sas-rdcopy.sh
        image: $QKB_IMAGE
        imagePullPolicy: IfNotPresent
        securityContext:
          allowPrivilegeEscalation: false
        volumeMounts:
        - mountPath: /rdutil
          name: sas-rdutil-dir
        - mountPath: /tgtdata
          name: sas-quality-knowledge-base-volume
      restartPolicy: Never
      imagePullSecrets: []
      volumes:
      - configMap:
          defaultMode: 493
          name: sas-qkb-management-scripts
        name: sas-rdutil-dir
      - name: sas-quality-knowledge-base-volume
        persistentVolumeClaim:
          claimName: sas-quality-knowledge-base
      tolerations:
        - key: "workload.sas.com/class"
          operator: "Equal"
          value: "stateful"
          effect: "NoSchedule"
        - key: "workload.sas.com/class"
          operator: "Equal"
          value: "stateless"
          effect: "NoSchedule"
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: In
                values:
                - stateless
          - weight: 50
            preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: NotIn
                values:
                - compute
                - cas
                - stateful
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.azure.com/mode
                operator: NotIn
                values:
                - system
EOF
}

# Parse the mandatory args.
[ $# -ne 1 ] && usage

QKB_IMAGE="$1"

SUFFIX=`head /dev/urandom | tr -dc a-z0-9 | head -c 8`
JOB_NAME=sas-quality-knowledge-base-install-job-${SUFFIX}

generate_job

