---
category: cas
tocprty: 9
---

# Configuration Settings for CAS

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for deploying CAS in both symmetric multiprocessing (SMP) and
massively parallel processing (MPP) configurations.

An SMP server requires one Kubernetes node. An MPP server requires one
Kubernetes node for the server controller and two or more nodes for server
workers. The *SAS Viya Platform: Deployment Guide* provides information to help
you
decide. A link to the deployment guide is provided in the
[Additional Resources](#additional-resources) section.

## Installation

SAS provides example files for many common customizations. Read the descriptions
for the example files in the following list. If you want to use an example file
to simplify customizing your deployment, copy the file to your
`$deploy/site-config` directory.

Each file has information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ .values.NUMBER_OF_WORKERS }}. Replace the
entire variable string, including the braces, with the value you want to use.

After you edit a file, add a reference to it in the transformer block of the
base `kustomization.yaml` file.

## Examples

The example files are located at `$deploy/sas-bases/examples/cas/configure`. The
following is a list of each example file for CAS settings and the file name.

- mount non-NFS persistentVolumeClaims and data connectors for the CAS server
  (`cas-add-host-mount.yaml`)

  ***Note***: To use hostPath mounts on Red Hat OpenShift, see
  [Enable hostPath Mounts for
CAS](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=d
plyml0phy0dkr&docsetTarget=p1h8it1wdu2iaxn1bkd8anfcuxny.htm#n02xn6pmscncm8n14zm4
zlcyyr2g).

- mount NFS persistentVolumeClaims and data connectors for the CAS server
  (`cas-add-nfs-mount.yaml`)

- add a backup controller to an MPP deployment (`cas-manage-backup.yaml`)

  ***Note***: Do not use this example for an SMP CAS server.

- change the user the CAS process runs as (`cas-modify-user.yaml`)

- modify the storage size for CAS PersistentVolumeClaims
  (`cas-modify-pvc-storage.yaml`)

- manage resources for CPU and memory (`cas-manage-cpu-and-memory.yaml`)

- modify the CPU overhead that is reserved for other daemonsets and pods
(`cas-manage-cpu-reserve.yaml`)

- modify the resource allocation for ephemeral storage
  (`cas-modify-ephemeral-storage.yaml`)

- add a configMap to your CAS server (`cas-add-configmap.yaml`)

- add environment variables (`cas-add-environment-variables.yaml`)

- add a configMap with an SSSD configuration (`cas-sssd-example.yaml`)

  ***Note***: This file has no variables. It is an example of how to create a
  configMap for SSSD.

- modify the accessModes on the CAS permstore and data PVCs
  (`cas-storage-access-modes.yaml`)

- disable the sas-backup-agent sidecar from running
  (`cas-disable-backup-agent.yaml`)

- add paths to the file system path allowlist for the CAS server.
  (`cas-add-allowlist-paths.yaml`)

- enable your CAS Services to be externally accessible.
  (`cas-enable-external-services.yaml`)

- remove secure computing mode (seccomp) profile for CAS.
  (`cas-disable-seccomp.yaml`)

- set the secure computing mode (seccomp) profile for CAS, and override the
default of "RuntimeDefault".
  (`cas-seccomp-profile.yaml`)

- automatically restart CAS servers during Deployment Operator updates.
  (`cas-auto-restart.yaml`)

- enable host identity session launching.
  (`cas-enable-host.yaml`)

- disable publish of HTTP Ingress.
  (`cas-disable-http-ingress.yaml`)

- enable TLS for CAS internode communications.
  (`cas-enable-internode-tls.yaml`)

### Manage the Number of Workers

**Note:** If you are using an SMP configuration, skip this section.

By default, MPP CAS has two workers. To modify the number of workers, you must
modify the cas-manage-workers.yaml transformer file. The file can be modified
before or after the initial deployment of your SAS Viya platform. Adding or
removing workers does not require a restart, but existing CAS tables will not be load
balanced to use the new workers by default. New tables should take advantage of the new
workers.

To enable load balancing when changing the number of workers, you should enable
CAS Node Scaling, which requires a modification to the
cas-add-environment-variables.yaml transformer file. If automatic balancing of
tables is desired when adding workers to a running server, the environment
variables should be set at the time of the initial deployment, regardless of
whether you are changing the number of workers at that time. Setting the
variables allows you to use CAS Node Scaling after the software has been
deployed without having to change any of the transformers or the base
kustomization.yaml file. For details about CAS
Node Scaling, see [CAS Node Scaling](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calserverscas&docsetTarget=n05000viyaservers000000admin.htm#n0frcy9n5mwb96n1jhkfl6d0cijj).

#### Use the cas-manage-workers.yaml Transformer

To use the cas-manage-workers.yaml transformer, copy the file to the
$deploy/sas-config subdirectory. Then modify the file as described in the
comments of the file itself before adding the file to the transformer block of
the base kustomization.yaml file.

#### Set the Environment Variables for CAS Node Scaling

To set the environment variables for CAS Node Scaling, copy the
cas-add-environment-variables.yaml file to the $deploy/sas-config subdirectory.
Modify the file to add the following environment variables:

```yaml
...
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/env/-
    value:
      name: CAS_GLOBAL_TABLE_AUTO_BALANCE
      value: "true"
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/env/-
    value:
      name: CAS_SESSION_TABLE_AUTO_BALANCE
      value: "true"
```

Ensure that you accurately designate which CAS servers are receiving the new
environment variables in the target block of the file. Then add the file to the
transformer block of the base kustomization.yaml file.

### Disable Cloud Native Mode

Perform these steps if cloud native mode should be disabled in your environment.

1. Add the following code to the configMapGenerator block of the base
kustomization.yaml
file:

    ```yaml
    ...
    configMapGenerator:
    ...
    - name: sas-cas-config
      behavior: merge
      literals:
        - CASCLOUDNATIVE=0
    ...
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment
Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docse
tId=dplyml0phy0dkr&docsetTarget=titepage.htm).

### Enable System Security Services Daemon (SSSD) Container

> ***Note***: If you are enabling SSSD on an OpenShift cluster, use the
SecurityContextConstraint patch `cas-server-scc-sssd.yaml` instead of
`cas-server-scc.yaml`. This will set the correct capabilities and privilege
escalation.

If SSSD is required in your environment, add
sas-bases/overlays/cas-server/cas-sssd-sidecar.yaml as the first entry to
the transformers list of the base kustomization.yaml file
(`$deploy/kustomization.yaml`).
 Here is an example:

    ```yaml
    ...
    transformers:
    ...
    - sas-bases/overlays/cas-server/cas-sssd-sidecar.yaml
    ...
    ```

> ***Note***: In the transformers list, the `cas-sssd-sidecar.yaml` file must
precede the entry `sas-bases/overlays/required/transformers.yaml` and any TLS
transformers.

### Add a Custom Configuration for System Security Services Daemon (SSSD)

Use these steps to provide a custom SSSD configuration to handle user
authorization in your environment.

1. Copy the `$deploy/sas-bases/examples/cas/configure/cas-sssd-example.yaml`
file to the location of your
   CAS server overlay.
   Example: `site-config/cas-server/cas-sssd-example.yaml`

2. Add the relative path of cas-sssd-example.yaml to the transformers block of
the base kustomization.yaml file
   (`$deploy/kustomization.yaml`).
   Here is an example:

    ```yaml
    ...
    transformers:
    ...
    - site-config/cas-server/cas-sssd-example.yaml
    ...
    ```

3. Copy your custom SSSD configuration file to `sssd.conf`.

4. Add the following code to the secretGenerator block of the base
kustomization.yaml
  file with a relative path to `sssd.conf`:

    ```yaml
    ...
    secretGenerator:
    ...
    - name: sas-sssd-config
      files:
        - SSSD_CONF=site-config/cas-server/sssd.conf
      type: Opaque
    ...
    ```

### Enable Host Launch in the CAS Server

> ***Note***: If you use Kerberos in your deployment, or enable SSSD and disable
CASCLOUDNATIVE,
you must enable host launch.

By default, CAS cannot launch sessions under a user's host identity. All
sessions run
under the cas service account instead. CAS can be configured to allow for host
identity
launches by including a patch transformer in the kustomization.yaml file. The
`/$deploy/sas-bases/examples/cas/configure` directory
contains a cas-enable-host.yaml file, which can be used for this purpose.

> ***Note***: If you are enabling host launch on an OpenShift cluster, specify
one of the following files to create the SecurityContextConstraint instead of
`cas-server-scc.yaml`:
>
> - If SSSD is not configured, use the SecurityContextConstraint patch
`cas-server-scc-host-launch.yaml`
> - If SSSD is configured, use the SecurityContextConstraint patch
`cas-server-scc-sssd.yaml`
>
> This will set the correct capabilities and privilege escalation.

To enable this feature:

1. Copy the `$deploy/sas-bases/examples/cas/configure/cas-enable-host.yaml` file
to the location of your
CAS server overlay. For example, `site-config/cas-server/cas-enable-host.yaml`.

2. The example file defaults to targeting all CAS servers by specifying a name
component of `.*`.
To target specific CAS servers, comment out the `name: .*` line and choose which
CAS servers you
want to target. Either uncomment the name: and replace NAME-OF-SERVER with one
particular CAS
server or uncomment the labelSelector line to target only the default
deployment.

3. Add the relative path of the `cas-enable-host.yaml` file to the transformers
block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`) before the reference to
the sas-bases/overlays/required/transformers.yaml file and any SSSD
transformers. Here is an example:

    ```yaml
    transformers:
    ...
    - site-config/cas-server/cas-enable-host.yaml
    ...
    - sas-bases/overlays/required/transformers.yaml
    ...
    ```

### Enable CAS Internode Encryption

CAS supports encrypting connections between the worker nodes. When internode
encryption is configured, any data sent between worker nodes is sent over a TLS
connection.

By default, CAS internode communication is not encrypted in any of the SAS Viya
platform encryption modes.  If required, CAS internode encryption should only be
enabled in the "Full-stack TLS" encryption mode.

Before deciding to enable CAS internode encryption, you should be familiar with
the content in [SAS Viya Platform Encryption: Data in
Motion](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docs
etId=calencryptmotion&docsetTarget=titlepage.htm).

>**Note:** Encryption has performance costs. Enabling CAS internode encryption
will degrade your performance and increase the amount of CPU time that is
required to complete any action. Actions that move large amounts of data are
penalized the most. Session start-up time is also impacted negatively. Testing
indicates that scenarios that move large blocks of data between nodes can
increase elapsed action times by a factor of ten.

Perform these steps to enable CAS internode encryption.

1. Copy the
`$deploy/sas-bases/examples/cas/configure/cas-enable-internode-tls.yaml` into
your `/site-config` directory.  For example:
`site-config/cas-server/cas-enable-host.yaml`

2. The cas-enable-internode-tls.yaml transformer file defaults to targeting all
CAS servers by specifying a name component of `.*`. Edit the transformer to
indicate the CAS servers you want to target for CAS internode encryption. For
more information about selecting specific CAS servers, see [Targeting CAS
Servers](#targeting-cas-servers).

3. Add the relative path of the `cas-enable-internode-tls.yaml` file to the
transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`) before the reference to
the `sas-bases/overlays/required/transformers.yaml`. Here is an example:

    ```yaml
    transformers:
    ...
    - site-config/cas-server/cas-enable-host.yaml
    ...
    - sas-bases/overlays/required/transformers.yaml
    ...
    ```
### Configure Behavior of CAS State Transfer

For the instructions to set up a CAS State transfer, including configuration steps, 
see the README file located at `$deploy/sas-bases/overlays/cas-server/state-transfer/README.md`
(for Markdown format) or at `$deploy/sas-bases/docs/state_transfer_for_cas_server_for_the_sas_viya_platform.htm`
(for HTML format).

## Targeting CAS Servers

Each example patch has a target section which tells it what resource(s) it
should apply to.
There are several parameters including object name, kind, version, and
labelSelector. By default,
the examples in this directory use  `name: .*` which applies to all CAS server
definitions.
If there are multiple CAS servers and you want to target a specific instance,
you can set the
"name" option to the name of that CASDeployment.  If you want to target the
default "cas-server"
overlay you can use a labelSelector:

Example:

```yaml
target:
  name: cas-example
  labelSelector: "sas.com/cas-server-default"
  kind: CASDeployment
```

> ***Note***: When targeting the default CAS server provided explicitly the path
option must be used, because the name is a config map token that cannot be
targeted.

## Additional Resources

For more information about CAS configuration and using example files, see the
[SAS Viya Platform: Deployment
Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docse
tId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
