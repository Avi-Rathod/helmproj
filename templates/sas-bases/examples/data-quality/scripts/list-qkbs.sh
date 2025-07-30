#!/bin/sh

SUFFIX=`head /dev/urandom | tr -dc a-z0-9 | head -c 8`
JOB_NAME=sas-quality-knowledge-base-list-job-$SUFFIX

cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    sas.com/deployment: sas-viya
    workload.sas.com/class: stateless
  name: $JOB_NAME
spec:
  template:
    metadata:
      labels:
        app: $JOB_NAME
        app.kubernetes.io/name: $JOB_NAME
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: lister
        command:
          - sh
          - -c
          - /rdutil/sas-rdlist.sh
        image: busybox
        imagePullPolicy: IfNotPresent
        securityContext:
          allowPrivilegeEscalation: false
        volumeMounts:
        - mountPath: /rdutil
          name: sas-rdutil-dir
        - mountPath: /rdata
          name: sas-quality-knowledge-base-volume
      restartPolicy: Never
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

