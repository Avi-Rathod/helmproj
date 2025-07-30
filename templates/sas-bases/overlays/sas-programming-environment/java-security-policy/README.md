---
category: sasProgrammingEnvironment
tocprty: 6
---

# Disable Generation of Java Security Policy File for SAS Programming Environment

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for managing the Java security policy file that is generated for
the SAS Programming Environment.

By default the deployment of the SAS Programming Environment generates a Java
security policy file to prevent SAS programmers from executing Java code that
would be deemed unsafe by the administrator directly from SAS code. This
README file describes the customizations that can be made by the Kubernetes
administrator to manage the Java security policy file that is generated.

## Installation

The generated Java security policy controls permissions for Java access
inside of the SAS Programming Environment.  In cases where the application of
the policy file is deemed restrictive by the administrator, the generation of
the policy file can be disabled.

### Disable the Generation of the Java Security Policy File

SAS has provided an overlay to disable the generation of the Java security policy.

To use the overlay:

1. Add a reference to the `sas-programming-environment/java-security-policy/
disable-java-policy-file-generation.yaml`
overlay to the transformers block of the base kustomization.yaml file
 (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/sas-programming-environment/java-security-policy/disable-java-policy-file-generation.yaml
   - sas-bases/overlays/required/transformers.yaml
   ...
   ```

   **NOTE:** The reference to the `sas-programming-environment/java-security-policy/disable-java-policy-file-generation.yaml`
    overlay **MUST** come before the required transformers.yaml, as seen in the example above.

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Enable the Generation of the Java Security Policy File

To enable the generation of the Java security policy file:

1. Remove `sas-bases/overlays/sas-programming-environment/java-security-policy/disable-java-policy-file-generation.yaml`
from the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).