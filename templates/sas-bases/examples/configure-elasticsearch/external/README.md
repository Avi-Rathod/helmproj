---
category: OpenSearch
tocprty: 80
---

# Configure an External OpenSearch Instance

This README file describes the files used to configure the SAS Viya platform deployment to use an externally managed instance of OpenSearch.

## Prerequisites

Before deploying the SAS Viya platform, make sure you have the following prerequisites:

* An external instance of OpenSearch 2.5 

* The following OpenSearch plug-ins:

	* analysis-icu

	* analysis-kuromoji

	* analysis-nori

	* analysis-phonetic

	* analysis-smartcn

	* analysis-stempel

	* mapper-murmur3

If you are deploying SAS Visual Investigator, the external instance of OpenSearch requires a specific configuration of OpenSearch and its security plugin. For more information, see the README file at `$deploy/sas-bases/examples/configure-elasticsearch/external/config/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/external_opensearch_configuration_requirements_for_sas_visual_investigator.htm` (for HTML format).

## Instructions

In order to use an external OpenSearch instance, you must customize your deployment to point to the required resources and transformers.

1. If you are deploying in Front-door or Full-stack TLS modes, copy the file `$deploy/sas-bases/examples/configure-elasticsearch/external/client-config-tls.yaml` into your `$deploy/site-config/external-opensearch/` directory. Create the `$deploy/site-config/external-opensearch/` directory if it does not already exist.

   If you are deploying in No TLS mode, copy the file `$deploy/sas-bases/examples/configure-elasticsearch/external/client-config-no-tls.yaml` into your `$deploy/site-config/external-opensearch/` directory. Create the `$deploy/site-config/external-opensearch/` directory if it does not already exist.

   Adjust the values in your copied file following the in-line comments.

2. Copy the file `$deploy/sas-bases/examples/configure-elasticsearch/external/secret.yaml` into your `$deploy/site-config/external-opensearch/` directory . Adjust the values in your copied file following the in-line comments.

3. Copy the file `$deploy/sas-bases/examples/configure-elasticsearch/external/external-opensearch-transformer.yaml` into your `$deploy/site-config/external-opensearch/` directory .

4. Go to the base kustomization file (`$deploy/kustomization.yaml`). In the transformers block of that file, add the following content, including adding the block if it doesn't already exist:

   ```yaml
   transformers:
   - site-config/external-opensearch/external-opensearch-transformer.yaml
   ```

5. If you are deploying in Full-stack TLS or Front-door TLS mode, add the following content in the resources block of the base kustomization file. Add the resources block if it does not already exist.

   ```yaml
   resources:
   ...
   - site-config/external-opensearch/client-config-tls.yaml
   - site-config/external-opensearch/secret.yaml
   ...
   ```

   If you are deploying in Front-door TLS mode and the external instance of OpenSearch is not in the same cluster, add the following content in the resources block of the base kustomization file. Add the resources block if it does not already exist.

   ```yaml
   resources:
   ...
   - site-config/external-opensearch/client-config-tls.yaml
   - site-config/external-opensearch/secret.yaml
   ...
   ```
   
   If you are deploying in Front-door TLS mode and the external instance of OpenSearch is in the same cluster, add the following content in the resources block of the base kustomization file. Add the resources block if it does not already exist.

   ```yaml
   resources:
   ...
   - site-config/external-opensearch/client-config-no-tls.yaml
   - site-config/external-opensearch/secret.yaml
   ...
   ```

   If you are not using TLS, add the following content in the resources block of the base kustomization file, including adding the block if it doesn't already exist.

   ```yaml
   resources:
   ...
   - site-config/external-opensearch/client-config-no-tls.yaml
   - site-config/external-opensearch/secret.yaml
   ...
   ```

## Recommendations

To ensure the optimal functionality of index creation within the SAS Viya platform, ensure that the action section inside the config/opensearch.yml file has the auto_create_index set to `-sand__*,-viya_catalog__*,+*`.