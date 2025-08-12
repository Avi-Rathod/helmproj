---
category: SAS Launcher Service
tocprty: 1
---

# Configuration Settings for SAS Launcher Service

## Overview

This README file describes the settings available for deploying SAS Launcher
Service.
The example files described in this README file are located at
'/$deploy/sas-bases/examples/sas-launcher/configure'.

## Installation

Based on the following descriptions of available example files, determine if you
want to use any example file in your deployment. If you do, copy the example
file and place it in your site-config directory.

### Process Limits

Example files are provided that contain suggested process limits based on your
deployment size. There is a file provided for each of the two types of users,
regular users and super users.

- Change process limit for non-super users (launcher-user-process-limit.yaml)
- Change process limit for super users (launcher-super-user-process-limit.yaml)

Regular users (non-super users) have the following suggested defaults according
to your deployment size:
   * 10 (small)
   * 25 (medium)
   * 50 (large)

Super users have the following suggested defaults according to your deployment
size:
   * 15 (small)
   * 35 (medium)
   * 65 (large) 

In the example files, uncomment the value you wish to keep, and comment out the
rest. After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

Here is an example using the transformer for regular users:

```yaml
transformers:
...
- site-config/sas-launcher/configure/launcher-user-process-limit.yaml
```

### Configure Home Directories

#### Use NFS Server To Mount Home Directory

The launcher-nfs-mount.yaml file allows you to change the location of the NFS
server hosting the user's home directories. The path is determined by the
Identities service.

1. Create the location site-config/sas-launcher/configure/.

2. Copy the sas-bases/examples/sas-launcher/configure/launcher-nfs-mount.yaml file to the site-config/sas-launcher/configure/ location.

3. In the file, replace {{ NFS-SERVER-LOCATION }} with the location of the NFS server. Here is an example: 

   ```yaml
   patch: |-
     - op: add
       path: /template/metadata/annotations/launcher.sas.com~1nfs-server
       value: myserver.nfs.com
   ```

4. After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file. Here is an example:

   ```yaml
   transformers:
   ...
   - site-config/sas-launcher/configure/launcher-nfs-mount.yaml
   ```

   **Note:** If you are performing the tasks in this README before the initial deployment of your SAS Viya software,
  you should perform the next step after the deployment is completed. If you are updating an existing deployment, you
  should perform the next step now.

5. In SAS Environment Manager, set the Identities identifier.homeDirectoryPrefix to the parent path to the home
directory location on the NFS server.

#### Use Kubernetes Volumes for User Home Directories

The launcher-user-homedirectory-volume.yaml allows you to specify the runtime
storage location of the user's home directory. The path is determined by the identities
service and is mounted using the specified {{ VOLUME-STORAGE-CLASS }}.

**Note:** Using this feature overrides changes made for the [Use NFS Server To Mount Home Directory](#use-nfs-server-to-mount-home-directory) feature.

1. Create the location `site-config/sas-launcher/configure/`.

2. Copy the sas-bases/examples/sas-launcher/configure/launcher-user-homedirectory-volume.yaml file to the `site-config/sas-launcher/configure/` location.

3. In the file, replace {{ VOLUME-STORAGE-CLASS }} with the location of the volume storage call of your choice. Here is an example:

   ```yaml
   patch: |-
     - op: add
       path: /template/spec/volumes/-
       value:
         name: sas-launcher-userhome
         persistentVolumeClaim:
           claimName: home-rwx-claim
   ```

4. After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file. Here is an example:

   ```yaml
   transformers:
   ...
   - site-config/sas-launcher/configure/launcher-user-homedirectory-volume.yaml
   ```

   **Note:** If you are performing the tasks in this README before the initial deployment of your SAS Viya software,
   you should perform the next step after the deployment is completed. If you are updating an existing deployment, you
   should perform the next step now.

5. In SAS Environment Manager, set the Identities identifier.homeDirectoryPrefix to the parent path to mount the 
home directory location in the pod.

### Locale and Encoding Defaults

The launcher-locale-encoding-defaults.yaml file allows you to modify the SAS LOCALE and SAS ENCODING defaults.
The defaults are stored in a Kubernetes ConfigMap called sas-launcher-init-nls-config, which the Launcher service will 
use to determine which default values are needed to be set. The LOCALE and ENCODING defaults specified here will affect 
all consumers of SAS Launcher (SAS Compute Server, SAS/CONNECT, and SAS Batch Server) unless overridden (see below). 
To update the defaults, replace {{ LOCALE-DEFAULT }} and {{ ENCODING-DEFAULT }}. Here is an example:

```yaml
patch: |-
  - op: replace
    path: /data/SAS_LAUNCHER_INIT_LOCALE_DEFAULT
    value: en_US
  - op: replace
    path: /data/SAS_LAUNCHER_INIT_ENCODING_DEFAULT
    value: utf8
```

**Note:** For a list of the supported values for LOCALE and ENCODING, see [LOCALE, ENCODING, and LANG Value Mapping Table](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calsrvpgm&docsetTarget=p04d9diqt9cjqnn1auxc3yl1ifef.htm#p1l37gkiso1lbxn1754hzpgbf67h).

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file. Here is an example:

```yaml
transformers:
...
- site-config/sas-launcher/configure/launcher-locale-encoding-defaults.yaml
```

The defaults from this ConfigMap can be overridden on individual launcher contexts. For more information on overriding 
specific launcher contexts, see [Change Default SAS Locale and SAS Encoding](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calsrvpgm&docsetTarget=n08vlobon8812gn11ija5pgjgjsy.htm).

The defaults from this ConfigMap are also overridden by effective LOCALE and ENCODING values derived from an export 
LANG=langValue statement that is present in a startup_commands configuration instance of sas.compute.server, 
sas.connect.server, or sas.batch.server. For more information on setting or removing these statements, see [Edit Server Configuration Instances](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=evfun&docsetTarget=p19rd04uy9qnlkn10vwoajl66nxq.htm&locale=en#n0p8gxdvtd6o8un16ky5a8z1u7io).

**Note:** When following links to SAS documentation, use the version number selector towards the left side of the header to select your currently deployed release version.

### Requests and Limits for CPU

The default values and maximum values for CPU requests and CPU limits can be specified
in a Launcher service pod template. The launcher-cpu-requests-limits.yaml allows
you to change these default and maximum values for the CPU resource. To update the defaults, replace the
{{ DEFAULT-CPU-REQUEST }}, {{ MAX-CPU-REQUEST }}, {{ DEFAULT-CPU-LIMIT }}, and {{ MAX-CPU-LIMIT }} variables with the value you want to use. Here is an example:

```yaml
patch: |-
  - op: add
    path: /metadata/annotations/launcher.sas.com~1default-cpu-request
    value: 50m
  - op: add
    path: /metadata/annotations/launcher.sas.com~1max-cpu-request
    value: 100m
  - op: add
    path: /metadata/annotations/launcher.sas.com~1default-cpu-limit
    value: "2"
  - op: add
    path: /metadata/annotations/launcher.sas.com~1max-cpu-limit
    value: "2"
```

**Note:** For details on the value syntax used above, see [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file. Here is an example:

```yaml
transformers:
...
- site-config/sas-launcher/configure/launcher-cpu-requests-limits.yaml
```

**Note:** The current example PatchTransformer targets all PodTemplates used by sas-launcher. If you only wish to target only one PodTemplate, update the PatchTransformer to target a specific PodTemplate name.

### Requests and Limits for Memory

The default values and maximum values for memory requests and memory limits can be specified
in a Launcher service pod template. The launcher-memory-requests-limits.yaml allows
you to change these default and maximum values for the memory resource. To update the defaults, replace the
{{ DEFAULT-MEMORY-REQUEST }}, {{ MAX-MEMORY-REQUEST }}, {{ DEFAULT-MEMORY-LIMIT }}, and {{ MAX-MEMORY-LIMIT }} variables with the value you want to use. Here is an example:

```yaml
patch: |-
  - op: add
    path: /metadata/annotations/launcher.sas.com~1default-memory-request
    value: 300M
  - op: add
    path: /metadata/annotations/launcher.sas.com~1max-memory-request
    value: 2Gi
  - op: add
    path: /metadata/annotations/launcher.sas.com~1default-memory-limit
    value: 500M
  - op: add
    path: /metadata/annotations/launcher.sas.com~1max-memory-limit
    value: 2Gi
```

**Note:** For details on the value syntax used above, see [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file. Here is an example:

```yaml
transformers:
...
- site-config/sas-launcher/configure/launcher-memory-requests-limits.yaml
```

**Note:** The current example PatchTransformer targets all PodTemplates used by sas-launcher. If you only wish to target only one PodTemplate, update the PatchTransformer to target a specific PodTemplate name.