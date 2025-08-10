---
category: sasProgrammingEnvironment
tocprty: 9
---

# Configuring SAS Compute Server to Use a Personal CAS Server

## Overview

The SAS Compute server provides the ability to execute SAS code that
can drive requests into the shared CAS server in the cluster. For development
purposes in applications such as SAS Studio, you might need to allow data scientists the ability to work with a CAS server that is local to their SAS Compute session.

This README file describes how to customize your SAS Viya platform deployment to allow
SAS Compute server users access to a personal CAS server.  This personal CAS server uses symmetric multiprocessing (SMP) architecture.

**Note:** The README for Personal CAS Server with GPU is located at `$deploy/sas-bases/examples/sas-programming-environment/personal-cas-server-with-gpu/README.md` (for Markdown format) or `$deploy/sas-bases/doc/configuring_sas_compute_server_to_use_a_personal_cas_server-with-gpu.htm` (for HTML format).

## Installation

Enable the ability for the pod where the SAS Compute
server is running to contain a personal CAS server instance. This CAS server
starts when the SAS Compute server is started, and exists for the life of
the SAS Compute server. Code executing in the SAS Compute session can then be
directed to this personal CAS server.

### Enable the Personal CAS Server in the SAS Compute Server

SAS has provided an overlay to enable the personal CAS server in your environment.

To use the overlay:

1. Add a reference to the `sas-programming-environment/personal-cas-server` overlay to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/sas-programming-environment/personal-cas-server
   - sas-bases/overlays/required/transformers.yaml
   ...
   ```

   **NOTE:** The reference to the `sas-programming-environment/personal-cas-server` overlay **MUST** come before the required transformers.yaml, as seen in the example above.

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Disabling the Personal CAS Server in the SAS Compute Server

To disable the personal CAS Server:

1. Remove `sas-bases/overlays/sas-programming-environment/personal-cas-server`
from the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).