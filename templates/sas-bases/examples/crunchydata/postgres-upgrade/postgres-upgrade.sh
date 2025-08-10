#!/bin/bash
# Description:
#   This script executes the steps to upgrade the PostgreSQL server to a newer major version for the SAS internal PostgreSQL server, based on Crunchy Postgres.
#   If your SAS Viya platform deployment uses an external PostgreSQL server, do not execute this script.
#   See the 2024.09 Deployment Notes for details about how to execute this script.

set -o pipefail

# Enable alias expansion
shopt -s expand_aliases

# Check parameters
if [[ "$#" -lt "3" ]]; then
  echo "Usage: $BASH_SOURCE <kubeconfig> <namespace> <update-target-manifests-file> [log-debug] [sas-crunchy-platform-postgres|sas-crunchy-cds-postgres]" >&2
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "KUBECONFIG '$1' does not exist" >&2
  echo "Usage: $BASH_SOURCE <kubeconfig> <namespace> <update-target-manifests-file> [log-debug] [sas-crunchy-platform-postgres|sas-crunchy-cds-postgres]" >&2
  exit 1
fi
if [[ ! -f "$3" ]]; then
  echo "manifests file '$3' does not exist. Or, prior parameters might have been provided through undefined env vars, causing the parameters shifted" >&2
  echo "Usage: $BASH_SOURCE <kubeconfig> <namespace> <update-target-manifests-file> [log-debug] [sas-crunchy-platform-postgres|sas-crunchy-cds-postgres]" >&2
  exit 1
fi

export KUBECONFIG="$1"
NAMESPACE="$2"
MANIFESTS_FILE="$3"
LOG_DEBUG="$4"  # Optional for internal use to dump more log info
CLUSTER_NAME_PARM="$5"  # Optional for internal use: Upgrade only the specified cluster. If not specified, both clusters are upgraded.

# Check NAMESPACE and cluster
if ! kubectl get ns "$NAMESPACE" -o name; then
  echo "Error getting the namespace $NAMESPACE" >&2
  echo "Usage: $BASH_SOURCE <kubeconfig> <namespace> <update-target-manifests-file> [log-debug] [sas-crunchy-platform-postgres|sas-crunchy-cds-postgres]" >&2
  exit 1
fi
if [ -n "$CLUSTER_NAME_PARM" ]; then
    if ! kubectl get postgrescluster "$CLUSTER_NAME_PARM" -o name -n "$NAMESPACE"; then
    echo "Error returned from kubectl get postgrescluster '$CLUSTER_NAME_PARM' -o name -n '$NAMESPACE'" >&2
    echo "Usage: $BASH_SOURCE <kubeconfig> <namespace> <update-target-manifests-file> [log-debug] [sas-crunchy-platform-postgres|sas-crunchy-cds-postgres]" >&2
    exit 1
    fi
fi

# Create a log dir if not existing
LOGDIR=~/pgupgrade-log
mkdir -p $LOGDIR

LOGX="pg-up-$(date +'%m%d-%H%M%S')"
PGO_FQDN="postgres-operator.crunchydata.com"
PGO_LABEL="$PGO_FQDN/control-plane=postgres-operator"
fromPostgresVersion=12  # Upgrade 'from' & 'to' versions should match with PGUpgrade CR 'fromPostgresVersion:' & 'toPostgresVersion:'.
toPostgresVersion=16    # The lifecycle operation 'deploy-pre-crunchy5' also has these hard-coded versions which must match with each other.

alias kc='kubectl -n $NAMESPACE '

# Function to log debug msg
f_log_debug() {
  if [ -n "$LOG_DEBUG" ]; then
    echo -e "DEBUG: $1"
  fi
} # f_log_debug

f_check_return_code() {
    return_code=$1
    str1=$2
    if [ "$return_code" -ne 0 ]; then
        echo "error from ${FUNCNAME[1]}: '$str1': return code: $return_code"  >&2   # ${FUNCNAME[1]}: caller of this function
        echo "Postgres Upgrade script is not idempotent, so do not retry. Contact SAS Technical Support to remediate the incomplete upgrade. Retrying may make the Postgres cluster unrecoverable"
        echo "Exiting"
        exit "$return_code"
    fi
} # f_check_return_code

f_return_rc_on_error() {
    return_code=$1
    str1=$2
    if [ "$return_code" -ne 0 ]; then
        echo "error from ${FUNCNAME[1]}: '$str1': return code: $return_code"  >&2   # ${FUNCNAME[1]}: caller of this function
    fi
    return "$return_code"
} # f_check_return_code

f_error_exit() {
    error_msg=$1
    echo "error: $error_msg"  >&2
    echo "Postgres Upgrade script is not idempotent, so do not retry. Contact SAS Technical Support to remediate the incomplete upgrade. Retrying may make the Postgres cluster unrecoverable"
    exit 1
} # f_error_exit

f_check_pgversion() {
    expected_pg_version="$1"
    echo
    echo "Checking PostgreSQL version..."

    if [ -z "$expected_pg_version" ]; then
        echo "error from ${FUNCNAME[0]}: Version parameter is missing" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi

    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        # Get the cluster's primary pod
        pod1=$(kc get pods --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" -o jsonpath="{.items[*].metadata.name}")
        return_code=$?
        f_log_debug "pod1: $pod1"
        if [ "$return_code" -ne 0 ] || [ -z "$pod1" ]; then
            echo "error from ${FUNCNAME[0]}: error finding the primary pod of $CLUSTER_NAME. The cluster may be down. Bring up the cluster and retry."  >&2
            exit "$return_code"
        fi

        # Get the Postgres version using psql
        pg_version=$( kc exec $pod1 -c database -- psql --tuples-only --command='SELECT version()' 2>/dev/null | cut -f1 -d'.' | cut -f3 -d' ')
        f_check_return_code "$?" "kc exec $pod1 -c database -- psql --tuples-only --command='SELECT version()' ..."
        f_log_debug "pg_version: $pg_version"

        # Check the obtained version against the expected version
        if [[ "$pg_version" != "$expected_pg_version" ]]; then
            echo "error from ${FUNCNAME[0]}: The current PostgreSQL version $pg_version of $CLUSTER_NAME is different from what is expected. It is expected to be $expected_pg_version."  >&2
            exit 1
        fi
        echo "PostgreSQL version $pg_version of $CLUSTER_NAME matches the expected version $expected_pg_version."
    done

    # Display successful upgrade message
    if [[ "$expected_pg_version" = "$toPostgresVersion" ]]; then
        echo "***********************************************"
        echo "Postgres Upgrade from $fromPostgresVersion to $toPostgresVersion is successful!"
        echo "***********************************************"
    fi
} # f_check_pgversion


f_delete_pgupgrade_cr_annotation() {
    echo
    echo "Deleting PGUpgrade CustomResources if exists..."
    # Delete all pgupgrade CRs.
    # The command always returns the return code 0. If CR doesn't exists, it displays 'No resources found'.
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        kc delete pgupgrade "${CLUSTER_NAME}-upgrade" 2>/dev/null
        echo "Deleting annotations if exists..."
        # Delete annotations by suffixing (-) to the annotations.
        # The command always displays '...annotated', and alwyas returns the return code 0 regardless that the annotation exists or not.
        kc annotate postgrescluster "$CLUSTER_NAME" postgres-operator.crunchydata.com/allow-upgrade-
    done
} # f_delete_pgupgrade_cr_annotation

f_wait_object_created() {
    # Function to check if the object is existing, and if not, wait for its creation.

    object_to_wait=$1
    selector=$2

    max_wait=180 # Maximum wait time in seconds
    interval=5  # Interval between checks in seconds
    total_wait=0

    echo "Checking the object type '$object_to_wait' of '$selector'..."
    while true; do
        if [ $total_wait -ge $max_wait ]; then
            echo "Timed out waiting for the object $object_to_wait of '$selector'. Max wait time: $max_wait." >&2
            exit 1
        fi

        # Check if the object exists
        obj1=$(kc get $object_to_wait --selector="$selector" -o jsonpath="{.items[*].metadata.name}")
        if [ -n "$obj1" ]; then
            # If the object was not found at the first try, then log the wait time
            if [ $total_wait -gt 0 ]; then
                echo "Object $object_to_wait of '$selector' found after $total_wait seconds"
            fi
            return 0
        fi

        # Object does not exists. Wait to be created. Log only at the first loop
        if [ $total_wait -eq 0 ]; then
            echo "Object $object_to_wait of '$selector' waiting to be created..."
        fi

        sleep $interval
        total_wait=$((total_wait + interval))
    done
} # f_wait_object_created

f_shutdown_dso() {
    echo
    echo "Shutting down Data Server Operator..."
    kc scale deploy --replicas=0 sas-data-server-operator
    f_check_return_code "$?" "scale deploy --replicas=0 sas-data-server-operator"

    echo "Waiting for Data Server Operator to be down..."
    kc wait pods --for=delete --selector="app.kubernetes.io/name=sas-data-server-operator" --timeout=300s
    f_check_return_code "$?" "wait --for=delete --selector=\"app.kubernetes.io/name=sas-data-server-operator\" pods --timeout=300s"

    # Check if a pod is still there
    pod1=$(kc get pods --selector="app.kubernetes.io/name=sas-data-server-operator" -o jsonpath="{.items[*].metadata.name}")
    f_log_debug "pod1: $pod1"
    if [ -n "$pod1" ]; then
        f_error_exit "Data Server Operator pod still found"
    fi
} # f_shutdown_dso

f_drop_replicas() {
    echo
    echo "Dropping replicas..."
    # Repeat for Postgres cluster
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        f_log_debug "${FUNCNAME[0]} for $CLUSTER_NAME"  # ${FUNCNAME[0]} is the current function

        kc patch postgrescluster/$CLUSTER_NAME --type json --patch '[{"op":"replace", "path": "/spec/instances/0/replicas", "value": 1}]'
        f_check_return_code "$?" "patch postgrescluster/$CLUSTER_NAME --type json --patch ..."

        kc wait --for=delete --selector="$PGO_FQDN/role=replica,$PGO_FQDN/cluster=$CLUSTER_NAME" pods --timeout=300s
        f_check_return_code "$?" "wait --for=delete --selector=\"$PGO_FQDN/role=replica,$PGO_FQDN/cluster=$CLUSTER_NAME\" pods --timeout=300s"

        # Check if a pod is still there
        pod1=$(kc get pods --selector="$PGO_FQDN/role=replica,$PGO_FQDN/cluster=$CLUSTER_NAME" -o jsonpath="{.items[*].metadata.name}")
        f_log_debug "pod1: $pod1"
        if [ -n "$pod1" ]; then
            f_error_exit "Replica pod still found"
        fi
    done
} # f_drop_replicas

f_get_checksum() {
    # This simple function is to work around the syntax issue of the command.
    primary_pod="$1"

    if [ -z "$primary_pod" ]; then
        echo "error from ${FUNCNAME[0]}: Primary pod was not passed in" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi
    # Do not generate any other output (do not use any echo) because outputs will become the return value of this function.
    kc exec -c database "$primary_pod" -- psql -t -A -c "show data_checksums"
    f_return_rc_on_error "$?" "kc exec $primary_pod -c database -- psql -t -A -c 'show data_checksums'"
} # f_get_checksum


f_get_proc_cnt() {
    # This simple function is to work around the syntax issue of the command.
    cluster_name="$1"
    primary_pod="$2"

    if [ -z "$cluster_name" ] || [ -z "$primary_pod" ]; then
        echo "error from ${FUNCNAME[0]}: Missing parameters. Passed-in cluster name is $cluster_name and primary pod is $primary_pod" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi

    # Do not generate any other output (do not use any echo) because outputs will become the return value of this function.
    kc exec -it "$primary_pod" -c database -- bash -c "ps xf | grep $cluster_name | grep -v grep | wc -l"
    f_return_rc_on_error "$?" "kc exec $primary_pod -c database -- bash -c 'ps xf | grep $cluster_name | grep -v grep | wc -l' "
} # f_get_proc_cnt


f_wait_for_postgres() {
    if [[ "$#" -lt "3" ]]; then
    echo "Usage: ${FUNCNAME[0]} <cluster_name> <primary_pod> <started|stopped>" >&2
    exit 1
    fi
    cluster_name="$1"
    primary_pod="$2"

    if [ "$3" = "started" ] || [ "$3" = "stopped" ]; then
        desired_state="$3"
    else
        echo "error from ${FUNCNAME[0]}: Desired state $3 is unexpected. It must be 'started' or 'stopped'" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi

    # Wait until the Postgres processes are started
    echo "Waiting for Postgres for desired state '$desired_state'"
    max_wait=180 # Maximum wait time in seconds
    interval=5  # Interval between checks in seconds
    total_wait=0

    while true; do
        if [ $total_wait -ge $max_wait ]; then
            echo "Timed out waiting for Postgres $desired_state. Max wait time: $max_wait." >&2
            return 1
        fi

        if [ "$total_wait" -eq 0 ] ; then
            echo "Call f_get_proc_cnt $cluster_name $primary_pod | tr -d '\r'"
        fi
        proc_cnt=$(f_get_proc_cnt "$cluster_name" "$primary_pod" | tr -d '\r')
        return_code=$?

        if [ "$total_wait" -eq 0 ] ; then
            f_log_debug "proc_cnt: $proc_cnt"
        fi
        if [ "$return_code" -ne 0 ] || [ -z "$proc_cnt" ]; then
            echo "error from ${FUNCNAME[0]}: error getting the process count"  >&2
            return "$return_code"
        fi

        if [ "$desired_state" = "started" ]; then
            if [ "$proc_cnt" -gt 5 ]; then   # 5 is only for key procs. Normally, 10.
                # Postgres is up.
                echo "Postgres $desired_state after $total_wait seconds"
                return 0
            else
                echo "Postgres is still not ready. Wait $interval more seconds"
            fi
        else # desired_state is 'stopped'
            if [ "$proc_cnt" -eq 0 ]; then  # PG process is not running
                echo "Postgres $desired_state after $total_wait seconds"
                return 0
            else
                echo "Postgres process is still running. Wait $interval more seconds"
            fi
        fi

        # For DEBUG: kc exec -it "$primary_pod" -c database -- bash -c "ps xf | grep $cluster_name | grep -v grep"

        sleep $interval
        total_wait=$((total_wait + interval))
    done

    sleep 3  # just to ensure everything is in sync
} # f_wait_for_postgres


f_update_checksum() {
    # Enable or disable checksum.
    cluster_name="$1"
    primary_pod="$2"
    update_mode="$3"

    if [ -z "$cluster_name" ] || [ -z "$primary_pod" ] || [ -z "$update_mode" ]; then
        echo "error from ${FUNCNAME[0]}: Missing parameters. Passed-in cluster name is $cluster_name, primary pod is $primary_pod, and update mode is $update_mode" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi

    if [ "$update_mode" = "enable" ] || [ "$update_mode" = "disable" ]; then
        update_sw="--$update_mode"
    else
        echo "error from ${FUNCNAME[0]}: Unexpected update mode $update_mode was passed in" >&2  # ${FUNCNAME[0]}: current function
        exit 1
    fi

    echo "Updating cluster $cluster_name to $update_mode checksum on the primary pod $primary_pod..."

    # Temporarily pause the cluster management of Crunchy Operator
    echo "kc patch postgrescluster $cluster_name --type merge --patch '{\"spec\":{\"paused\": true}}"
    kc patch postgrescluster "$cluster_name" --type merge --patch '{"spec":{"paused": true}}'
    if ! f_return_rc_on_error "$?" "kc patch postgrescluster $cluster_name --type merge --patch '{\"spec\":{\"paused\": true}}"; then
        return 1
    fi

    update_checksum_status="failed"

    # Temporarily pause patroni operations
    echo "kc exec -it $primary_pod -c database -- patronictl pause"
    kc exec -it "$primary_pod" -c database -- patronictl pause
    if f_return_rc_on_error "$?" "kc exec -it $primary_pod -c database -- patronictl pause"; then

        echo "kc exec -it $primary_pod -c database -- pg_ctl stop -D /pgdata/pg12 -m fast"
        kc exec -it "$primary_pod" -c database -- pg_ctl stop -D /pgdata/pg12 -m fast
        if f_return_rc_on_error "$?" "kc exec -it $primary_pod -c database -- pg_ctl stop -D /pgdata/pg12 -m fast"; then

            if f_wait_for_postgres $cluster_name $primary_pod stopped; then
                # Run pg_checksums binary
                start_time=$(date)
                echo "kc exec -it $primary_pod -c database -- pg_checksums $update_sw --pgdata /pgdata/pg12 --progress --verbose > $LOGDIR/$LOGX-09-pg_checksums-$cluster_name.log 2>&1"
                kc exec -it "$primary_pod" -c database -- pg_checksums $update_sw --pgdata /pgdata/pg12 --progress --verbose > $LOGDIR/$LOGX-09-pg_checksums-$cluster_name.log 2>&1

                if f_return_rc_on_error "$?" "kc exec -it $primary_pod -c database -- pg_checksums $update_sw --pgdata /pgdata/pg12 --progress --verbose"; then
                    update_checksum_status="successful"
                fi

                end_time=$(date)
                time_diff=$(date -u -d "@$(($(date -d "$end_time" +%s) - $(date -d "$start_time" +%s)))" +"%H:%M:%S")
                echo "Time taken to $update_mode checksum: $time_diff. Status: $update_checksum_status"
            fi # if wait was successful
        fi # if pg_ctl stop
    fi # if patroni pause

    # Try reversing the temp 'pause' whether there was an error or not. Ignore any error of the commands.

    # Resume patroni operations. This starts the Postgres process.
    echo "kc exec -it $primary_pod -c database -- patronictl resume"
    kc exec -it "$primary_pod" -c database -- patronictl resume
    f_return_rc_on_error "$?" "kc exec -it $primary_pod -c database -- patronictl resume"

    f_wait_for_postgres "$cluster_name" "$primary_pod" started
    f_return_rc_on_error "$?" "f_wait_for_postgres $cluster_name $primary_pod started"

    # Check the Postgres cluster status
    echo "kc exec -it $primary_pod -c database -- patronictl list"
    kc exec -it "$primary_pod" -c database -- patronictl list
    f_return_rc_on_error "$?" "kc exec -it $primary_pod -c database -- patronictl list"

    # Check if the PG checksum setting is "on"
    checksum_setting=$(f_get_checksum "$primary_pod" | tr -d '\r')
    echo "checksum setting is '$checksum_setting'"

    # Resume the cluster management of Crunchy Operator
    echo "kc patch postgrescluster $cluster_name --type merge --patch '{\"spec\":{\"paused\": false}}'"
    kc patch postgrescluster "$cluster_name" --type merge --patch '{"spec":{"paused": false}}'
    f_return_rc_on_error "$?" "kc patch postgrescluster $cluster_name --type merge --patch '{\"spec\":{\"paused\": false}}'"
    sleep 3

    if [ "$update_checksum_status" = "successful" ]; then
        return 0
    else
        return 1
    fi
} # f_update_checksum


f_check_checksum_setting() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Checking checksum setting for $CLUSTER_NAME..."
        # Get the cluster's primary pod
        pod1=$(kc get pods --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" -o jsonpath="{.items[*].metadata.name}")
        return_code=$?
        f_log_debug "pod1: $pod1"
        if [ "$return_code" -ne 0 ] || [ -z "$pod1" ]; then
            echo "error from ${FUNCNAME[0]}: error finding the primary pod of $CLUSTER_NAME. The cluster may be down. Bring up the cluster and retry."  >&2
            exit "$return_code"
        fi

        echo "Call f_get_checksum $pod1 | tr -d '\r'"
        checksum_setting=$(f_get_checksum "$pod1" | tr -d '\r')
        return_code=$?
        f_log_debug "checksum_setting: $checksum_setting"
        if [ "$return_code" -ne 0 ] || [ -z "$checksum_setting" ]; then
            echo "error from ${FUNCNAME[0]}: error getting the checksum setting. The cluster may be down. Bring up the cluster and retry."  >&2
            exit "$return_code"
        fi

        if [ "$checksum_setting" = "on" ]; then
            # Checksum is on. All set. Continue next loop.
            continue
        elif [ "$checksum_setting" = "off" ]; then
            # Checksum is "off". Enable it.
            if ! f_update_checksum "$CLUSTER_NAME" "$pod1" "enable"; then
                echo "error from ${FUNCNAME[0]}: error returned from running f_update_checksum $CLUSTER_NAME $pod1 enable"  >&2
                exit 1
            fi
        else
            # The checksum setting was returned other than "on" or "off".
            echo "error from ${FUNCNAME[0]}: Unexpected checksum setting returned from $CLUSTER_NAME: $checksum_setting"  >&2
            exit 1
        fi
    done
} # f_check_checksum_setting


f_apply_crd() {
    echo
    echo "Applying Crunchy CRDs..."
    kubectl apply --selector="sas.com/admin=cluster-api,$PGO_LABEL" -f $MANIFESTS_FILE --server-side --force-conflicts
    f_check_return_code "$?" "apply --selector=\"sas.com/admin=cluster-api,$PGO_LABEL\" --server-side --force-conflicts -f $MANIFESTS_FILE"

    sleep 10  # To work around the kubectl issue (DEPENBDAT-2358)
    kubectl wait crd --for condition=established --selector="sas.com/admin=cluster-api,$PGO_LABEL" --timeout=60s
    f_check_return_code "$?" "wait crd --for condition=established --selector=\"sas.com/admin=cluster-api,$PGO_LABEL\" --timeout=60s"

    # Check if crds are found
    pod1=$(kc get crd --selector="sas.com/admin=cluster-api,$PGO_LABEL" -o jsonpath="{.items[*].metadata.name}")
    f_log_debug "pod1: $pod1"

    podc=$(echo $pod1 | wc -w)
    f_log_debug "podc: $podc"
    if [ "$podc" -ne 4 ]; then
        f_error_exit "CRD counts are not 4"
    fi
} # f_apply_crd


f_apply_pgo() {
    echo
    echo "Applying Crunchy Postgres Operator..."

    # Apply the image pull secret that is required to pull the new PGO image.
    echo "Apply a new image pull secret"
    yq e 'select((.kind == "Secret") and .metadata.name == "sas-image-pull-secrets-*")' $MANIFESTS_FILE |  kc apply -f-
    f_check_return_code "$?" "applying the new image pull secret failed"

    
    echo "Apply serviceaccount/pgo and role"
    kubectl apply --selector="sas.com/admin=cluster-wide,$PGO_LABEL" -f $MANIFESTS_FILE  # Creates serviceaccount/pgo and role.rbac.authorization.k8s.io/postgres-operator
    f_check_return_code "$?" "apply --selector=sas.com/admin=cluster-wide,$PGO_LABEL"

    # kc get serviceaccount --selector="sas.com/admin=cluster-wide,$PGO_LABEL"
    # kc get role --selector="sas.com/admin=cluster-wide,$PGO_LABEL"

    echo "Apply rolebinding"
    kubectl apply --selector="sas.com/admin=cluster-local,$PGO_LABEL" -f $MANIFESTS_FILE --prune # Creates rolebinding.rbac.authorization.k8s.io/postgres-operator
    f_check_return_code "$?" "apply --selector=sas.com/admin=cluster-local,$PGO_LABEL"

    # kc get rolebinding --selector="sas.com/admin=cluster-local,$PGO_LABEL"

    echo "Apply PGO deployment"
    kubectl apply --selector="sas.com/admin=namespace,$PGO_LABEL" -f $MANIFESTS_FILE --prune --prune-allowlist=autoscaling/v2/HorizontalPodAutoscaler # Creates deployment.apps/sas-crunchy5-postgres-operator
    f_check_return_code "$?" "apply --selector=sas.com/admin=namespace,$PGO_LABEL"

    pgo_deploy=$(kc get deploy --selector="sas.com/admin=namespace,$PGO_LABEL" -o jsonpath="{.items[*].metadata.name}")
    f_log_debug "pgo_deploy: $pgo_deploy"

    # Wait for the updated PGO deployment to be rolled out. Use either kc rollout status or kc wait --for=condition=available deployment.
    echo "Wait for PGO deployment to be rolled out"
    sleep 10  # To work around the potential kubectl wait issue
    kc rollout status deployment/$pgo_deploy --timeout=600s
    f_check_return_code "$?" "rollout status deployment/$pgo_deploy"

    # Wait for the pgcluster restarted
    # Restart happens node by node, so 'k wait' may exit before the restart is commenced or when one node is completed but the next node hasn't begun.
    # So, do 'k wait' up to (number-of-cluster * 2 nodes + 1 extra) times, giving time between.
    echo "Wait for pgclusters to be restarted by the new PGO"
    sleep 30  # Wait for the restart is commenced.
    max_try=$(( $CR_COUNT * 2 + 1 ))
    for i in $(seq 1 $max_try); do 
        echo "Wait loop: $i/$max_try";
        sleep 10  # Sleep to wait for the next node to begin.

        kc wait pods --for=condition=ready --selector="$PGO_FQDN/cluster,$PGO_FQDN/data" --timeout=600s
        f_check_return_code "$?" "wait pods --for=condition=ready --selector=$PGO_FQDN/cluster,$PGO_FQDN/data"
    done

    # Check if pgo pod is found. Note: If selector is used, k get always returns 0.
    pod1=$(kc get pod --selector="$PGO_LABEL" -o jsonpath="{.items[*].metadata.name}")
    f_log_debug "PGO pod: $pod1"
    if [ -z "$pod1" ]; then
        f_error_exit "PGO pod is not found"
    fi

    # Check if all expected resources were created. Note: Resource names are not allowed with --all-namespaces
    # kc get serviceaccount  --all-namespaces | grep pgo
    # kc get role.rbac.authorization.k8s.io --all-namespaces | grep postgres-operator
    # kc get rolebinding.rbac.authorization.k8s.io --all-namespaces | grep postgres-operator
    # kc get deployment.apps --all-namespaces | grep sas-crunchy5-postgres-operator
} # f_apply_pgo

f_backup_pgcluster() {
    echo "WARNING: f_backup_pgcluster was not tested enough. Use it in your own risk."
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Backup the cluster $CLUSTER_NAME..."
        REPO_POD=$(kc get pod --selector="$PGO_FQDN/data=pgbackrest,$PGO_FQDN/cluster=$CLUSTER_NAME" -o jsonpath='{.items[*].metadata.name}');
        # echo "Before the new backup:"
        # kc exec -it -c pgbackrest $REPO_POD -- pgbackrest info
        echo "Running a new backup: pgbackrest backup --stanza db --type=full..."
        kc exec -it -c pgbackrest $REPO_POD -- pgbackrest backup --stanza db --type=full
        f_check_return_code "$?" "pgbackrest backup"
        sleep 3

        echo "After the new backup:"
        kc exec -it -c pgbackrest $REPO_POD -- pgbackrest info
    done
} # f_backup_pgcluster

f_create_pgupgrade_cr() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        UPGRADE_CR_NAME="${CLUSTER_NAME}-upgrade"
        CR_LABEL="${CLUSTER_NAME}-pgupgrade"
        echo "Create PGUpgrade CR $UPGRADE_CR_NAME..."
        kc apply -f $MANIFESTS_FILE --selector="sas.com/pgupgrade-cr=${CR_LABEL}-cr"
        f_check_return_code "$?" "apply pgupgrade $UPGRADE_CR_NAME"

        # kc get pgupgrade

        # Check if pgupgrade CRs are found
        # Use '-o name' instead of '-o jsonpath="{.items[*].metadata.name}"' because a specific name is provided instead of a label selector.
        # When a specific name is provided, the 'item; wrapper block is not generated. 
        # '-o name' works with multiple names also.
        cr1=$(kc get pgupgrade "$UPGRADE_CR_NAME" -o name)
        f_check_return_code "$?" "get pgupgrade $UPGRADE_CR_NAME"
        f_log_debug "cr1: $cr1"
        if [ -z "$cr1" ]; then
            f_error_exit "PGUpgrade CR $UPGRADE_CR_NAME is not found"
        fi
    done
} # f_create_pgupgrade_cr

f_shutdown_pgcluster() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Shutting down the cluster, $CLUSTER_NAME..."
        kc patch postgrescluster/$CLUSTER_NAME --type json --patch '[{"op":"replace", "path": "/spec/shutdown", "value": true}]'
        f_check_return_code "$?" "patch postgrescluster shutdown"

        kc wait pods --for=delete --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/data" --timeout=300s
        f_check_return_code "$?" "wait pods --for=delete --selector=$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/data"

        # Check if all PG pods are deleted. Note: If selector is used, it always returns 0.
        pod1=$(kc get pod --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/data" -o jsonpath="{.items[*].metadata.name}")
        f_log_debug "pod1: $pod1"
        if [ -n "$pod1" ]; then
            f_error_exit "Postgres pods are left undeleted"
        fi
    done
} # f_shutdown_pgcluster

f_annotate_pgupgrade() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Annotate for the upgrade of $CLUSTER_NAME..."
        kc annotate postgrescluster $CLUSTER_NAME $PGO_FQDN/allow-upgrade="${CLUSTER_NAME}-upgrade"
        f_check_return_code "$?" "annotate postgrescluster pgupgrade"
        
        # Check the annotation
        cnt1=$(kc get postgrescluster $CLUSTER_NAME -o yaml | grep allow-upgrade | wc -l)
        f_check_return_code "$?" "get postgrescluster for pgupgrade annotation"
        f_log_debug "cnt1: $cnt1"
        if [ "$cnt1" -ne 1 ]; then
            f_error_exit "Annotation is missing or too many"
        fi
    done
} # f_annotate_pgupgrade

f_wait_pgupgrade() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Waiting for the $CLUSTER_NAME pgupgrade job to finish..."

        # Check if the object exists, and if not, then wait for it to be created
        f_wait_object_created "job" "$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/pgupgrade=${CLUSTER_NAME}-upgrade"

        # Wait for the job to be completed. Note: condition is NOT 'completed' BUT 'complete' (case insensitive)
        # Using '--timeout' makes a job failure case to wait until timeout instead returning at the failure.
        # But without '--timeout', the 'wait' returns 'timeout' prematurely. So, use it always.
        kc wait job --for=condition=complete --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/pgupgrade=${CLUSTER_NAME}-upgrade"  --timeout=7200s
        return_code=$?

        # Save the CR status block abd the pod logs.
        echo "============================get yaml output========================" >> $LOGDIR/$LOGX-20-CR-$CLUSTER_NAME-upgrade.log 2>&1
        kc get pgupgrade $CLUSTER_NAME-upgrade -o yaml >> $LOGDIR/$LOGX-20-CR-$CLUSTER_NAME-upgrade.log 2>&1
        echo "============================describe output========================" >> $LOGDIR/$LOGX-20-CR-$CLUSTER_NAME-upgrade.log 2>&1
        kc describe pgupgrade $CLUSTER_NAME-upgrade >> $LOGDIR/$LOGX-20-CR-$CLUSTER_NAME-upgrade.log 2>&1

        pod_list=$(kc get pod -o name | grep $CLUSTER_NAME-upgrade-pgdata | cut -d'/' -f2)
        for pod1 in $(echo "$pod_list"); do 
            kc logs $pod1 > $LOGDIR/$LOGX-20-POD-$pod1.log 2>&1
        done

        # Check the return code of kc wait job
        f_check_return_code "$?" "wait for pgupgrade job to complete or fails..."

        # Check if pgupgrade job is completed successfully. Note: the field name is status.**succeeded**, but the field-selector is status.**successful**.
        # Note: If a selector is used, it always returns 0.
        job1=$(kc get job --field-selector=status.successful=1 --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/pgupgrade=${CLUSTER_NAME}-upgrade" -o jsonpath="{.items[*].metadata.name}")
        if [ -z "$job1" ]; then
            f_error_exit "There is no successfully completed PGUpgrade job"
        fi
        f_log_debug "job1: $job1"

        # Check the status in a different way to be certain.
        job_name=$(kc get job --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/pgupgrade=${CLUSTER_NAME}-upgrade" -o jsonpath="{.items[*].metadata.name}")
        job_status=$(kc get job "$job_name" -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
        failed_pods=$(kc get job "$job_name" -o jsonpath='{.status.failed}')
        f_log_debug "job_name: $job_name, job_status: $job_status, failed_pods: $failed_pods"

        if [ "$job_status" == "True" ]; then
            echo "Job $job_name completed successfully."
        elif [ "$failed_pods" -gt 0 ]; then
            echo "Job $job_name failed." >&2
            echo "Postgres Upgrade script is not idempotent, so do not retry. Contact SAS Technical Support to remediate the incomplete upgrade. Retrying may make the Postgres cluster unrecoverable"
            exit 1
        else
            echo "Job $job_name is in an unknown state." >&2
            echo "Postgres Upgrade script is not idempotent, so do not retry. Contact SAS Technical Support to remediate the incomplete upgrade. Retrying may make the Postgres cluster unrecoverable"
            exit 1
        fi
    done
} # f_wait_pgupgrade

f_check_pgupgrade_status() {
    echo
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Checking the PGUpgrade CustomResource status for ${CLUSTER_NAME}-upgrade..."
        status_reason=$(kc get pgupgrade ${CLUSTER_NAME}-upgrade -o jsonpath="{.status.conditions[-1].reason}")  # -1 is last entry
        status_status=$(kc get pgupgrade ${CLUSTER_NAME}-upgrade -o jsonpath="{.status.conditions[-1].status}")
        status_type=$(kc get pgupgrade ${CLUSTER_NAME}-upgrade -o jsonpath="{.status.conditions[-1].type}")
        f_log_debug "status_reason: $status_reason, status_status: $status_status, status_type: $status_type"

        if [[ "$status_reason" == "PGUpgradeSucceeded" ]] && [[ "$status_status" == "True" ]] && [[ "$status_type" == "Succeeded" ]]; then
            echo "PGUpgrade was successful"
        else
            echo "error: PGUpgrade failed. Check the status block of PGUpgrade CustomResource and check log of the pgupgrade pod" >&2
            echo "Postgres Upgrade script is not idempotent, so do not retry. Contact SAS Technical Support to remediate the incomplete upgrade. Retrying may make the Postgres cluster unrecoverable"
            exit 1
        fi
    done
} # f_check_pgupgrade_status

f_start_pgcluster() {
    echo
    sleep 30  # To work around the kubectl issue (DEPENBDAT-2358)
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo "Applying Postgres new images to the upgraded cluster $CLUSTER_NAME..."
        kubectl apply --selector="sas.com/postgrescluster-cr=${CLUSTER_NAME}-postgrescluster-cr" -f "$MANIFESTS_FILE"
        f_check_return_code "$?" "apply --selector=sas.com/postgrescluster-cr=${CLUSTER_NAME}-postgrescluster-cr"
        sleep 10  # To work around the kubectl issue (DEPENBDAT-2358)

        # Wait for the primary pod running
        # PostgresCluster CR sets 'shutdown:' to false, so the cluster is started.
        # Check if the object exists, and if not, then wait for it to be created.
        f_wait_object_created "pod" "$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master"

        echo "Waiting for the primary node (leader) to be running..."
        kc wait pods --for=condition=ready --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" --timeout=300s
        f_check_return_code "$?" "wait pods --for=condition=ready --selector=$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master"

        # Double check if the primary pod is there before using it
        f_wait_object_created "pod" "$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master"

        # Get the pod. If a selector is used, then the return code is 0 even when there is none found.
        pod1=$(kc get pods --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" -o jsonpath="{.items[*].metadata.name}")
        f_check_return_code "$?" "get pods --selector=$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master"

        f_log_debug "pod1: $pod1"
        if [ -z "$pod1" ]; then
            f_error_exit "PG cluster primary pod not found"
        fi

        # # Show the cluster
        # echo "Displaying the cluster status for $CLUSTER_NAME using the pod $pod1..."
        # kc exec $pod1 -c database -- patronictl list
        # f_check_return_code "$?" "exec $pod1 -c database -- patronictl list"

        # echo "INFO: Creating replicas may take time if the database size is big, so the process continues without waiting for replicas to come up."
        # echo "      For now, safely ignore the 'unknown', 'stopped', or 'creating' for Replicas. The Postgres cluster works without replicas."
        # echo "      Check later if Replicas are 'streaming' by running: kubectl exec $pod1 -n $NAMESPACE -c database -- patronictl list"
    done
} # f_start_pgcluster

f_start_dso() {
    echo
    echo "Starting up Data Server Operator..."
    kc scale deploy --replicas=1 sas-data-server-operator
    f_check_return_code "$?" "scale deploy --replicas=1 sas-data-server-operator"

    # Wait the object to be created first before starting to wait for the condition.
    f_wait_object_created "pod" "app=sas-data-server-operator"

    kc wait pod --for=condition=ready --selector="app=sas-data-server-operator" --timeout=300s
    f_check_return_code "$?" "wait pod --for=condition=ready --selector=app=sas-data-server-operator"

    # Check if a pod is there. Note: If a selector is used, it always returns 0.
    pod1=$(kc get pods --selector="app.kubernetes.io/name=sas-data-server-operator" -o jsonpath="{.items[*].metadata.name}")
    if [ -z "$pod1" ]; then
        f_error_exit "Data Server Operator pod not found"
    fi
    kc get pod $pod1
    f_check_return_code "$?" "get pod $pod1"
} # f_start_dso

# Post-upgrade task: Upgrade extensions
f_post_upgrade_extension_upgrade() {
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo
        echo "Post-upgrade task for $CLUSTER_NAME: Upgrading Postgres extensions..."
        echo "Get the primary pod of $CLUSTER_NAME"

        # Get the cluster's primary pod
        pod1=$(kc get pods --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" -o name)
        return_code=$?
        if [ "$return_code" -ne 0 ] || [ -z "$pod1" ]; then
            echo "error from ${FUNCNAME[0]}: error finding the primary pod of $CLUSTER_NAME. The cluster may be down or is not healthy."  >&2
            exit "$return_code"
        fi
        f_log_debug "Primary pod is $pod1"

        # Run the script within the primary pod.
        # Do not use '-it' for exec. It is not interactive.
        # bash -c: commands;  -e: exit on error;  -u: undeclared variables are considered as an error
        # WARNING: Do not use (') within the bash code block because it is wrapped with single quotes.
        kc exec "$pod1" -c database -- /bin/bash -ceu '
logFile="/pgdata/upgrade_extensions.log"
echo > $logFile    # CAUTION: ">" overwrites the log file if exists while ">>" appends to it

# Show the current extension versions
echo "Before extensions are upgraded..." >> $logFile
psql -c "\dx" >> $logFile

# Show the content of the script that pg_upgrade created
echo >> $logFile
echo "Original script:" >> $logFile
cat /pgdata/update_extensions.sql >> $logFile

# Copy the script to a new file in order to edit it for pgaudit
cp /pgdata/update_extensions.sql /pgdata/drop_create_extensions.sql

# For the extension "pgaudit", replace "ALTER EXTENSION...UPDATE" with  "DROP/CREATE EXTENSION"  
# because it returns "ERROR:  extension pgaudit has no update path from version 1.4.3 to version 16.0"
sed -i "/pgaudit/c\DROP EXTENSION pgaudit;  CREATE EXTENSION pgaudit;" /pgdata/drop_create_extensions.sql
echo >> $logFile
echo "Updated script:" >> $logFile
cat /pgdata/drop_create_extensions.sql >> $logFile

# Execute the script through psql
echo >> $logFile
echo "Excute the ppdated script:" >> $logFile
psql -f /pgdata/drop_create_extensions.sql | tee -a $logFile

# Show the extension versions again
echo >> $logFile
echo "After extensions are upgraded..." >> $logFile
echo >> $logFile
psql -c "\dx" >> $logFile
echo "The log file $logFile was created within $(hostname) to show the details of the extension upgrades"
'
    done
} # f_post_upgrade_extension_upgrade


# Post-upgrade task: Vacuumdb for analyze only
f_post_upgrade_vacuumdb_analyze() {
    for CLUSTER_NAME in $(echo "$CLUSTER_NAME_LIST"); do
        echo
        echo "Post-upgrade task for $CLUSTER_NAME: Running vacuumdb with analyze-only..."
        echo "Get the primary pod of $CLUSTER_NAME"

        # Get the cluster's primary pod
        pod1=$(kc get pods --selector="$PGO_FQDN/cluster=$CLUSTER_NAME,$PGO_FQDN/role=master" -o name)
        return_code=$?
        if [ "$return_code" -ne 0 ] || [ -z "$pod1" ]; then
            echo "error from ${FUNCNAME[0]}: error finding the primary pod of $CLUSTER_NAME. The cluster may be down or is not healthy."  >&2
            exit "$return_code"
        fi
        f_log_debug "Primary pod is $pod1"

        # Run the command 'vacuumdb for all databases only analyzing data' within the primary pod.
        # Run it in a background process so that Viya Update process does not have to wait for the analyze to complete.
        # Do not use '-it' for exec. It is not interactive.
        kc exec $pod1 -c database -- /bin/bash -c 'nohup vacuumdb --verbose --all --analyze-only >/pgdata/vacuumdb-analyze-only.log 2>&1 &'
        echo "vacuumdb --analyze-only was submitted as a detached background job within $pod1."
        # echo "Its log file is /pgdata/vacuumdb-analyze-only.log within $pod1."
        echo "Continue Viya Update without waiting for the vacuumdb to be completed."
        echo "The PostgreSQL cluster may be used as normal while the vacuumdb runs."
    done
} # f_post_upgrade_vacuumdb_analyze


##############################################################
# Main body
##############################################################

# Check if there are Crunchy 4 CR. 
set +o pipefail
cr4_count=$(kc get pgcluster -o jsonpath="{.items[*].metadata.name}" 2>/dev/null | wc -w)
set -o pipefail
if [ "$cr4_count" -ne 0 ]; then
    echo "error: pgcluster CR is found. Upgrading directly from Crunchy 4 (2022.09 LTS) is not allowed. Upgrade to more recent LTS first and retry."  >&2
    exit 1
fi

# Check if yq is installed
yq --version
if [ "$?" -ne 0 ]; then
    echo "error: yq is required. Please install yq and retry." >&2
    exit 1
fi

# Check if the log dir is writable. Log files need to be created later.
if [ ! -w "$LOGDIR" ]; then
    echo "error: log files cannot be created in the current directory. Change directory to where log files can be written" >&2
    exit 1
fi

# Get the cluster list
if [ -n "$CLUSTER_NAME_PARM" ]; then
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        echo "This script is being sourced with a cluster name passed in."
        echo "Use that option only for debugging or recovering from a failed upgrade."
        echo "When sourced, the script just define functions without calling them. You have to call them one by one."
        echo "Note that f_apply_crd, f_apply_pgo, f_shutdown/start_dso are common between clusters."
        DEFINE_FUNCTIONS_ONLY="true"
    fi
    # Use the passed-in cluster name
    CLUSTER_NAME_LIST="$CLUSTER_NAME_PARM"
    CLUSTER_NAME="$CLUSTER_NAME_PARM"
    CR_COUNT=1
else
    # Get postgrescluster CR count
    f_log_debug 'kc get postgrescluster -o jsonpath="{.items[*].metadata.name}" | wc -w'
    set +o pipefail
    CR_COUNT=$(kc get postgrescluster -o jsonpath="{.items[*].metadata.name}" | wc -w)
    set -o pipefail

    # Make a cluster name list
    DEFINE_FUNCTIONS_ONLY="false"
    if [ "$CR_COUNT" -eq 1 ]; then
        CLUSTER_NAME_LIST="sas-crunchy-platform-postgres"
    elif [ "$CR_COUNT" -eq 2 ]; then
        CLUSTER_NAME_LIST="sas-crunchy-platform-postgres sas-crunchy-cds-postgres"
    else
        echo "error: unexpected PostgresCluster CustomResource count. Check 'kc get PostgresCluster'"  >&2
        exit 1
    fi
fi
f_log_debug "CLUSTER_NAME_LIST: $CLUSTER_NAME_LIST"

# If a cluster name was passed in, then return after defining functions so that the functions may be invoked manually to patch the upgrade process
if [[ $DEFINE_FUNCTIONS_ONLY == "true" ]]; then
    return 0  # return, not exit, in this case because we are sourcing this script to define functions and exit from the script. 'exit' terminates the current process. Then, all the defined functions will go away.
fi

# Ensure that the Postgres is at the 'from' version
f_check_pgversion "$fromPostgresVersion"

# Shutdown Data Server Operator
f_shutdown_dso

# Drop replicas from the Postgres clusters
f_drop_replicas

# If checksum is disabled, enable it
f_check_checksum_setting

# Apply Crunchy CRDs
f_apply_crd

# Apply PGO
f_apply_pgo

# Backup the Postgres clusters
# f_backup_pgcluster
# Skip this because of sporadic failure. Just document the requirement for backup.

# Delete PGUpgrade CRs and annotations if exists
f_delete_pgupgrade_cr_annotation

# Apply PGUpgrade CRs
f_create_pgupgrade_cr

# Shutdown the Postgres clusters.
f_shutdown_pgcluster

# Annotate to start the pgupgrade
f_annotate_pgupgrade

# Wait for the completion of the pgupgrade job
f_wait_pgupgrade

# Check the PGUpgrade status
f_check_pgupgrade_status

# Start the Postgres clusters with the new Postgres images
f_start_pgcluster

# Start back Data Server Operator
f_start_dso

# Ensure that the Postgres is now at the 'to' version
f_check_pgversion "$toPostgresVersion"

# Do not delete the PGUpgrade CR; let users decide when to delete.
# If it is left behind until next upgrade, it will be deleted at the top of this script.
# f_delete_pgupgrade_cr_annotation
# Document it to be deleted by users after everything is completed

# Post-upgrade task: Upgrade extensions
f_post_upgrade_extension_upgrade

# Post-upgrade task: Kick off the vacuumdb command to the background process
f_post_upgrade_vacuumdb_analyze
