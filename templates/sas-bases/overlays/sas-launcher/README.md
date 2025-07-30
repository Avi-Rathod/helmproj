---
category: SAS Launcher Service
tocprty: 2
---

# Configuring SAS Launcher Service to Disable the Resource Exhaustion Protection

This README describes the steps necessary to disable your SAS Viya platform deployment SAS Launcher Resource Exhaustion protection.
Disabling this feature allows users to have no limit to the number of processes they can launch through the SAS Launcher API.

## Installation

1. To disable SAS Launcher Resource Exhaustion protection, add sas-bases/overlays/sas-launcher/launcher-disable-user-process-limits.yaml
to the transformers block of the base kustomization.yaml file in the `$deploy` directory. Here is an example:

    ```yaml
    transformers:
    ...
    - sas-bases/overlays/sas-launcher/launcher-disable-user-process-limits.yaml
    ```

2. When the reference is added to the base kustomization.yaml, use the deployment commands described in [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.