---
category: cas
tocprty: 6
---

# Create an Additional CAS Server

## Overview

This README describes how to create additional CAS server definitions with the
`create-cas-server.sh` script. The script creates a Custom Resource (CR) that
can be added to your manifest and deployed to the Kubernetes cluster.

Running this script creates all of the artifacts that are necessary for
deploying a new CAS server in the Kubernetes cluster in one directory. The
directory can be referenced in the base `kustomization.yaml`.

**Note:** The script does not modify your Kubernetes cluster. It creates the manifests
that you can apply to your Kubernetes cluster to add a CAS server.

## Create a CAS Server

1. Run the `create-cas-server.sh` script and specify, at a minimum, the instance
   name. The instance name is used to label the server and differentiate it from
   the default instance that is provided automatically. The default tenant name
   is "shared" and provided automatically when multi-tenancy is not enabled in
   your deployment.

   ```bash
   ./create-cas-server.sh -i {{ INSTANCE }}
   ```

   The sample command creates a top-level directory `cas-{{ TENANT }}-{{ INSTANCE }}`
   that contains everything that is required for a new CAS server instance. For
   example, the directory contains the CR, PVC definitions for the permstore and
   data PVs, and so on.

   Optional arguments:

   * -o, --output: Output location. This argument is used to specify the parent
                     directory for the output. For example, you can specify
                     `-o $deploy/site-config`. If you do not create the output in that
                     directory, you should move the new directory to `$deploy/site-config`.
   * -w, --workers: Specify the number of CAS worker nodes. Default is 0 (SMP).
   * -b, --backup: Set this to include a CAS backup controller. Disabled by default.
   * -t, --tenant: Set the tenant name to be used for this deployment. Default is 'shared'.
   * -r, --transfer: Set this to enable support for state transfer between restarts. Disabled by default.
   * -a, --affinity: Specify the workload.sas.com/class node affinity and toleration to use for this deployment.  Default is 'cas'.
   * -q, --required-affinity: Set this to have the node affinity be a required node affinity.  Default is preferred node affinity.
   * -v, --version: Provides the version of this CAS server creation utility tool.
   * -h, --help: Display help for all the available options.

2. In the base kustomization.yaml file, add the new directory to the resources
   section so that the CAS server is included when the manifest is rebuilt. This
   server is fully customizable with the use of patch transformers.

   ```yaml
   resources:
     - site-config/cas-{{ TENANT }}-{{ INSTANCE }}
   ```

3. Deploy your software using the steps in [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)
   according to the method you are using.

   ```bash
   kubectl get pods -l casoperator.sas.com/server={{ TENANT }}-{{ INSTANCE }}
   cas-{{ TENANT }}-{{ INSTANCE }}-controller     3/3     Running     0          1m

   kubectl get pvc -l sas.com/cas-instance: {{ TENANT }}-{{ INSTANCE }}
   NAME                                                  STATUS  ...
   cas-{{ TENANT }}-{{ INSTANCE }}-data                   Bound  ...
   cas-{{ TENANT }}-{{ INSTANCE }}-permstore              Bound  ...
   ```

## Example

Run the script with more options:

```bash
./create-cas-server.sh --instance sample --output . --workers 2 --backup 1
```

This sample command creates a new directory named `cas-shared-sample` in the
current location and creates a new CAS distributed server (MPP) CR with 2
worker nodes and a backup controller.
