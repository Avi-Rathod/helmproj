---
category: security
tocprty: 15
---

# Modify Container Security Settings

## Overview

This README describes customizations that can be made by the Kubernetes
administrator to modify container security configurations while deploying the SAS Viya platform.
An administrator might want or need to change the default container security settings in a SAS Viya platform
deployment such as removing, adding, or updating settings in the podSpecs. There are many reasons why an
administrator might want to modify these settings.

The steps in this README for fsGroup and seccomp can
be used for any platform. However, if you are deploying on Red Hat OpenShift, these settings must be modified in
order to take advantage of OpenShift's built-in security context constraints (SCCs). The title of each section indicates whether it is required for OpenShift.

### What is an SCC?

SCCs are the framework, provided by OpenShift, that controls what privileges can be requested by pods in the cluster.
OpenShift provides users with several built-in SCCs. Admins can attach pods to any of these SCCs or they can create dedicated SCCs. Dedicated SCCs
are created specifically to address the specs and capabilities required by a certain pod/product.
For more information on OpenShift SCCs, see [Managing SCCs in OpenShift](https://www.openshift.com/blog/managing-sccs-in-openshift).

### Purpose of the Customizations

You can use the customizations in this file to accomplish the following required or optional tasks:

- (OpenShift only) Adjust your podSpec to use one of the built-in SCCs and avoid creating a dedicated one.

  The "restricted" SCC, for example, is the primary built-in SCC that should control all pods. The restricted SCC is classified as the standard, and most pods should be able to run with it and validate against it.
   
- Remove the seccomp profile settings from the podSpec or update its value.

  Removal is required for OpenShift and optional for other environments. The restricted SCC does not allow this setting to be included in the podSpec.
   
- Remove the fsGroup setting or update its value.

  This step is required for OpenShift and optional for other environments. The restricted SCC prevents you from setting fsGroup to a value outside of the allocated ID range. SAS has set it to a default value that enables the shared service account to access the file system. This shared account is invalid in the OpenShift restricted SCC.

  In OpenShift, every namespace/project has a dynamically allocated range of IDs that are used to prevent collisions between separate projects. Replace the fsGroup value with an ID from the allocated range.

  In other environments, removing the setting is an option when you are using a storage class provider that grants group-write access by default.

  Otherwise, the fsGroup value should be updated rather than removed.

**Note:** Pods that run with dedicated SCCs for Crunchy Data (the internal PostgreSQL server) or the CAS server do not need the customizations referenced in this README. They have dedicated SCCs that will contain all conditions for the pods
without altering the podSpec. You can use some of these customizations for OpenSearch. For more information, see [Security Requirements](http://documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#p08n4ci5vnlaj7n1h9xefbnemeut).

## Instructions

### fsGroup

The fsGroup field defines a special supplemental group that assigns a GID for all containers in the pod.
Volumes that support ownership management are modified to be owned and writable by the GID specified in fsGroup.
For more information about using fsGroup, see [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

#### Update the fsGroup Field (Mandatory for OpenShift; Optional for Other Environments)

**Notes:** Crunchy Data currently does not support updating this value. Do not attempt to change this setting for an internal PostgreSQL server. Instead, custom SCCs grant the Crunchy Data pods the ability to run with their specific group ID (GID).

Updating this value for CAS is optional because CAS default settings work in all environments. If you want to update values for CAS, you must uncomment the corresponding PatchTransformer in the update-fsgroup.yaml file. If you are deploying on OpenShift, the corresponding SCC also must be updated to specify the new fsGroup values or be set to "RunAsAny".

Use these steps to update the fsGroup field for pods in your SAS Viya platform deployment.

1. Copy the `$deploy/sas-bases/examples/security/container-security/configmap-inputs.yaml` file to the location of your working container security overlay,
   such as `site-config/security/container-security/`.

2. Update the `{{ FSGROUP_VALUE }}` token in the configmap-inputs.yaml file to match the desired numerical group value.

   **Note:** For OpenShift, you can get the allocated GID and value with the `kubectl describe namespace <name-of-namespace>` command. The value to use is the minimum value of the `openshift.io/sa.scc.supplemental-groups` annotation. For example, if the output is the following, you should use `1000700000`.

   ```yaml
   Name:         sas-1
   Labels:       <none>
   Annotations:  ...
                 openshift.io/sa.scc.supplemental-groups: 1000700000/10000
                 ...
   ```

3. Add the relative path of configmap-inputs.yaml to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/security/container-security/configmap-inputs.yaml
   ...
   ```

4. Add the relative path of the update-fsgroup.yaml file to the transformers block of the base kustomization.yaml file. Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/security/container-security/update-fsgroup.yaml
   ...
   ```

5. (Optional) For CAS, add the relative path of the update-cas-fsgroup.yaml file to the transformers block of the base kustomization.yaml file. Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/security/container-security/update-fsgroup.yaml
   - sas-bases/overlays/security/container-security/update-cas-fsgroup.yaml
   ...
   ```

6. (For OpenShift) If you performed the optional configuration for CAS from Step 5, update the dedicated SCC for CAS to allow the desired fsGroup value. This value should match the value from Step 2 above, or it should be set to `RunAsAny`.

#### Remove the fsGroup Field (Not Recommended for Typical Deployment Scenarios)

**Note:** Crunchy Data currently does not support removing this value. Pods for an internal PostgreSQL server will remain unaffected.

To remove the fsGroup field from your deployment specification, add the relative path of the remove-fsgroup-transformer.yaml file
to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/security/container-security/remove-fsgroup-transformer.yaml
...
```

### Secure Computing Mode (seccomp)

Secure computing mode (seccomp) is a security facility that restricts the actions that are available
within a container. You can use this feature to restrict your application's access. For more information
about seccomp, see [Seccomp security profiles for Docker](https://docs.docker.com/engine/security/seccomp/).

#### Update the seccomp Profile

Considerations:

- Crunchy Data (the internal PostgreSQL server) and OpenSearch currently do not support updating this value and will remain unaffected.
- If you are deploying on OpenShift, do not update the seccomp profile, but instead remove it according to the instructions in the next section.
- If you are changing the seccomp profile to unconfined, do not update the seccomp profile, but instead remove it according to the instructions in the next section.
- If you are changing the seccomp profile to a locally-defined profile, be aware that SAS cannot claim support for all user-defined profiles. Additionally, not all of the SAS Viya platform supports using locally-defined profiles. This option is not recommended.

Use these steps to update the seccomp profile enabled for pods in your deployment specification.

1. Copy the `deploy/sas-bases/examples/security/container-security/update-seccomp.yaml` file to the location of your working container security overlay.

   Here is an example: `site-config/security/container-security/update-seccomp.yaml`

2. Update the "{{ SECCOMP_PROFILE }}" tokens in the update-seccomp.yaml file to match the desired seccomp profile value.

3. Add the relative path of update-seccomp.yaml to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - site-config/security/container-security/update-seccomp.yaml
   ...
   ```

#### Remove the seccomp Profile (Mandatory for OpenShift)

To remove the seccomp profile settings from your deployment specification, add the relative path of the
remove-seccomp-transformer.yaml file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

**IMPORTANT:**  You must make this modification in an OpenShift environment.

Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/security/container-security/remove-seccomp-transformer.yaml
...
```
