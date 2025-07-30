---
category: openSourceConfiguration
tocprty: 5
---

# Configure rpy2 for SAS Model Repository Service

## Overview

The SAS Model Repository service provides support for registering, organizing,
and managing models within a common model repository. This service is used by
SAS Event Stream Processing, SAS Intelligent Decisioning, SAS Model Manager,
Model Studio, SAS Studio, and SAS Visual Analytics.

The Model Repository service also includes support for testing and deploying R
models. SAS environments such as CAS and SAS Micro Analytic Service do not
support direct execution of R code. Therefore, R models in a SAS environment are
executed using Python with the rpy2 package. The rpy2 package enables Python to
directly access the R libraries and execute R code.

This README describes how to configure your Python and R environments to use the
rpy2 package for executing models.

## Prerequisites

The SAS Viya platform provides YAML files that the Kustomize tool uses to
configure Python and R. Before you use those files, you must perform the
following tasks:

**Note:** For rpy2 to work properly, Python and R must be installed on the same
system. They do not have to be mounted in the same volume. However, in order to
use the R libraries, Python must have access to the directory that was set for
the R_HOME environment variable.

1. Make note of the attributes for the volumes where Python and R, as well as
   their associated packages, are to be deployed. For example, for NFS, note the
   NFS server and directory. For more information about the various types of
   persistent volumes in Kubernetes, see
   [Additional Resources](#additional-resources).

2. Verify that R 3.4+ is installed on the R volume.

3. Verify that Python 3.5+ and the requests package are installed on the Python
   volume.

4. Verify that the R_HOME environment variable is set.

5. Verify that rpy2 2.9+ is installed as a Python package.

   **Note:** For information about the rpy2 package and version compatibilities,
   see the
   [rpy2 documentation](https://rpy2.github.io/doc/v3.0.x/html/overview.html).

6. Verify that both the Python and R open-source configurations have been
   completed. For more information, see the README files in
   `$deploy/sas-bases/examples/sas-open-source-config/`.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-model-repository/r`
   directory to the `$deploy/site-config/sas-model-repository/r` directory.
   Create the target directory, if it does not already exist.

2. In rpy2-transformer.yaml replace the {{ R-HOME }} value with the R_HOME
   directory path. The value for the R_HOME path is the same as the DM_RHOME
   value in the kustomization.yaml file, which was specified as part of the R
   open-source configuration. That file is located in
   `$deploy/site-config/open-source-config/r/`.

   There are three sections in the rpy2-transformer.yaml file that you must
   update.

   Here is a sample of one of the sections before the change:

   ```yaml
   patch: |-
   # Add R_HOME Path
     - op: add
       path: /template/spec/containers/0/env/-
       value:
         name: R_HOME
         value:  {{ R-HOME }}
   target:
     kind: PodTemplate
     name: sas-launcher-job-config
   ```

   Here is a sample of the same section after the change:

   ```yaml
   patch: |-
   - op: add
     path: /template/spec/containers/0/env/-
     value:
       name: R_HOME
       value:  /share/nfsviyar/lib64/R
   target:
     kind: PodTemplate
     name: sas-launcher-job-config
   ```

3. In the cas-rpy2-transformer section of the rpy2-transformer.yaml file, update
   the CASLLP_99_EDMR value, as shown in this example.

   Here is the relevant code excerpt before the change:

   ```yaml
   - op: add
     path: /spec/controllerTemplate/spec/containers/0/env/-
     value:
       name: CASLLP_99_EDMR
       value: {{ R-HOME }}/lib
   ```

   Here is the relevant code excerpt after the change:

   ```yaml
   - op: add
     path: /spec/controllerTemplate/spec/containers/0/env/-
     value:
       name: CASLLP_99_EDMR
       value: /share/nfsviyar/lib64/R/lib
   ```

4. Add site-config/sas-model-repository/r/rpy2-transformer.yaml to the
   transformers block to the base kustomization.yaml file in the `$deploy`
   directory.

   ```yaml
   transformers:
     - site-config/sas-model-repository/r/rpy2-transformer.yaml
   ```

5. Complete the deployment steps to apply the new settings. See
   [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)
   in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the
   SAS Viya platform or after the deployment of the SAS Viya platform.

   - If you are applying the overlay during the initial deployment of the SAS
     Viya platform, complete all the tasks in the README files that you want to
     use, then run `kustomize build` to create and apply the manifests.
   - If the overlay is applied after the initial deployment of the SAS Viya
     platform, run `kustomize build` to create and apply the manifests.

## Additional Resources

- [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
- [SAS Model Manager: Administrator's Guide](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag)
- [rpy2 Documentation](https://rpy2.github.io/doc/latest/html/index.html)
- [Persistent volumes in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
