---
category: cas
tocprty: 13
---

# State Transfer for CAS Server for the SAS Viya Platform

## Overview

This directory contains files to Kustomize your SAS Viya platform deployment to enable state transfers.
Enabling state transfers allows the sessions, tables, and state of a running CAS server to be preserved
between a running CAS server and a new CAS server instance which will be started as part of the CAS server upgrade.

**Note:** You cannot enable both CAS auto-restart and state transfer in the same SAS Viya platform deployment.  If you have already
enabled auto-restart, disable it before continuing.

## Instructions

### Edit the kustomization.yaml File

To add the new CAS server to your deployment:

1. Add a reference to the `state-transfer` overlay to the resources block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`).  This overlay adds a PVC to the deployment
to store the temporary state data during a state transfer.  This PVC is mounted to both the source and target system
and must be large enough to hold all session and global tables that are loaded at transfer time.
If you need to increase the size of the transfer PVC, consider using the `cas-modify-pvc-storage.yaml` example file.

   ```yaml
   resources:
   ...
   - sas-bases/overlays/cas-server/state-transfer
   ```

2. Add the state-transfer transformer to enable the state transfer feature to the deployment

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/cas-server/state-transfer/support-state-transfer.yaml
   ```
3. Determine the method to transfer the state. The model 'readonly' has a shorter
window where the server is unresponsive. However, during the transfer, attempts to alter
or create global tables will fail. The model 'suspend' has a longer window
where the server is unresponsive, and attempts to alter or create global tables will
wait until the transfer is complete.

   The default state transfer model is 'suspend'. If you want to specify a model at
deployment time, copy the `$deploy/sas-bases/examples/cas/configure/cas-add-environment-variables.yaml`
file to `$deploy/site-config/cas/configure/cas-add-environment-variables.yaml`, if you have
not already done so. In the copied file, change the value of CASCFG_STATETRANSFERMODEL
to the model you want to use. The model can also be changed by altering the CAS server option stateTransferModel.

   Here is an example of the code used to set the state transfer model to 'readonly'.

   ```yaml
   ...
   patch: |-
     - op: add
       path: /spec/controllerTemplate/spec/containers/0/env/-
       value:
         name: CASCFG_STATETRANSFERMODEL
         value: "readonly"
   ```

4. Decide if you want to limit the amount of data in individual sessions to be transferred.
The server will be unresponsive while session tables are transferred between the
original server and the new server. The length of this period of unresponsiveness can be
managed by setting the MAXSESSIONTRANSFERSIZE server option. Any session that has more data
loaded than the value of this option will not be transferred to the new session. The default
behavior is to impose no limit. Smaller values of this option can reduce the amount of time
that the server is unresponsive during a state transfer.

   If you want to specify a limit at deployment time, copy the
`$deploy/sas-bases/examples/cas/configure/cas-add-environment-variables.yaml`file to
`$deploy/site-config/cas/configure/cas-add-environment-variables.yaml`, if you have
not already done so. In the copied file, set the environment variable CASCFG_MAXSESSIONTRANSFERSIZE.

   Here is an example of the code used to set the session transfer size limit to 10 million bytes.

   ```yaml
   ...
   patch: |-
     - op: add
       path: /spec/controllerTemplate/spec/containers/0/env/-
       value:
         name: CASCFG_MAXSESSIONTRANSFERSIZE
         value: "10000000"
   ```

5. If you have changed the values CASCFG_STATETRANSFERMODEL or CASCFG_MAXSESSIONTRANSFERSIZE, add
a reference to the cas-add-environment-variables.yaml file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   transformers:
   ...
   - site-config/cas/configure/cas-add-environment-variables.yaml
   ```

   If you have already made some configuration changes for CAS, this entry may already exist
   in the transformers block.

## Build

After you configure Kustomize, continue your SAS Viya platform deployment as documented.
