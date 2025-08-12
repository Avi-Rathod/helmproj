---
category: OpenSearch
tocprty: 60
---

# OpenSearch on Red Hat OpenShift

Before deploying your SAS Viya platform software, perform the following steps in order to run OpenSearch on OpenShift in that deployment.

* Configure a Security Context Constraints resource to support OpenSearch
* Remove Seccomp Profile property and annotation on OpenSearch Pods

## Configure Security Context Constraints for OpenSearch

An example Security Context Constraints is available at `$deploy/sas-bases/examples/configure-elasticsearch/internal/openshift/sas-opendistro-scc.yaml`.
A Kubernetes cluster administrator must add these Security Context Constraints to their OpenShift cluster before deploying the SAS Viya platform.

Consult [Common Customizations](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1hvb150qa9z0pn1i4h5joqv2qmc) 
for information about the additional transformers, which might require changes to the Security Context Constraints. 

If modifications are required, place a copy of the `sas-opendistro-scc.yaml` file in the site-config directory and apply the changes to the copy.

### Modify sas-opendistro-scc.yaml for run-user-transformer.yaml

If you are planning to use `run-user-transformer.yaml` to specify a custom UID for the OpenSearch processes, update the `uid` property of the `runAsUser` option to match the custom UID. For example, if UID 2000 will be configured in the `run-user-transformer.yaml`, update the file `sas-opendistro-scc.yaml` as follows.

```
runAsUser:
   type: MustRunAs
   uid: 2000
```

### Modify sas-opendistro-scc.yaml for sysctl-transformer.yaml

If your deployment will use `sysctl-transformer.yaml` to apply the necessary sysctl parameters, the `sas-opendistro-scc.yaml` file must be modified. 
Otherwise, you should skip these steps.

1. Set the allowPrivilegeEscalation and allowPrivilegedContainer options to `true`. This allows a privileged init container to execute and apply the necessary sysctl parameters.

   ```
   allowPrivilegeEscalation: true
   allowPrivilegedContainer: true
   ```

2. Update the runAsUser option to `RunAsAny`, using the following example as your guide. This allows the privileged init container to run as a different user to apply the necessary sysctl parameters.

   ```
   runAsUser:
      type: RunAsAny
   ```

### Apply Security Context Constraints

As a Kubernetes cluster administrator of the OpenShift cluster, use one of the following commands to apply the Security Context Constraints.

```
kubectl apply -f sas-opendistro-scc.yaml
```

```
oc apply -f sas-opendistro-scc.yaml
```

### Add Security Context Constraints to sas-opendistro Service Account

The sas-opendistro SecurityContextConstraints must be added to the sas-opendistro ServiceAccount within each target deployment namespace to grant the
necessary privileges.

Use the following command to configure the ServiceAccount. Replace the entire variable `{{ NAME-OF-NAMESPACE }}`, including the braces,
with the Kubernetes namespace used for the SAS Viya platform.

```
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-opendistro -z sas-opendistro
```

## Remove Seccomp Profile Property and Annotation on OpenSearch Pods

An example transformer that removes the seccomp property and annotation from the OpenSearch pods through the OpenDistroCluster resource is available at `$deploy/sas-bases/overlays/internal-elasticsearch/remove-seccomp-transformer.yaml`.

To include this transformer, add the following to the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/internal-elasticsearch/remove-seccomp-transformer.yaml
   ```
