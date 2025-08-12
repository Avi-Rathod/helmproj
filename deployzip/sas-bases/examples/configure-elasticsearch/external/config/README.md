---
category: OpenSearch
tocprty: 90
---

# External OpenSearch Configuration Requirements for SAS Visual Investigator

This README file describes OpenSearch's configuration requirements for SAS Visual Investigator.

**Note:** If your deployment does not include SAS Visual Investigator, this README contains no information that pertains to you.

## OpenSearch Configuration Requirements

In the action section inside the config/opensearch.yml file, the destructive_requires_name setting should be set to false.

## Security Plugin Configuration Requirements

In the config.dynamic section inside the config/opensearch-security/config.yml file, the do_not_fail_on_forbidden setting should be set to true.

In the config.dynamic.authc section inside the config/opensearch-security/config.yml file, the following four authentication domains must be defined in this exact order:

1. Basic authentication with challenge set to false.

2. OpenID authentication using user_name as subject key.

- Configure the openid_connect_url to point to SAS Logon's OpenID endpoint.

- Configure the openid_connect_idp.pemtrustedcas_filepath to point to the certificates needed to connect to SAS Logon.

3. OpenId authentication using client_id as subject key.

- Configure the openid_connect_url to point to SAS Logon's OpenID endpoint.

- Configure the openid_connect_idp.pemtrustedcas_filepath to point to the certificates needed to connect to SAS Logon.

4. Basic authentication with challenge set to true.

## Security Plugin Config Example

For a security config example, see `$deploy/sas-bases/examples/configure-elasticsearch/external/config/config.yaml`.