#!/bin/bash

#
# create-cas-server.sh
# 2020
#
# This script will take user parameters as input, and
# generate new CAS server definitions (CR) for Viya 4.

#set -x

function echo_line()
{
    line_out="$(date) - $1"
    printf "%s\n" "$line_out"
}

version="1.6"

case "$1" in
        --version | -v)
                echo "${version}"
                exit
                ;;
        --help | -h)
                echo "Flags:"
                echo "  -h  --help     help"
                echo "  -i, --instance CAS server instance name"
                echo "  -o, --output   Output location. If undefined, default to working directory."
                echo "  -v, --version  CAS server creation utility version"
                echo "  -w, --workers  Specify the number of CAS worker nodes. Default is 0 (SMP)."
                echo "  -b, --backup   Set this to include a CAS backup controller. Disabled by default."
                echo "  -t, --tenant   Set the tenant name. default is shared."
                echo "  -r, --transfer Set this to enable support for state transfer between restarts. Disabled by default."
                echo "  -a, --affinity Specify the node affinity and toleration to use for this deployment.  Default is 'cas'."
                echo "  -q, --required-affinity Set this flag to have the node affinity be a required node affinity.  Default is preferred node affinity."
                echo "  -p, --pools    Set this flag to have the tolerations and affinities be set for two separate node pools.  Where the controller will run on nodes labeled 'cascontroller' and the workers on ones labeled 'casworker'."
                exit
                ;;
esac

# declaring a couple of associative arrays
declare -A arguments=();
declare -A variables=();
declare -A ovariables=();
declare -A env=();

# declaring an index integer
declare -i index=1;

variables["-i"]="instance";
variables["--instance"]="instance";
variables["-f"]="file";
variables["--file"]="file";
variables["-o"]="output";
variables["--output"]="output";
variables["-w"]="workers";
variables["--workers"]="workers";
variables["-t"]="tenant";
variables["--tenant"]="tenant";
variables["-a"]="affinity";
variables["--affinity"]="affinity";

# ioptional variables are ones that can either have "1" as the value
#  or no value and they default to true.
ovariables["-q"]="required";
ovariables["--required-affinity"]="required";
ovariables["-p"]="pools";
ovariables["--pools"]="pools";
ovariables["-b"]="backup";
ovariables["--backup"]="backup";
ovariables["-r"]="transfer";
ovariables["--transfer"]="transfer";


# $@ here represents all arguments passed in
for i in "$@"
do
  arguments[$index]=$i;
  prev_index="$(expr $index - 1)";

  # this if block does something akin to "where $i contains ="
  # "%=*" here strips out everything from the = to the end of the argument leaving only the label
  if [[ $i == *"="* ]]
    then argument_label=${i%=*}
    else argument_label=${arguments[$prev_index]}
  fi

  exec 2> /dev/null
  # this if block only evaluates to true if the argument label exists in the variables array
  if [[ -n ${variables[$argument_label]} ]]
    then
        # dynamically creating variables names using declare
        # "#$argument_label=" here strips out the label leaving only the value
        if [[ $i == *"="* ]]
            then declare ${variables[$argument_label]}="${i#$argument_label=}"
            else declare ${variables[$argument_label]}="${arguments[$index]}"
        fi
        argument_label="" #clear argument label
  elif [[ -n ${ovariables[$argument_label]} ]]; then
      # dynamically creating variables names using declare
      # "#$argument_label=" here strips out the label leaving only the value
      if [[ $i == *"="* ]]
           then declare ${ovariables[$argument_label]}="${i#$argument_label=}"
      elif [[ $i == "-"* ]]
         # if it starts with a -, that's the next argument, default to 1
         then declare ${ovariables[$argument_label]}="1"
      else declare ${ovariables[$argument_label]}="${arguments[$index]}"
      fi
      argument_label="" #clear argument label
  elif [ "$argument_label" == "--env" ]; then
    #get the index of the value
    ((value_index=index+1))

    #store the name and value in the map
    env["$i"]="${!value_index}"
    argument_label="" #clear argument label
  fi
  exec 2> /dev/tty

  index=$((index+1));
done;

# check to make sure that there isn't a hanging empty argument at the end
if [ -n "${argument_label}" ]; then
    if [[ -n ${ovariables[$i]} ]]; then
      #optional value at the end, set to 1
      declare ${ovariables[$i]}="1"
    else
      echo_line "$i does not have a value.  Please provide a value."
      exit 1
    fi
fi

if [[ -n ${ovariables[$i]} ]]; then
      #optional value at the end, set to 1
      declare ${ovariables[$i]}="1"
fi

if [ -z "${instance}" ]; then
    if [ -z "${tenant}" ]; then
        echo_line "instance is not defined.  Please provide instance with either -i or --instance flag."
        exit 1
    else
        instance="default"
    fi
fi
echo_line "instance = $instance"
echo_line "tenant = $tenant"

if [ -z "${tenant}" ]; then
    # default to shared, if not specified
    tenant="shared"
fi

# Validate that the tenant name is a valid tenant name
#  * Must be letters and numbers only. No special characters or symbols.
if [[ ! $tenant =~ ^[[:alnum:]]+$ ]]; then
    echo "invalid value for tenant option: $tenant"
    exit 1
fi

if [ -z "${affinity}" ]; then
   # default node affinity to cas
    affinity="cas"
fi

if [ -n "${workers}" ]; then
    workers=${workers}
else
    workers=0
fi

if [ -n "${transfer}" ]; then
    if [ "$transfer" == "1" ]; then
      transferpvc="- transfer-pvc.yaml"
      transfermount=$'- name: cas-default-transfer-volume\n          mountPath: /cas/transferdir'
      transfervolume=$'- name: cas-default-transfer-volume\n        persistentVolumeClaim:\n'"          claimName: sas-cas-transfer-data-${tenant}-${instance}"
      transfertransformer="- state-transfer.yaml"
    else
        echo "invalid value for transfer option: $transfer"
        echo "1 is the only valid value"
        exit 1
    fi
fi

if [ -n "${backup}" ]; then
    if [ "$backup" == "0" ] || [ "$backup" == "1" ]; then
        backup=${backup}
    else
        echo "invalid value for backup option: $backup"
        echo "please enter 0 or 1"
        exit 1
    fi
else
    backup=0
fi

if [ -n "${required}" ]; then
    if [ "$required" == "1" ]; then
        if [ "$pools" == "1" ]; then
          requiredtransformer="- require-affinity-pools.yaml"
        else
          requiredtransformer="- require-affinity.yaml"
        fi
    else
        echo "invalid value for required option: $required"
        echo "1 is the only valid value"
        exit 1
    fi
else
    required=0
fi

if [ -n "${output}" ]; then
    echo_line "output = $output"
    output=$output"/"

    if [ -d "${output}cas-${tenant}-${instance}" ]; then
    echo ""
    while true; do
        read -p "Content already exists in the specified output location.  Continuing will overwrite the existing content.  Do you want to continue? (y/n) " yn
        case $yn in
            [Yy]* ) make install; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    rm -rf "${output}"cas-${tenant}-${instance}
    fi

    if [ ! -d "${output}cas-${tenant}-${instance}" ]; then
        echo "output directory does not exist: ${output}"
        echo "creating directory: ${output}"
        mkdir -p "${output}"/cas-${tenant}-${instance}
    fi
else

    if [ -d "cas-${tenant}-${instance}" ]; then
    echo ""
    while true; do
        read -p "Content already exists in the specified output location.  Continuing will overwrite the existing content.  Do you want to continue? (y/n) " yn
        case $yn in
            [Yy]* ) make install; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    rm -rf  cas-${tenant}-${instance}
    fi
    mkdir -p cas-${tenant}-${instance}
fi

echo "Generating artifacts..."

count=0
total=34
pstr="[=======================================================================]"

while [ $count -lt $total ]; do
  sleep 0.025 # this is work
  count=$(( $count + 1 ))
  pd=$(( $count * 73 / $total ))
  printf "\r%3d.%1d%% %.${pd}s" $(( $count * 100 / $total )) $(( ($count * 1000 / $total) % 10 )) $pstr
done

echo ""
echo "|-cas-${tenant}-${instance} (root directory)"

echo "  |-cas-${tenant}-${instance}-cr.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-${tenant}-${instance}-cr.yaml
apiVersion: viya.sas.com/v1alpha1
kind: CASDeployment
metadata:
  annotations:
    sas.com/sas-access-config: "true"
    sas.com/sas-kerberos-config: "true"
    sas.com/config-init-mode: "initcontainer"
  labels:
    app: sas-cas-operator
    app.kubernetes.io/instance: "${tenant}-${instance}"
    app.kubernetes.io/name: "cas"
    app.kubernetes.io/managed-by: sas-cas-operator
    sas.com/admin: "namespace"
    workload.sas.com/class: cas
    sas.com/tenant: "${tenant}"
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
  name: "${tenant}-${instance}"
spec:
  controllerTemplate:
    metadata:
      annotations: {}
      labels:
        pod.security.sas.com/exception-default-capabilities: "exempt"
        pod.security.sas.com/exception-allow-privilege-escalation: "exempt"
        pod.security.sas.com/exception-run-as-non-root: "exempt"
    spec:
      tolerations:
      - key: "workload.sas.com/class"
        operator: "Equal"
        value: "$affinity"
        effect: "NoSchedule"
      initContainers:
      - image: sas-config-init
        imagePullPolicy: IfNotPresent
        name: sas-config-init
        env:
        - name: SAS_INIT_CONFIG_LOG_LEVEL
          value: INFO
        envFrom:
          - configMapRef:
              name: sas-go-config
          - configMapRef:
              name: sas-shared-config
          - configMapRef:
              name: sas-access-config
          - secretRef:
              name: sas-consul-client
        volumeMounts:
          - mountPath: /cas/config/
            name: cas-default-config-volume
          - mountPath: /opt/sas/viya/home/commonfiles
            name: commonfilesvols
        resources:
          limits:
            memory: 500Mi
            cpu: 500m
          requests:
            memory: 500Mi
            cpu: 500m
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          privileged: false
          readOnlyRootFilesystem: true
      containers:
      - name: sas-cas-server  # required name for the CAS container
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /internal/state
            port: 8777
          initialDelaySeconds: 5
          periodSeconds: 10
        #args:  # change the command so we can manually run the entrypoint script and debug cas
          #- while true; do sleep 30; done;
        #command:
          #- /bin/bash
          #- -c
          #- --
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        env:
        - name: CASENV_CONSUL_NAME
          value: "cas-${tenant}-${instance}"
        - name: CONSUL_HTTP_ADDR
          value: http://localhost:8500
        - name: CASENV_CAS_VIRTUAL_PATH
          value: "/cas-${tenant}-${instance}-http"
EOF

for i in "${!env[@]}"
do
  eval "name=$i"
  eval "value=${env[$i]}"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-${tenant}-${instance}-cr.yaml
        - name: $name
          value: "$value"
EOF
done

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-${tenant}-${instance}-cr.yaml
        - name: SAS_LICENSE
          valueFrom:
            secretKeyRef:
              key: SAS_LICENSE
              name: sas-cas-license
        envFrom:
        - configMapRef:
            name: sas-shared-config
        - configMapRef:
            name: sas-java-config
        - configMapRef:
            name: sas-access-config
        - configMapRef:
            name: sas-cas-config-${tenant}-${instance}
        - configMapRef:
            name: sas-deployment-metadata
        - secretRef:
            name: sas-consul-client
        image: sas-cas-server
        imagePullPolicy: IfNotPresent
        resources:
          requests:
            memory: 2Gi
            cpu: 250m
        volumeMounts:
        #- name: bigdisk
          #mountPath: "/bigdisk" # Example of mount supplied by user
        ${transfermount}
        - name: cas-default-permstore-volume
          mountPath: /cas/permstore
        - name: cas-default-data-volume
          mountPath: /cas/data
        - name: cas-default-cache-volume
          mountPath: /cas/cache
        - name: cas-default-config-volume
          mountPath: /cas/config
        - name: cas-tmp-volume
          mountPath: /tmp
          subPath: tmp
        - name: cas-tmp-volume
          mountPath: /opt/sas/viya/config/tmp/sas-cas
          subPath: sas-cas
        - name: cas-license-volume
          mountPath: /cas/license
        - name: commonfilesvols
          mountPath: /opt/sas/viya/home/commonfiles
          readOnly: true
        - name: podinfo
          mountPath: /etc/podinfo
      imagePullSecrets:
      - name: sas-image-pull-secrets
      serviceAccountName: sas-cas-server
      volumes:
      ${transfervolume}
      - name: podinfo
        downwardAPI:
          items:
            - path: "labels"
              fieldRef:
                fieldPath: metadata.labels
      - name: cas-default-permstore-volume
        persistentVolumeClaim:
          claimName: cas-${tenant}-${instance}-permstore
      - name: cas-default-data-volume
        persistentVolumeClaim:
          claimName: cas-${tenant}-${instance}-data
      - name: cas-default-cache-volume
        emptyDir: {}
      - name: cas-default-config-volume
        emptyDir: {}
      - name: cas-tmp-volume
        emptyDir: {}
      - name: cas-license-volume
        secret:
          secretName: sas-cas-license
          items:
          - key: SAS_LICENSE
            path: license.sas
      - name: commonfilesvols
        persistentVolumeClaim:
          claimName: sas-commonfiles
          readOnly: true
  workers: ${workers}
  backupControllers: ${backup}
  workerTemplate: {}
  controllerTemplateAdditions:
    spec:
      tolerations:
      - key: "workload.sas.com/class"
        operator: "Equal"
        value: "${affinity}controller"
        effect: "NoSchedule"
  workerTemplateAdditions:
    metadata:
      annotations:
        casoperator.sas.com/remove-sidecars: "sas-backup-agent,sas-consul-agent"
    spec:
      tolerations:
      - key: "workload.sas.com/class"
        operator: "Equal"
        value: "${affinity}worker"
        effect: "NoSchedule"
  tenantID: ${tenant}
  instanceID: ${instance}
  publishHTTPIngress: true
  routeTemplate:
    spec:
      host: \$(INGRESS_HOST)
    metadata:
      annotations: {}
      labels: {}
  ingressTemplate:
    spec:
      rules:
      - host: \$(INGRESS_HOST)
    metadata:
      annotations:
        nginx.ingress.kubernetes.io/proxy-body-size: 2048m
        nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
        nginx.ingress.kubernetes.io/proxy-buffer-size: "16k"
      labels: {}
  appendCASAllowlistPaths: []
EOF

echo "  |-kustomization.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/kustomization.yaml
resources:
- ${tenant}-${instance}-pvc.yaml
- provider-pvc.yaml
- cas-${tenant}-${instance}-cr.yaml
${transferpvc}
generators:
- configmaps.yaml
configurations:
- kustomizeconfig.yaml
transformers:
- cas-fsgroup-security-context.yaml
- annotations.yaml
- backup-agent-patch.yaml
- cas-consul-sidecar.yaml
- node-affinity.yaml
${transfertransformer}
${requiredtransformer}
EOF

echo "  |-${tenant}-${instance}-pvc.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/${tenant}-${instance}-pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cas-${tenant}-${instance}-permstore
  labels:
    sas.com/backup-role: provider
    app.kubernetes.io/part-of: cas
    sas.com/cas-instance: ${tenant}-${instance}
    sas.com/cas-pvc: permstore
    sas.com/tenant: ${tenant}
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cas-${tenant}-${instance}-data
  labels:
    sas.com/backup-role: provider
    app.kubernetes.io/part-of: cas
    sas.com/cas-instance: ${tenant}-${instance}
    sas.com/cas-pvc: data
    sas.com/tenant: ${tenant}
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
EOF

echo "  |-annotations.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/annotations.yaml
apiVersion: builtin
kind: AnnotationsTransformer
metadata:
  name: annotations-transformer
annotations:
  sas.com/component-name: sas-cas-operator
fieldSpecs:
- path: metadata/annotations
  create: true
EOF

echo "  |-backup-agent-patch.yaml"
    cat << EOF >> "${output}"cas-${tenant}-${instance}/backup-agent-patch.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch1
patch: |-
  - op: add
    path: /metadata/labels/sas.com~1backup-role
    value:
      "provider"
target:
  annotationSelector: sas.com/component-name=sas-cas-operator
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch2
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/-
    value:
      env:
      - name: BACKUP_MOUNT_LOCATION
        value: /sasviyabackup
      - name: BACKUP_SOURCE_MOUNTS
        value: cas-default-data-volume
      - name: cas-default-data-volume
        value: /cas/data
      - name: NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/cas-env-consul-name']
      - name: CAS_NODE_TYPE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/node-type']
      - name: CAS_CONTROLLER_ACTIVE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/controller-active']
      - name: CAS_CFG_MODE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/cas-cfg-mode']
      - name: CAS_SERVICE_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/service-name']
      envFrom:
      - configMapRef:
          name: sas-go-config
      - configMapRef:
          name: sas-shared-config
      - configMapRef:
          name: sas-java-config
      - configMapRef:
          name: sas-backup-agent-parameters
      - secretRef:
          name: sas-consul-client
      image: sas-backup-agent
      imagePullPolicy: IfNotPresent
      args:
      - -c
      - rm -f /tmp/sas-shutdown; while [ ! -f /tmp/sas-shutdown ]; do /opt/sas/viya/home/bin/backup_agent_job_start.sh; echo 'restarting backup script'; sleep 3; done;
      command:
      - /bin/bash
      lifecycle:
        preStop:
          exec:
            command: ["bash", "-c", "touch /tmp/sas-shutdown; pkill -SIGKILL 'backup-agent' ; kill -SIGKILL \$(ps -Af | grep 'backup_agent_job_start.sh'  | grep -v grep | awk '{print \$2}')"]
      resources:
        requests:
          memory: 2Gi
          cpu: 100m
        limits:
          memory: 2Gi
          cpu: 100m
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
          - ALL
      imagePullPolicy: IfNotPresent
      name: sas-backup-agent
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
      volumeMounts:
      - name: backup
        mountPath: /sasviyabackup
      - name: cas-default-data-volume
        mountPath: /cas/data
      - name: tmp
        mountPath: /tmp
target:
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
  annotationSelector: sas.com/component-name=sas-cas-operator
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch3
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: backup
      persistentVolumeClaim:
        claimName: sas-cas-backup-data-${tenant}-${instance}
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: tmp
      emptyDir: {}
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
    value:
      name: backup
      mountPath: /sasviyabackup
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/envFrom/-
    value:
      configMapRef:
        name: sas-restore-job-parameters
target:
  annotationSelector: sas.com/component-name=sas-cas-operator
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
EOF

echo "  |-cas-consul-sidecar.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-consul-sidecar.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-consul-sidecar
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/-
    value:
      env:
      - name: CONSUL_SERVER_LIST
        value: sas-consul-server
      - name: CONSUL_SERVER_FLAG
        value: "false"
      - name: CONSUL_CLIENT_ADDRESS
        value: 127.0.0.1
      - name: CONSUL_DATACENTER_NAME
        value: viya
      - name: CONSUL_TOKENS_ENCRYPTION
        valueFrom:
          secretKeyRef:
            name: sas-consul-management
            key: CONSUL_TOKENS_ENCRYPTION
      - name: CONSUL_CAS_POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name
      - name: CONSUL_NODE_NAME
        value: \$(CONSUL_CAS_POD_NAME)-agent
      envFrom:
      - configMapRef:
          name: sas-shared-config
      - configMapRef:
          name: sas-go-config
      - secretRef:
          name: sas-consul-client
      image: sas-consul-server
      imagePullPolicy: IfNotPresent
      command: [/bin/bash]
      args:
        - -c
        - rm -f /tmp/sas-shutdown; while [ ! -f /tmp/sas-shutdown ]; do /opt/sas/viya/home/bin/sas-consul-server-entrypoint.sh; echo restarting_consul_script; sleep 3; done;
      lifecycle:
        preStop:
          exec:
            command:
            - /bin/sh
            - -c
            - PROTO="http";
              [[ ! -z \${SAS_CERTIFICATE_FILE+x} ]] && export PROTO="https";
              CONSUL_HTTP_ADDR=\$PROTO://localhost:8500; touch /tmp/sas-shutdown;
              /opt/sas/viya/home/bin/consul leave ; sleep 5; pkill consul
      name: sas-consul-agent
      ports:
      - containerPort: 8300
        name: server
        protocol: TCP
      - containerPort: 8301
        name: serflan-tcp
        protocol: TCP
      - containerPort: 8301
        name: serflan-udp
        protocol: UDP
      - containerPort: 8500
        name: http
        protocol: TCP
      readinessProbe:
        exec:
          command:
          - sh
          - /opt/sas/viya/home/bin/consul-readiness-probe.sh
        failureThreshold: 3
        initialDelaySeconds: 5
        successThreshold: 1
        timeoutSeconds: 60
        periodSeconds: 20
      volumeMounts:
      - mountPath: /opt/sas/viya/config/etc/consul.d
        name: consul-tmp-volume
        subPath: consul.d
      - mountPath: /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default
        name: consul-tmp-volume
        subPath: consul-tokens
      - mountPath: /opt/sas/viya/config/tmp/sas-consul
        name: consul-tmp-volume
        subPath: sas-consul
      - mountPath: /tmp
        name: consul-tmp-volume
        subPath: tmp
      - mountPath: /consul/data/
        name: consul-tmp-volume
        subPath: data
      resources:
        requests:
          memory: 500Mi
          cpu: 500m
        limits:
          memory: 500Mi
          cpu: 500m
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
          - ALL
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: consul-tmp-volume
      emptyDir: {}
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-cas-fsgroup-security-context.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-fsgroup-security-context.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-apply-security-context
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/securityContext
    value:
        runAsUser: 1001
        runAsGroup: 1001
        runAsNonRoot: true
        fsGroup: 1001

target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-cas-sssd-sidecar.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/cas-sssd-sidecar.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-sssd-sidecar
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/-
    value:
      env:
      - name: SAS_K8S_DEPLOYMENT_NAME
        value: "sas-sssd-server"
      image: sas-sssd-server
      imagePullPolicy: IfNotPresent
      name: sssd
      lifecycle:
        preStop:
          exec:
            command: ["bash", "-c", "kill -SIGKILL \$(ps -Af | grep '/opt/sas/viya/home/bin/consul-template'  | grep -v grep | awk '{print \$2}'); kill -SIGKILL \$(ps -Af | grep '/sbin/sssd'  | grep -v grep | awk '{print \$2}')"]
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
        readOnlyRootFilesystem: false
        runAsNonRoot: false
        runAsGroup: 0
        runAsUser: 0
      resources:
        requests:
          memory: 512Mi
          cpu: 100m
        limits:
          memory: 512Mi
          cpu: 100m
      envFrom:
      - configMapRef:
          name: sas-shared-config
      - configMapRef:
          name: sas-java-config
      - secretRef:
          name: sas-consul-client
      volumeMounts:
       - mountPath: /var/lib/sss
         name: sss
    volumes:
    - emptyDir: {}
      name: sss
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-container-sssd-mounts
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: sss
      emptyDir: {}
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
    value:
      name: sss
      mountPath: /var/lib/sss
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-add-sssd-psp
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/securityContext/readOnlyRootFilesystem
    value: false
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/securityContext/capabilities
    value: {}
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/securityContext/capabilities
    value:
       add: ["ALL"]
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-add-sssd-env
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/env/-
    value:
      name: SAS_POD_USES_SSSD
      value: "true"
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-kustomizeconfig.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/kustomizeconfig.yaml
nameReference:
- kind: ConfigMap
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/containers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/containers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/volumes/configMap/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/containers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/initContainers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/containers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/initContainers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/volumes/configMap/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/containers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/initContainers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/containers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/initContainers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/volumes/configMap/name
    kind: CASDeployment
- kind: Secret
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/containers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/volumes/secret/secretName
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/containers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/initContainers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/volumes/secret/secretName
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/containers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/initContainers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/volumes/secret/secretName
    kind: CASDeployment
- kind: Secret
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/imagePullSecrets/name
    kind: CASDeployment
  - path: spec/controllerTemplateAdditions/spec/imagePullSecrets/name
    kind: CASDeployment
  - path: spec/workerTemplateAdditions/spec/imagePullSecrets/name
    kind: CASDeployment
varReference:
  - path: spec/routeTemplate/spec/host
    kind: CASDeployment
  - path: spec/ingressTemplate/spec/rules/host
    kind: CASDeployment
  - path: spec/ingressTemplate/spec/tls/hosts
    kind: CASDeployment
EOF

echo "  |-provider-pvc.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/provider-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    sas.com/backup-role: "storage"
    app.kubernetes.io/part-of: cas
    sas.com/cas-pvc: backup
    sas.com/tenant: ${tenant}
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
  name: sas-cas-backup-data-${tenant}-${instance}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 4Gi
EOF

echo "  |-transfer-pvc.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/transfer-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/part-of: cas
    sas.com/cas-instance: ${tenant}-${instance}
    sas.com/cas-pvc: transfer
    sas.com/tenant: ${tenant}
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
  annotations:
    sas.com/component-name: sas-cas-operator
  name: sas-cas-transfer-data-${tenant}-${instance}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
EOF

echo "  |-enable-binary-port.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/enable-binary-port.yaml
# PatchTransformer to set and publish binary ports for CAS
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-publish-binary
patch: |-
   - op: add
     path: /spec/publishBinaryService
     value: true
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-enable-http-port.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/enable-http-port.yaml
# PatchTransformer to set and publish HTTP ports for CAS
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-publish-http
patch: |-
   - op: add
     path: /spec/publishHTTPService
     value: true
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-configmaps.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/configmaps.yaml
---
apiVersion: builtin
kind: ConfigMapGenerator
options:
  labels:
    app.kubernetes.io/part-of: cas
    sas.com/tenant: "${tenant}"
    casoperator.sas.com/tenant: "${tenant}"
    casoperator.sas.com/instance: "${instance}"
metadata:
  name: sas-cas-config-${tenant}-${instance}
literals:
- CASCLOUDNATIVE=1
EOF

echo "  |-state-transfer.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/state-transfer.yaml
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-support-state-transfer
patch: |-
  - op: add
    path: /spec/supportStateTransfer
    value: true
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/env/-
    value:
      name: K8S_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-node-affinity.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/node-affinity.yaml
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-node-affinity
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/affinity
    value:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
            - key: workload.sas.com/class
              operator: In
              values:
              - $affinity
        - weight: 1
          preference:
            matchExpressions:
            - key: workload.sas.com/class
              operator: NotIn
              values:
              - compute
              - stateless
              - stateful
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.azure.com/mode
              operator: NotIn
              values:
              - system
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                - sas-cas-server
            topologyKey: kubernetes.io/hostname

target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF


echo "  |-require-affinity.yaml"

  cat << EOF >> "${output}"cas-${tenant}-${instance}/require-affinity.yaml
# PatchTransformer to make the $affinity node label required
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: require-affinity-label
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/affinity/nodeAffinity/requiredDuringSchedulingIgnoredDuringExecution/nodeSelectorTerms/0/matchExpressions/-
    value:
      key: workload.sas.com/class
      operator: In
      values:
      - $affinity
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF



echo "  |-require-affinity-pools.yaml"

cat << EOF >> "${output}"cas-${tenant}-${instance}/require-affinity-pools.yaml
# PatchTransformer to make the $affinity node label required
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: require-affinity-label-pools
patch: |-
  - op: add
    path: /spec/controllerTemplateAdditions/spec/affinity
    value:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: workload.sas.com/class
              operator: In
              values:
              - ${affinity}controller

  - op: add
    path: /spec/workerTemplateAdditions/spec/affinity
    value:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: workload.sas.com/class
              operator: In
              values:
              - ${affinity}worker
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

#echo "[=======================================================================]"
echo ""
echo "create-cas-server.sh complete!"
echo ""

exit 0
