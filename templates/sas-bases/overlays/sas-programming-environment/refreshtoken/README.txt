---
category: sasProgrammingEnvironment
tocprty: 4
---

# Configure SAS Compute Server to Use SAS Refresh Token Sidecar

## Overview

The SAS Compute server provides the ability to execute SAS Refresh Token, 
which by use of a sidecar works as a silent partner to the main container,
refreshing the client token as needed. Using the sidecar is valuable for 
long-running tasks that exceed the default life of the client token, 
which in turn inhibits the successful completion of such tasks. The sidecar
seamlessly refreshes the token so that these tasks can continue running unimpeded.

The SAS Refresh Token facility is disabled by default.  This README file describes how to
customize your SAS Viya platform deployment to allow SAS Compute server to run the SAS Refresh Token sidecar.

## Installation

Enable the ability for the pod where the SAS Compute
server is running to run SAS Refresh Token. SAS Refresh Token starts when the SAS
Compute server is started. It exists for the life of
the SAS Compute server.

### Enable SAS Refresh Token in the SAS Compute Server

SAS has provided an overlay to enable SAS Refresh Token in your environment.

To use the overlay:

1. Add a reference to the `sas-programming-environment/refreshtoken` overlay to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

    ```yaml
    ...
    transformers:
    ...
    - sas-bases/overlays/sas-programming-environment/refreshtoken
    - sas-bases/overlays/required/transformers.yaml
    ...
    ```

   **NOTE:** The reference to the `sas-programming-environment/refreshtoken` overlay **MUST** come before the required transformers.yaml, as shown in the example above.

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Disable SAS Refresh Token in the SAS Compute Server

To disable SAS Refresh Token:

1. Remove `sas-bases/overlays/sas-programming-environment/refreshtoken`
from the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).