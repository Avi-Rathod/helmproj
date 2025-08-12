---
category: SAS/CONNECT Spawner
tocprty: 1
---

# Configure SAS/CONNECT Spawner in the SAS Viya Platform

## Overview

This readme describes hows to customize your SAS Viya platform deployment to use 
SAS/CONNECT Spawner.

## Installation

SAS provides example and overlay files for customizations. Read the descriptions
of the available tasks in the following sections. If you want to perform a
task to customize your deployment, follow the instructions for it that follow
in that section.

### Disable Cloud Native Mode

Perform these steps if cloud native mode should be disabled in your environment.

1. Add the following code to the configMapGenerator block of the base kustomization.yaml
file:

    ```
    ...
    configMapGenerator:
    ...
    - name: sas-connect-spawner-config
      behavior: merge
      literals:
        - SASCLOUDNATIVE=0
    ...
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Enable System Security Services Daemon (SSSD) Container

Perform these steps if SSSD is required in your environment.

1. Add sas-bases/overlays/sas-connect-spawner/add-sssd-container-transformer.yaml to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

**Important:** This line must come before any network transformers (that is, transformers starting with "- sas-bases/overlays/network/") and the required transformer "- sas-bases/overlays/required/transformers.yaml". Note that your configuration may not have network transformers if security is not configured.

Here is an example for Full-stack TLS. If you are using a different version of TLS, or no TLS at all, the network transformers may be different or not present.

    ```
    ...
    transformers:
    ...
    - sas-bases/overlays/sas-connect-spawner/add-sssd-container-transformer.yaml
    # The following lines are provided as a location reference, they should not be added if they don't appear.
    - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml
    - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml
    - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml
    # The following line is provided as a location reference, it should appear only once and not be duplicated.
    - sas-bases/overlays/required/transformers.yaml 
    ...
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Add a Custom Configuration for System Security Services Daemon (SSSD)

Use these steps to provide a custom SSSD configuration to handle user authorization in your environment.

1. Copy the `$deploy/sas-bases/examples/sas-connect-spawner/external-sssd-config/add-sssd-configmap-transformer.yaml` file to `$deploy/site-config/sas-connect-spawner/external-sssd-config/add-sssd-configmap-transformer.yaml`.

2. Modify the copied file according to the comments in it.

3. Add site-config/sas-connect-spawner/external-sssd-config/add-sssd-configmap-transformer.yaml
and sas-bases/overlays/sas-connect-spawner/ext-sssd-volume-transformer.yaml
to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
Here is an example:

    ```
    ...
    transformers:
    ...
    -
    - site-config/sas-connect-spawner/external-sssd-config/add-sssd-configmap-transformer.yaml
    - sas-bases/overlays/sas-connect-spawner/ext-sssd-volume-transformer.yaml
    ...
    ```

4. Copy your custom sssd configuration file to `$deploy/site-config/sas-connect-spawner/external-sssd-config/sssd.conf`.

5. Add the following code to the secretGenerator block of the base kustomization.yaml
file:

    ```
    ...
    secretGenerator:
    ...
    - name: sas-sssd-config
      files:
        - SSSD_CONF=site-config/sas-connect-spawner/external-sssd-config/sssd.conf
      type: Opaque
    ...
    ```

6. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Provide External Access to sas-connect-spawner via a Load Balancer

LoadBalancer assigns an IP address for the SAS/CONNECT Spawner and allows the
standard port number to be used.

1. Copy the `$deploy/sas-bases/examples/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-loadbalancer.yaml` file to `$deploy/site-config/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-loadbalancer.yaml`.

2. Modify the copied file according to the comments in it.

3. Add a reference to the copied file to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

    ```
    ...
    resources:
    ...
    - site-config/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-loadbalancer.yaml
    ...
    ```

4. Deploy the software as described in [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

5. Refer to [External Client Sign-On to TLS-Enabled SAS Viya SAS/CONNECT Spawner](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calencryptmotion&docsetTarget=n1xdqv1sezyrahn17erzcunxwix9.htm&locale=en#n14ebs8337o5t4n1hwm0bx5681o8) when LoadBalancer is configured.

### Provide External Access to sas-connect-spawner via a NodePort

NodePort assigns a port and routes traffic from that port to the SAS/CONNECT Spawner.
A value can be selected from the allowed nodePort range and assigned in the yaml.
This assignment prevents the SAS/CONNECT Spawner from starting if the selected port is
already in use or is outside the allowable nodePort range.

1. Copy the `$deploy/sas-bases/examples/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-nodeport.yaml` file to `$deploy/site-config/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-nodeport.yaml`.

2. Modify the copied file according to the comments in it.

3. Add a reference to the copied file to the resources block of the base kustomization.yaml file. Here is an example:

    ```
    ...
    resources:
    ...
    - site-config/sas-connect-spawner/enable-external-access/sas-connect-spawner-enable-nodeport.yaml
    ...
    ```

4. Deploy the software as described in [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

5. Refer to [External Client Sign-On to TLS-Enabled SAS Viya SAS/CONNECT Spawner](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calencryptmotion&docsetTarget=n1xdqv1sezyrahn17erzcunxwix9.htm&locale=en#n14ebs8337o5t4n1hwm0bx5681o8) when NodePort is configured.

## Additional Resources

For more information about configurations and using example and overlay files, see
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).