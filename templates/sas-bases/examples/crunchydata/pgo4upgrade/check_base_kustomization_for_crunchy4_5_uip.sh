#!/bin/bash
# Usage: 

set -o pipefail

# Function to log debug msg
f_log_debug() {
  if [ -n "$LOG_DEBUG" ]; then
    echo -e "$1"
  fi
} # f_log_debug


# Function to get the storage class from Crunchy 4 cluster
f_get_src_storage_class() {
  # Get the current storage class of the PVCs of the Postgres cluster
  if [ -z "$1" ] || [ "$1" != 'sas-crunchy-data-postgres' ] && [ "$1" != 'sas-crunchy-data-cdspostgres' ]; then
    echo "Usage: f_get_src_storage_class <cluster-name-under-crunchy4>.  Ex: f_get_src_storage_class sas-crunchy-data-postgres" >&2
    exit
  fi

  SRC_CLUSTER_NAME=$1

  SC_COUNT=$(kubectl -n "$NAMESPACE" get pvc -l pg-cluster="$SRC_CLUSTER_NAME,vendor=crunchydata" -o jsonpath='{.items[*].spec.storageClassName}' | tr ' ' '\n' | sort -u | wc -l)
  f_log_debug "SC_COUNT=$SC_COUNT for the cluster $SRC_CLUSTER_NAME"

  if [[ $SC_COUNT -eq 0 ]]; then
    if [ "$SRC_CLUSTER_NAME" = "sas-crunchy-data-postgres" ]; then
      echo "ERROR: storage class count SC_COUNT=$SC_COUNT is unexpected with $SRC_CLUSTER_NAME" >&2
      return
    else # sas-crunchy-data-cdspostgres
      SRC_CDS_SC="CDS-NOT-USED"
      return # There seems no cds postgres. All set.
    fi
  elif [[ $SC_COUNT -gt 1 ]]; then
    echo "ERROR: storage class count SC_COUNT=$SC_COUNT is unexpected. More than one storage classes transformers are being used for the cluster $SRC_CLUSTER_NAME. Manual intervention is needed. Continuing checking the storage class using the first storage class..." >&2
  fi

  # Get the (first) storage class name
  SRC_SC=$(kubectl -n "$NAMESPACE" get pvc -l pg-cluster="$SRC_CLUSTER_NAME,vendor=crunchydata" -o jsonpath='{.items[*].spec.storageClassName}' | tr ' ' '\n' | sort -u | head -1)
  f_log_debug "SRC_SC=$SRC_SC"

  # Assign it to a proper variable
  case $SRC_CLUSTER_NAME in
    sas-crunchy-data-postgres)
      SRC_PLATFORM_SC=$SRC_SC
      ;;
    sas-crunchy-data-cdspostgres)
      SRC_CDS_SC=$SRC_SC
      ;;    
  esac
  f_log_debug "SRC_PLATFORM_SC=$SRC_PLATFORM_SC"
  f_log_debug "SRC_CDS_SC=$SRC_CDS_SC"
} # f_get_src_storage_class


# Function to get the default storage class
f_get_default_storage_class() {
  DEFAULT_SC=$(kubectl -n "$NAMESPACE" get sc | grep '(default)' | awk '{print $1}')
  f_log_debug "DEFAULT_SC=$DEFAULT_SC"
} # f_get_default_storage_class


# Function to check the storage transformer and get the storage class name for Crunchy 5 cluster
f_check_storage_transformer() {
  STORAGE_TRANSFORMER_NAME=$1
  f_log_debug "STORAGE_TRANSFORMER_NAME=$STORAGE_TRANSFORMER_NAME"

  # Check Access Mode of Postgres instance and repo storages.  | awk '{print $1}' is to remove trailing spaces.
  ACCESS_MODE=$(awk -F"#" '{print $1}' "$STORAGE_TRANSFORMER_NAME" | grep -A 2 /spec/instances/0/dataVolumeClaimSpec/accessModes | tail -1 | awk -F"- " '{print $2}'  | awk '{print $1}'  | tr -d \" | tr -d \')
  f_log_debug "PG instance PVC ACCESS_MODE=$ACCESS_MODE"
  if [[ "$ACCESS_MODE" != "ReadWriteOnce" ]]; then
    echo "ERROR: Access mode '$ACCESS_MODE' was specified for Postgres instance. Only 'ReadWriteOnce' is supported as of now" >&2
  fi

  ACCESS_MODE=$(awk -F"#" '{print $1}' "$STORAGE_TRANSFORMER_NAME" | grep -A 2 /spec/backups/pgbackrest/repos/0/volume/volumeClaimSpec/accessModes | tail -1 | awk -F"- " '{print $2}' | awk '{print $1}'  | tr -d \" | tr -d \')
  f_log_debug "Repo PVC ACCESS_MODE=$ACCESS_MODE"
  if [[ "$ACCESS_MODE" != "ReadWriteOnce" ]]; then
    echo "ERROR: Access mode '$ACCESS_MODE' was specified for pgBackRest repo. Only 'ReadWriteOnce' is supported as of now" >&2
  fi

  # Get the storage class which will be compared against the existing PVC's storage class
  PG_SC=$(awk -F"#" '{print $1}' "$STORAGE_TRANSFORMER_NAME" | grep -A 1  /spec/instances/0/dataVolumeClaimSpec/storageClassName | tail -1 | awk -F": " '{print $2}' | awk '{print $1}'  | tr -d \" | tr -d \')
  REPO_SC=$(awk -F"#" '{print $1}' "$STORAGE_TRANSFORMER_NAME" | grep -A 1  /spec/backups/pgbackrest/repos/0/volume/volumeClaimSpec/storageClassName | tail -1 | awk -F": " '{print $2}' | awk '{print $1}'  | tr -d \" | tr -d \')
  f_log_debug "PG_SC=$PG_SC, REPO_SC=$REPO_SC"

  # Postgres instance storage class and the repo's storage class must be the same when the cluster is upgraded from the Crunchy4 cluster.
  if [ "$PG_SC" != "$REPO_SC" ]; then
    echo "ERROR: The postgres pod storage class '$PG_SC' is different from the repo's storage class '$REPO_SC'. They must be the same when migrated from the Crunchy 4. Manual intervention is needed." >&2
  fi

  # Check the cluster name
  TRANSFORMER_CLUSTER_NAME=$(awk -F"#" '{print $1}' "$STORAGE_TRANSFORMER_NAME" | grep -A3 target: | grep name: | awk -F": " '{print $2}' | awk '{print $1}'  | tr -d \" | tr -d \')
  f_log_debug "TRANSFORMER_CLUSTER_NAME=$TRANSFORMER_CLUSTER_NAME"
  case $TRANSFORMER_CLUSTER_NAME in
    sas-crunchy-platform-postgres)
      if [ -n "$TAR_PLATFORM_SC" ]; then
        echo "ERROR: The prior storage transformer has already set the storage class to $PG_SC" >&2
      fi
      TAR_PLATFORM_SC=$PG_SC
      ;;
    sas-crunchy-cds-postgres)
      if [ -n "$TAR_CDS_SC" ]; then
        echo "ERROR: The prior storage transformer has already set the storage class to $PG_SC" >&2
      fi
      TAR_CDS_SC=$PG_SC
      ;;
    '.*')
      if [ -n "$TAR_PLATFORM_SC" ]; then
        echo "ERROR: The prior storage transformer has already set the storage class to $PG_SC" >&2
      fi
      TAR_PLATFORM_SC=$PG_SC
      if [ -n "$TAR_CDS_SC" ]; then
        echo "ERROR: The prior storage transformer has already set the storage class to $PG_SC" >&2
      fi
      TAR_CDS_SC=$PG_SC
      ;;
    *)    
      echo "ERROR: Unexpected target cluster name '$CLUSTER_NAME' is found. Under Crunchy 5,  cluster name must be one of sas-crunchy-platform-postgres, sas-crunchy-cds-postgres, or .* for both clusters." >&2
      echo "ERROR: Setting target storage class failed ">&2
      ;;
  esac

  f_log_debug "TAR_PLATFORM_SC=$TAR_PLATFORM_SC, TAR_CDS_SC=$TAR_CDS_SC"
} # f_check_storage_transformer

#--------------------------------------------------------------
#                             Main
#--------------------------------------------------------------

# Check if the base kustomization file is found in the default directory
if [ -f "./kustomization.yaml" ]; then
  BASE_KUST_FILE="./kustomization.yaml"
else
  echo "ERROR: ./kustomization.yaml is not found. Change the default directory to \$deploy, the deployment asset top directory where the base kustomization file resides, and retry" >&2
  exit
fi

# Get the namespace
if [ -z "$1" ]; then
  echo "Usage: ./check_base_kustomization_for_crunchy4_5_uip.sh <namespace of the k8s cluster>" >&2
  exit
fi

NAMESPACE=$1

LOG_DEBUG=$2

# Check if kubectl works with the provided namespace
if ! kubectl -n "$NAMESPACE" get pod>/dev/null; then
  echo "ERROR: Getting kubectl get pgcluster CR failed. Check if KUBECONFIG or the provided namespace are correct. Check the k8s cluster" >&2
fi

BLOCK_NAME=""
PLATFORM_POSTGRES_OVERLAY=0
CDS_POSTGRES_OVERLAY=0
CRUNCHY_OPERATOR_OVERLAY=0
PLATFORM_POSTGRES_COMPONENT=0
CDS_POSTGRES_COMPONENT=0
UPGRADE_PLATFORM=0
UPGRADE_CDS=0
LINE_NUM=0
LINE_NUM_COMPONENTS=0
LINE_NUM_PLATFORM_COMPONENTS=0
LINE_NUM_CDS_COMPONENTS=0

while read -r LINE; do
  # Remove comments
  LINE=$(echo "$LINE" | awk -F'#' '{print $1}')
  if [ -z "$LINE" ]; then
    continue
  fi
  LINE_NUM=$((LINE_NUM + 1))
  if [[ "$LINE" = "resources:" || "$LINE" = "transformers:" || "$LINE" = "components:" || "$LINE" = "configMapGenerator:" || "$LINE" = "generators:" || "$LINE" = "secretGenerator:" || "$LINE" = "patches:" || "$LINE" = "configurations:" ]]; then
    BLOCK_NAME=$(echo "$LINE" | awk -F":" '{print $1}')
    f_log_debug "------------$BLOCK_NAME started"
    if [[ $BLOCK_NAME = 'components' ]]; then
      LINE_NUM_COMPONENTS=$LINE_NUM
    fi
  elif [[ "$LINE" =~ ^[a-zA-Z]+:$ ]]; then
    BLOCK_NAME='other'
    f_log_debug "------------$BLOCK_NAME started"
  elif [[ "$LINE" = "- sas-bases/overlays/postgres/platform-postgres" ]]; then
    if [[ $PLATFORM_POSTGRES_OVERLAY -eq 0 ]]; then
      PLATFORM_POSTGRES_OVERLAY=1
    else
      echo "ERROR: sas-bases/overlays/postgres/platform-postgres was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME != 'resources' ]]; then
      echo "ERROR: sas-bases/overlays/postgres/platform-postgres must be under 'resources:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/overlays/postgres/cds-postgres" ]]; then
    if [[ $CDS_POSTGRES_OVERLAY -eq 0 ]]; then
      CDS_POSTGRES_OVERLAY=1
    else
      echo "ERROR: sas-bases/overlays/postgres/cds-postgres was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME != 'resources' ]]; then
      echo "ERROR: sas-bases/overlays/postgres/cds-postgres must be under 'resources:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/overlays/crunchydata/postgres-operator" ]]; then
    if [[ $CRUNCHY_OPERATOR_OVERLAY -eq 0 ]]; then
      CRUNCHY_OPERATOR_OVERLAY=1
    else
      echo "ERROR: sas-bases/overlays/crunchydata/postgres-operator was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME != 'resources' ]]; then
      echo "ERROR: sas-bases/overlays/crunchydata/postgres-operator must be under 'resources:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/components/crunchydata/internal-platform-postgres" ]]; then
    if [[ $PLATFORM_POSTGRES_COMPONENT -eq 0 ]]; then
      PLATFORM_POSTGRES_COMPONENT=1
    else
      echo "ERROR: sas-bases/components/crunchydata/internal-platform-postgres was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME = 'components' ]]; then
      LINE_NUM_PLATFORM_COMPONENTS=$LINE_NUM
    else
      echo "ERROR: sas-bases/components/crunchydata/internal-platform-postgres must be under 'components:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/components/crunchydata/internal-cds-postgres" ]]; then
    if [[ $CDS_POSTGRES_COMPONENT -eq 0 ]]; then
      CDS_POSTGRES_COMPONENT=1
    else
      echo "ERROR: sas-bases/components/crunchydata/internal-cds-postgres was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME = 'components' ]]; then
      LINE_NUM_CDS_COMPONENTS=$LINE_NUM
    else
      echo "ERROR: sas-bases/components/crunchydata/internal-cds-postgres must be under 'components:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml" ]]; then
    if [[ $UPGRADE_PLATFORM -eq 0 ]]; then
      UPGRADE_PLATFORM=1
    else
      echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME != 'transformers' ]]; then
      echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml must be under 'transformers:'" >&2
    fi
  elif [[ "$LINE" = "- sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml" ]]; then
    if [[ $UPGRADE_CDS -eq 0 ]]; then
      UPGRADE_CDS=1
    else
      echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml was already there and found again" >&2
    fi
    if [[ $BLOCK_NAME != 'transformers' ]]; then
      echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml must be under 'transformers:'" >&2
    fi
  fi
  f_log_debug "BLOCK_NAME=$BLOCK_NAME\t$LINE|"

done < $BASE_KUST_FILE

f_log_debug "PLATFORM_POSTGRES_OVERLAY=$PLATFORM_POSTGRES_OVERLAY"
f_log_debug "CDS_POSTGRES_OVERLAY=$CDS_POSTGRES_OVERLAY"
f_log_debug "CRUNCHY_OPERATOR_OVERLAY=$CRUNCHY_OPERATOR_OVERLAY"
f_log_debug "PLATFORM_POSTGRES_COMPONENT=$PLATFORM_POSTGRES_COMPONENT"
f_log_debug "CDS_POSTGRES_COMPONENT=$CDS_POSTGRES_COMPONENT"
f_log_debug "UPGRADE_PLATFORM=$UPGRADE_PLATFORM"
f_log_debug "UPGRADE_CDS=$UPGRADE_CDS"
f_log_debug "LINE_NUM=$LINE_NUM"
f_log_debug "LINE_NUM_COMPONENTS=$LINE_NUM_COMPONENTS"
f_log_debug "LINE_NUM_PLATFORM_COMPONENTS=$LINE_NUM_PLATFORM_COMPONENTS"
f_log_debug "LINE_NUM_CDS_COMPONENTS=$LINE_NUM_CDS_COMPONENTS"

if [[ $PLATFORM_POSTGRES_OVERLAY -eq 0 ]]; then
  echo "ERROR: sas-bases/overlays/postgres/platform-postgres doesn't seem to be found. It must be specified under 'resources:'" >&2
fi

if [[ $PLATFORM_POSTGRES_COMPONENT -eq 0 ]]; then
  echo "ERROR: sas-bases/components/crunchydata/internal-platform-postgres doesn't seem to be found. It must be specified under 'components:'" >&2
fi

if [[ $CRUNCHY_OPERATOR_OVERLAY -eq 0 ]]; then
  echo "ERROR: sas-bases/overlays/crunchydata/postgres-operator doesn't seem to be found. It must be specified under 'resources:'" >&2
fi

if [[ $PLATFORM_POSTGRES_COMPONENT -eq 1 && $PLATFORM_POSTGRES_OVERLAY -eq 0 || $PLATFORM_POSTGRES_COMPONENT -eq 0 && $PLATFORM_POSTGRES_OVERLAY -eq 1 ]]; then
  echo "ERROR: platform-postgres resources must go together with platform-postgres component. One of them seems to be missing" >&2
fi

if [[ $CDS_POSTGRES_COMPONENT -eq 1 && $CDS_POSTGRES_OVERLAY -eq 0 || $CDS_POSTGRES_COMPONENT -eq 0 && $CDS_POSTGRES_OVERLAY -eq 1 ]]; then
  echo "ERROR: cds-postgres resources must go together with cds-postgres component. One of them seems to be missing" >&2
fi

if [[ $UPGRADE_PLATFORM -eq 1  ]]; then
  echo "INFO: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml is only for upgrade. After upgrade, remove it so that another upgrade may not be attempted in the future. For more details, see 'After Deployment Commands' section within 2022.10 Deployment Notes.">&2
else
  echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml is required under the 'transformers:' block in order to upgrade from Crunchy 4 to 5.">&2
  echo "INFO: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-platform-transformer.yaml is only for upgrade. After upgrade, remove it so that another upgrade may not be attempted in the future. For more details, see 'After Deployment Commands' section within 2022.10 Deployment Notes.">&2
fi

if [[ $CDS_POSTGRES_COMPONENT -eq 1  || $CDS_POSTGRES_OVERLAY -eq 1 ]]; then  # If either one of them is found, then it may indicate that cds postgres is there.
  if [[ $UPGRADE_CDS -eq 1 ]]; then
    echo "INFO: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml is only for upgrade. After upgrade, remove it so that another upgrade may not be attempted in the future. For more details, see 'After Deployment Commands' section within 2022.10 Deployment Notes.">&2
  else
    echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml is required under the 'transformers:' block in order to upgrade from Crunchy 4 to 5.">&2
    echo "INFO: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml is only for upgrade. After upgrade, remove it so that another upgrade may not be attempted in the future. For more details, see 'After Deployment Commands' section within 2022.10 Deployment Notes.">&2
  fi
else
  if [[ $UPGRADE_CDS -eq 1 ]]; then
    echo "ERROR: sas-bases/examples/crunchydata/pgo4upgrade/crunchy-upgrade-cds-transformer.yaml exists, but there seems no resources nor components defined for cds-postgres">&2
  fi
fi

# Platform postgres component and cds postgres component must be the first two line under component block so that they may be before tls components in order to have tls generated correctly.
if [[ $LINE_NUM_COMPONENTS -eq 0 ]]; then
  echo "components block seems to be missing">&2
else
  if [[ $LINE_NUM_CDS_COMPONENTS -eq 0 ]]; then
    # If cds postgres is not used, then platform component must be the first within the component block
    if [[ $LINE_NUM_PLATFORM_COMPONENTS -ne $((LINE_NUM_COMPONENTS + 1)) ]]; then
      echo "ERROR: Postgres components must be listed before any other components in the component block in order to properly generate tls">&2
    fi
  else
    if [[ $LINE_NUM_PLATFORM_COMPONENTS -ne $((LINE_NUM_COMPONENTS + 1)) && $LINE_NUM_PLATFORM_COMPONENTS -ne $((LINE_NUM_COMPONENTS + 2)) || \
      $LINE_NUM_CDS_COMPONENTS -ne $((LINE_NUM_COMPONENTS + 1)) && $LINE_NUM_CDS_COMPONENTS -ne $((LINE_NUM_COMPONENTS + 2)) ]]; then
        echo "ERROR: Postgres components must be listed before any other components in the component block in order to properly generate tls">&2
    fi
  fi
fi
# Check if any Crunchy 4 entries are left in the base kust file
if awk -F'#' '{print $1}'  $BASE_KUST_FILE | grep -E 'pgo-client|crunchydata_pgadmin|patroni-custom-config|pghba-custom-config|postgres-custom-config|postgres-pods-resource-limits-settings|postgres-replicas-transformer|postgres-storage-transformer|overlays/internal-postgres|overlays/internal-postgres/cdspostgres'; then
  echo "ERROR: Some entries in $BASE_KUST_FILE seem to be of Crunchy 4. Please review and replace them with new transformers under Crunchy 5" >&2
fi

# Check the storage class.
SRC_PLATFORM_SC=""
SRC_CDS_SC=""

# Get Crunchy4 storage classes for each cluster
f_get_src_storage_class sas-crunchy-data-postgres
f_get_src_storage_class sas-crunchy-data-cdspostgres

# Get the current default storage class
f_get_default_storage_class

# Get crunchy5 storage class names specified in the transformer or in the default.
TAR_PLATFORM_SC=""
TAR_CDS_SC=""

if [[ $(awk -F"#" '{print $1}' "$BASE_KUST_FILE" | grep -c 'storage-transformer.yaml') -ge 1 ]]; then 
  STORAGE_TRANSFORMER_FILE_LIST=$(awk -F"#" '{print $1}' "$BASE_KUST_FILE" | grep 'storage-transformer.yaml' | awk -F"- " '{print $2}' | awk '{print $1}' )
  f_log_debug "STORAGE_TRANSFORMER_FILE_LIST=$STORAGE_TRANSFORMER_FILE_LIST"
  for STORAGE_TRANSFORMER_FILE_1 in $STORAGE_TRANSFORMER_FILE_LIST; do
    f_check_storage_transformer "$STORAGE_TRANSFORMER_FILE_1"
  done
fi

# If storage class is not defined through a transformer, then use the default
if [ -z "$TAR_PLATFORM_SC" ]; then
  TAR_PLATFORM_SC=$DEFAULT_SC
  f_log_debug "TAR_PLATFORM_SC is set to the default, '$DEFAULT_SC'"
fi
if [ -z "$TAR_CDS_SC" ]; then
  TAR_CDS_SC=$DEFAULT_SC
  f_log_debug "TAR_CDS_SC is set to the default, '$DEFAULT_SC'"
fi


# Check if the storage class matches between the source side (Crunchy 4 cluster) and the target side (Crunchy 5 cluster)
f_log_debug "SRC_PLATFORM_SC=$SRC_PLATFORM_SC, TAR_PLATFORM_SC=$TAR_PLATFORM_SC"
if [ -n "$SRC_PLATFORM_SC" ] && [ "$SRC_PLATFORM_SC" != "$TAR_PLATFORM_SC" ]; then
  echo "ERROR: For platform postgres, storage class '$SRC_PLATFORM_SC' under Crunchy 4 does not match with the storage class '$TAR_PLATFORM_SC' under Crunchy 5" >&2
fi
f_log_debug "SRC_CDS_SC=$SRC_CDS_SC, TAR_CDS_SC=$TAR_CDS_SC"
if [ "$SRC_CDS_SC" != "CDS-NOT-USED" ] && [ "$SRC_CDS_SC" != "$TAR_CDS_SC" ]; then
  echo "ERROR: For cds postgres, storage class '$SRC_CDS_SC' under Crunchy 4 does not match with the storage class '$TAR_CDS_SC' under Crunchy 5" >&2
fi
