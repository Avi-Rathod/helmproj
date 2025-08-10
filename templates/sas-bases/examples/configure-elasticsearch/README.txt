---
category: OpenSearch
tocprty: 10
---

# OpenSearch for SAS Viya Platform

## Overview

[OpenSearch](https://opensearch.org/) is an Apache 2.0 licensed search and analytics suite based on Elasticsearch 7.10.2 . The SAS Viya platform provides two options for your search cluster: an internal instance provided by SAS or an external instance you would like the SAS Viya platform to utilize. Before deploying, you must select which of these options you want to use for your SAS Viya platform deployment. 

**Note**: The search cluster must be either internally managed or externally managed. SAS does *not* support mixing internal and external search clusters in the same deployment. Once deployed, you cannot switch between an internal and external search cluster.

## Internally Managed

SAS Viya platform support for an internally managed search cluster is provided by a proprietary `sas-opendistro` Kubernetes operator.

If you want to use an internal instance of OpenSearch, refer to the README file located at `$deploy/sas-bases/overlays/internal-elasticsearch/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/configure_an_internal_opensearch_instance_for_sas_viya.htm` (for HTML format).

## Externally Managed

If you want to use an external instance of OpenSearch, you should refer to the README file located at `$deploy/sas-bases/examples/configure-elasticsearch/external/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/configure_an_external_opensearch_instance.htm` (for HTML format).

Externally managed cloud subscriptions to Elasticsearch and Open Distro for Elasticsearch are not supported.

### Security Considerations 

SAS strongly recommends the use of SSL/TLS to secure data in transit. You should follow the documented best practices provided by OpenSearch and your cloud platform provider for securing access to your external OpenSearch instance using SSL/TLS. Securing your OpenSearch cluster with SSL/TLS entails the use of certificates. In order for the SAS Viya platform to connect directly to a secure OpenSearch cluster, you must provide the OpenSearch cluster's CA certificate to the SAS Viya platform prior to deployment. Failing to configure the SAS Viya platform to trust the OpenSearch cluster's CA certificate results in "Connection refused" errors. For instructions on how to provide CA certificates to the SAS Viya platform, see the section labeled "Incorporating Additional CA Certificates into the SAS Viya Platform Deployment" in the README file at `$deploy/sas-bases/examples/security/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/configure_network_security_and_encryption_using_sas_security_certificate_framework.htm` (for HTML format).