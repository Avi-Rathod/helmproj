---
category: dataServer
tocprty: 1
---

# Configure PostgreSQL

## Overview

The default PostgreSQL server (used by most micro-services) in the SAS Viya platform is called "Platform PostgreSQL". The SAS Viya platform can handle multiple PostgreSQL servers at once, but only specific micro-services use servers besides the default. Consult the documentation for your order to see if you have products that require their own PostgreSQL in addition to the default.

The SAS Viya platform provides two options for your PostgreSQL servers: internal instances provided by SAS or external PostgreSQL that you would like the SAS Viya platform to utilize. Before deploying, you must select which of these options you want to use for your SAS Viya platform deployment. If you follow the instructions in the SAS Viya Platform Deployment Guide, the deployment includes an internal instance of PostgreSQL.

**Note**: PostgreSQL servers must be all internally managed or all externally managed. SAS does *not* support mixing internal and external PostgreSQL servers in the same deployment.
For information about moving from an internal PostgreSQL server to an external one, see the [PostgreSQL Data Transfer Guide](https://go.documentation.sas.com/doc/en/itopscdc/default/pgdatamig/titlepage.htm).

## Installation

### Platform PostgreSQL

Platform PostgreSQL is required in the SAS Viya platform.

Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the resources block of that file, add the following content, including adding the block if it doesn't already exist:

```yaml
resources:
- sas-bases/overlays/postgres/platform-postgres
```

Then, follow the appropriate subsection to continue installing or configuring Platform PostgreSQL as either internally or externally managed.

#### Internally Managed

Follow the steps in the "Configure Crunchy Data PostgreSQL" README located at `$deploy/sas-bases/examples/crunchydata/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_crunchy_data_postgresql.htm` (for HTML format).

#### Externally Managed

Follow the steps in the section "External PostgreSQL Configuration".

### Common Data Store (CDS) PostgreSQL

CDS PostgreSQL is an additional PostgreSQL server that some services in your SAS Viya platform deployment may want to utilize, providing a second database that can be configured separately from the default PostgreSQL server.

Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the resources block of that file, add the following content, including adding the block if it doesn't already exist:

```yaml
resources:
- sas-bases/overlays/postgres/cds-postgres
```

Then, follow the appropriate subsection to continue installing or configuring CDS PostgreSQL as either internally or externally managed.

#### Internally Managed

Follow the steps in the "Configure Crunchy Data PostgreSQL" README located at `$deploy/sas-bases/examples/crunchydata/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_crunchy_data_postgresql.htm` (for HTML format).

#### Externally Managed

Follow the steps in the section "External PostgreSQL Configuration".

### External PostgreSQL Configuration

External PostgreSQL is configured by modifying the DataServer CustomResource to describe your PostgreSQL server. Follow the below steps separately for each external PostgreSQL server in your Viya deployment.

1. Copy the file `$deploy/sas-bases/examples/postgres/postgres-user.env` into your `$deploy/site-config/postgres/` directory and make it writable:

   ```bash
   chmod +w $deploy/site-config/postgres/postgres-user.env
   ```

2. Rename the copied file to something unique. SAS recommends following the naming convention: `{{ POSTGRES-SERVER-NAME }}-user.env`. For example, a copy of the file for Platform PostgreSQL might be called `platform-postgres-user.env`.

   **Note:** Take note of the name and path of your copied file. This information will be used in a later step.

3. Adjust the values in your copied file following the in-line comments.

4. Go to the base kustomization file (`$deploy/kustomization.yaml`). In the secretGenerator block of that file, add the following content, including adding the block if it doesn't already exist:

   ```yaml
   secretGenerator:
   - name: {{ POSTGRES-USER-SECRET-NAME }}
     envs:
     - {{ POSTGRES-USER-FILE }}
   ```

5. In the added secretGenerator, fill out the user-defined values as follows:

   1. Replace `{{ POSTGRES-USER-SECRET-NAME }}` with a unique name for the secret. For example, you might use `platform-postgres-user` if specifying the user for Platform PostgreSQL.

   2. Replace `{{ POSTGRES-USER-FILE }}` with the path of the file you copied in Step 2. For example, this may be something like `site-config/postgres/platform-postgres-user.env`.

   **Note:** Take note of the name you give this secretGenerator. This information will be used in a later step.

6. Copy the file `$deploy/sas-bases/examples/postgres/dataserver-transformer.yaml` into your `$deploy/site-config/postgres` directory and make it writable:

   ```bash
   chmod +w $deploy/site-config/postgres/dataserver-transformer.yaml
   ```

7. Rename the copied file to something unique. SAS recommends following the naming convention: `{{ POSTGRES-SERVER-NAME }}-dataserver-transformer.yaml`. For example, a copy of the transformer targeting Platform PostgreSQL might be called `platform-postgres-dataserver-transformer.yaml`, and if you have CDS PostgreSQL, then a copy of the transformer targeting CDS PostgreSQL might be called `cds-postgres-dataserver-transformer.yaml`.

   **Note:** Take note of the name and path of your copied file. This information will be used in step 9.

8. Adjust the values in your copied file following the guidelines in the comments.

9. In the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`), add references to the files you renamed in step 7. The following example is based on the deployment using a file named `platform-postgres-dataserver-transformer.yaml` for the Platform PostgreSQL instance:

   ```yaml
   transformers:
   - site-config/postgres/platform-postgres-dataserver-transformer.yaml
   ```

#### Setting a Custom Database Name

By default, the SAS Viya platform uses a database named "SharedServices" in each PostgreSQL server.

To set a custom database name, uncomment the surrounding block and replace the `{{ DB-NAME }}` variable in your copied `dataserver-transformer.yaml` file(s) with the custom database name.

#### Security Considerations

SAS strongly recommends the use of SSL/TLS to secure data in transit. You should follow the documented best practices provided by your cloud platform provider for securing access to your database using SSL/TLS. Securing your database server with SSL/TLS entails the use of certificates. Upon securing your database server, your cloud platform provider may provide you with a server CA certificate. In order for the SAS Viya platform to connect directly to a secure database server, you must provide the server CA certificate to the SAS Viya platform prior to deployment. Failing to configure the SAS Viya platform to trust the database server CA certificate results in "Connection refused" errors or in communications falling back to insecure modes. For instructions on how to provide CA certificates to the SAS Viya platform, see the section labeled "Incorporating Additional CA Certificates into the SAS Viya Platform Deployment" in the README file at `$deploy/sas-bases/examples/security/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/configure_network_security_and_encryption_using_sas_security_certificate_framework.htm` (for HTML format).

When using an SQL proxy for database communication, it might be possible to secure database communication in accordance with the cloud platform vendor's best practices without the need to import your database server CA certificate. Some cloud platforms, such as the Google Cloud Platform, allow the use of a proxy server to connect to the database server indirectly in a manner similar to a VPN tunnel. These platform-provided SQL proxy servers obtain certificates directly from the cloud platform. In this case, a database server CA certificate is obtained automatically by the proxy and you do not need to provide it during deployment. To find out more about SQL proxy connections to the database server, consult your cloud provider's documentation.

##### Google Cloud Platform Cloud SQL for PostgreSQL Prerequisites

If you are using Google Cloud SQL for PostgreSQL, the following steps are required for each PostgreSQL server. For example, if you have both a Platform PostgreSQL server and a CDS PostgreSQL server, then you need a separate sql-proxy for each server.

1. Copy the file `$deploy/sas-bases/examples/postgres/cloud-sql-proxy.yaml` to your `$deploy/site-config/postgres/` directory and make it writable:

   ```bash
   chmod +w $deploy/site-config/postgres/cloud-sql-proxy.yaml
   ```

2. Rename the copied file to something unique. SAS recommends following the naming convention: `{{ POSTGRES-SERVER-NAME }}-cloud-sql-proxy.yaml`. For example, a copy of the transformer targeting Platform PostgreSQL might be called `platform-postgres-cloud-sql-proxy.yaml`, and if you have CDS PostgreSQL, then a copy of the transformer targeting CDS PostgreSQL might be called `cds-postgres-cloud-sql-proxy.yaml`.

   **Note:** Take note of the name and path of your copied file. This information will be used in step 4.

3. Adjust the values in your copied file following the guidelines in the file's comments.

4. In the resources block of the base kustomization.yaml (`$deploy/kustomization.yaml`), add references to the files you renamed in step 2. The following example is based on the deployment using a file named `platform-postgres-cloud-sql-proxy.yaml`:

   ```yaml
   resources:
   - site-config/postgres/platform-postgres-cloud-sql-proxy.yaml
   ```

5. The Google Cloud SQL Auth Proxy requires a Google Service Account Key. It retrieves this key from a Kubernetes Secret. To create this secret you must place the Service Account Key required by the Google sql-proxy in the file `$deploy/site-config/postgres/ServiceAccountKey.json` (in JSON format).

6. Go to the base kustomization file (`$deploy/kustomization.yaml`). In the secretGenerator block of that file, add the following content, including adding the block if it doesn't already exist:

   ```yaml
   secretGenerator:
   - name: sql-proxy-serviceaccountkey
     files:
     - credentials.json=site-config/postgres/ServiceAccountKey.json
   ```

7. The file `$deploy/sas-bases/overlays/postgres/external-postgres/gcp-tls-transformer.yaml` allows database clients and the sql-proxy pod to communicate in clear text. This transformer must be added after all other security transformers.

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/postgres/external-postgres/gcp-tls-transformer.yaml
   ```

## DataServer CustomResource

You can add PostgreSQL servers to the SAS Viya platform via the DataServer.webinfdsvr.sas.com [CustomResource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/). This CustomResource is used to inform the SAS Viya platform of the location and credentials for PostgreSQL servers. DataServers can be configured to reference either internally managed Crunchy Data PostgreSQL clusters or externally managed PostgreSQL servers.

**Note**: DataServer CustomResources will not provision PostgreSQL servers on your behalf.

To view the DataServer CustomResources in your SAS Viya platform deployment, run the following command.

```bash
kubectl get dataservers.webinfdsvr.sas.com -n {{ NAME-OF-NAMESPACE }}
```
