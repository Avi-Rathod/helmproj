---
category: security
tocprty: 14
---

# SAS Programming Environment Configuration Tasks

## Overview

This readme describes how to customize your SAS Viya platform deployment for
tasks related to the SAS Programming Environment.

## Installation

SAS provides the ability for modifications to be made to the scripts that
are used for launching processes.  The following processes allow for modifications
to be set in SAS Environment Manager.

* SAS CAS server
* SAS Compute server
* SAS/CONNECT server
* SAS/CONNECT spawner
* SAS Batch server

Each server type has multiple configuration instances for modification of
configuration files, autoexec code, and startup scripts that are used to launch
the servers. Modifications to the startup script configurations for each server
are disabled by default.

The system administrator can give the SAS Administrator the ability to have
updates made to these configuration scripts processed by the server applications.

Since this processing takes place at the initialization of the server application,
changes to these configMaps take effect upon the next launch of the pod.

### Enabling Processing of SAS Administrator Script Modifications

Included in this folder is an overlay called enable-admin-script-access.yaml.
This overlay provides a patchTransformer that gives the SAS
Administrator the ability to have script modifications made in SAS Environment
Manager processed by the server applications.

To enable this access:

1. Add sas-bases/overlays/sas-programming-environment/enable-admin-script-access.yaml
to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
Here is an example:

    ```
    ...
    transformers:
    ...
    - sas-bases/overlays/sas-programming-environment/enable-admin-script-access.yaml
    ...
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Disabling Processing of SAS Administrator Script Modifications

Included in this folder is an overlay called disable-admin-script-access.yaml.
This overlay provides a patchTransformer that denies the SAS
Administrator the ability to have script modifications made in SAS Environment
Manager processed by the server applications.

To disable this access:

1. Add sas-bases/overlays/sas-programming-environment/disable-admin-script-access.yaml
to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
Here is an example:

    ```
    ...
    transformers:
    ...
    - sas-bases/overlays/sas-programming-environment/disable-admin-script-access.yaml
    ...
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).