---
category: sasProgrammingEnvironment
tocprty: 11
---

# Configuration Settings for the Personal CAS Server

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for deploying the Personal CAS Server.

## Installation

The SAS Viya Platform provides example files for many common customizations. Read the descriptions
for the example files in the following list. If you want to use an example file
to simplify customizing your deployment, copy the file to your
`$deploy/site-config` directory.

Each file has information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ AMOUNT-OF-STORAGE }}. Replace the
entire variable string, including the braces, with the value you want to use.

After you edit a file, add a reference to it in the transformers block of the
base `kustomization.yaml` file.

Here is an example using the host path transformer, saved to `$deploy/site-config/sas-programming-environment/personal-cas-server`:

  ```yaml
  transformers:
  ...
  - /site-config/sas-programming-environment/personal-cas-server/personal-cas-modify-host-cache.yaml
  ...

  ```

## Examples

The example files are located at `$deploy/sas-bases/examples/sas-programming-environment/personal-cas-server`.
The following is a list of each example file.

- enable Kerberos support for the Personal CAS server
  (`personal-cas-enable-kerberos.yaml`)

- modify the CAS_DISK_CACHE to be a host path for the Personal CAS server
  (`personal-cas-modify-host-cache.yaml`)

## Additional Resources

For more information about deployment and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).