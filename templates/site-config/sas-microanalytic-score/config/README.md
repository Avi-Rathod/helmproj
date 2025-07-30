---
category: SAS Micro Analytic Service
tocprty: 4
---

# Configuration Settings for SAS Micro Analytic Service

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for deploying, tuning, and troubleshooting  SAS Micro Analytic Service.


## Installation

SAS provides example files for many common customizations. Read the descriptions
for the example files in the examples section. Follow these steps to use transformers from examples to customize your deployment.

1. Copy the example transformer file in `$deploy/sas-bases/examples/sas-microanalytic-score/config` to the `$deploy/site-config/sas-microanalytic-score/config` directory. Create the destination directory if it does not exist.

2. Each file has information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ VARIABLE-NAME }}. Replace the
entire variable string, including the braces, with the value you want to use.

3. In the base kustomization.yaml in $deploy directory, add site-config/sas-microanalytic-score/config/<example-transformer-file> to the transformers block.


   ```yaml   
   transformers:
   - site-config/sas-microanalytic-score/config/mas-add-environment-variables.yaml   
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

   **Note:** These transformers can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

   * If you are applying the transformer during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
   * If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.  

## Examples

The example files are located at `$deploy/sas-bases/examples/sas-microanalytic-score/config`. The
following is a list of each example file for SAS Micro Analytic Service settings and the file name.

- add environment variables (`mas-add-environment-variables.yaml`)
           
## Verify Transformer for the New Configuration

1. Run the following command to verify whether the transformer has been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```

2. Verify that the output contains the  values that you configured:
    
   ```yaml
   Environment:
     my-variable: my-value
   ```

## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)