---
category: SAS Compute Service
tocprty: 10
---

# Update Compute Service Internal HTTP Request Timeout

## Overview

The SAS Compute service makes calls to Compute server processes running
in the cluster using HTTP calls.  The Compute service uses a default request timeout
of 600 seconds.  This README describes the customizations that can be made for
updating this timeout to control how long the Compute
service requests to the servers wait for a response.

## Installation

The SAS Compute service internal HTTP request timeout can be modified by using the
change-sas-compute-http-request-timeout.yaml file.

1. Copy the
`$deploy/sas-bases/examples/compute/client-request-timeout/change-sas-compute-http-request-timeout.yaml`
file to the site-config directory.

2. In the copied file, replace {{ TIMEOUT }} with the number of seconds to use for
the timeout.  Note that the trailing "s" after {{ TIMEOUT }} should be kept.

Here is an example:

   ```yaml
   ...
   patch: |-
     - op: replace
       path: /spec/template/spec/containers/0/env/-
         value:
           name: SAS_HTTP_CLIENT_TIMEOUT_REQUEST
           value: 1200s
   ...
   ```

3. After you edit the file, add a reference to it in the transformers block of
the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example assuming the file has been saved
   to `$deploy/site-config/compute/client-request-timeout`:

   ```yaml
   transformers:
   ...
   - /site-config/compute/client-request-timeout/change-sas-compute-http-request-timeout.yaml
   ...
   ```

## Additional Resources

For more information about deployment and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
