---
category: security
tocprty: 9
---

# Configuring SAS Servers for Kerberos in SAS Viya Platform

## Overview

This README describes the steps necessary to configure your SAS Viya platform
SAS Servers to use Kerberos.

## Prerequisites

### Kerberos Configuration File

Before you start the deployment, obtain the Kerberos configuration file (krb5.conf) and
keytab file for the HTTP service account.

Edit the krb5.conf file and add `renewable = true` under the `[libdefaults]`
section. This allows renewable Kerberos credentials to be used in SAS Viya platform. SAS servers
will renew Kerberos credentials prior to expiration up to the renewable lifetime.
Here is an example:

```yaml
[libdefaults]
  ...
  renewable = true
```

### Keytab File

Obtain a keytab file for the HTTP service account.

If you are using SAS/CONNECT from external clients, such as SAS 9.X, obtain a
keytab for the SAS service account. The HTTP service account and SAS service
account can be placed in the same keytab file for convenience.  If you are using
a single keytab file, the SAS service account should be placed before the HTTP
service account in the keytab file.

Make sure you have tested the keytab files before proceeding with the installation.

### Kerberos Connections

If you want to connect to the CAS Server from external clients through the
binary or REST ports, you must also configure the CAS Server to accept direct
Kerberos connections.

If SAS/ACCESS Interface to Hadoop will be used with a Hadoop
deployment that is Kerberos-protected, either nss_wrapper or System Security Services Daemon (SSSD)
must be configured.  Unlike SSSD, nss_wrapper does not require running in a
privilege elevated container.  If you are using OpenShift Container Platform 4.2 or later, neither
nss_wrapper nor SSSD are required. If SAS/CONNECT is configured to spawn the SAS/CONNECT Server in the
SAS/CONNECT Spawner pod, SSSD must be configured regardless of the container orchestration
platform being used.

#### nss_wrapper

To configure nss_wrapper, make the following changes to the base kustomization.yaml file in the $deploy
directory. Add the following to the transformers block. These additions must come before
`sas-bases/overlays/required/transformers.yaml`.

```yaml
transformers:
...
- sas-bases/overlays/kerberos/nss_wrapper/add-nss-wrapper-transformer.yaml
```

#### System Security Services Daemon (SSSD)

To configure SSSD for SAS Compute Server and SAS Batch
Server, follow the instructions in `$deploy/sas-bases/examples/kerberos/sssd/README.md`
(for Markdown format) or `$deploy/sas-bases/docs/docs/configure_system_security_services_daemon.htm`
(for HTML format). For CAS, follow the instructions in `$deploy/sas-bases/examples/cas/configure/README.md`
(for Markdown format) and `$deploy.sas-bases/docs/configuration_settings_for_cas.htm` (for HTML format).
For SAS/CONNECT, follow the instructions in `$deploy/sas-bases/examples/sas-connect-spawner/README.md`
(for Markdown format) or `$deploy/sas-bases/docs/configure_sasconnect_spawner_in_sas_viya.htm`
(for HTML format).

### Delegation

The aim of configuring for Kerberos is to allow Kerberos authentication to
flow into, between, and out from the SAS Viya platform environment. Allowing SAS servers
to connect to other SAS Viya platform processes and third-party data sources on behalf of
the user is referred to as `delegation`. SAS supports Kerberos Unconstrained
Delegation, Kerberos Constrained Delegation, and Kerberos Resource-based Constrained
Delegation.  Delegation should be configured prior to completing the installation steps below.

The HTTP service account must be trusted for delegation. If you are using
SAS/CONNECT, the SAS service account must also be trusted for delegation.

- [How to configure Kerberos Unconstrained
Delegation](#Configure-Kerberos-Unconstrained-Delegation)
- [How to configure Kerberos Constrained
Delegation](#Configure-Kerberos-Constrained-Delegation)
- [How to configure Kerberos Resource-based
Constrained Delegation](#Configure-Kerberos-Resource-Based-Constrained-Delegation)

### Stored Credentials

As an alternative method to Delegation, external credentials can be stored in an Authentication Domain.
SAS uses the stored credentials to generate Kerberos credentials on the user's behalf. The default
Authentication Domain is KerberosAuth. The Authentication Domain, whether default or custom, will need
to be created in SAS Environment Manager. SAS recommends creating a Custom Group with shared external
credentials and assigning the custom group to the created Authentication Domain.

For more information about creating Authentication Domains, see [External Credentials: Concepts](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calcredentials&docsetTarget=p1ntkxcd5ts4k1n1dboal0ywea70.htm).

**Note:** Stored user credentials take precedence over stored group credentials in the same Authentication Domain. For more information, see [How to configure Kerberos stored credentials](#Configure-Kerberos-Stored-Credentials).

## Installation

### Configure SAS Servers for Kerberos in SAS Viya Platform

1. Copy the files in the `$deploy/sas-bases/examples/kerberos/sas-servers`
directory to the `$deploy/site-config/kerberos/sas-servers` directory. Create
the target directory, if it does not already exist.

2. Copy your Kerberos keytab file and configuration files into the
`$deploy/site-config/kerberos/sas-servers` directory, naming them `keytab` and
`krb5.conf` respectively.

   **Note:** A Kubernetes secret is generated during deployment using the content of the keytab binary file.
   However, the SAS Viya Platform Deployment Operator and the viya4-deployment project do not support creating secrets from
   binary files. For these types of deployments, the Kerberos keytab content must be loaded from an existing
   Kubernetes secret. If you are using either of these deployment types, see [Manually Configure a Kubernetes Secret for the Kerberos Keytab](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm#p1bk7fvjzt9fahn1kllczegxicvi) for the steps.

3. Replace {{ .Values.SPN }} in
`$deploy/site-config/kerberos/sas-servers/configmaps.yaml` under the
`sas-servers-kerberos-sidecar-config` stanza with the name of the
principal as it appears in the keytab file.

4. Make the following changes to the base kustomization.yaml file in the $deploy
directory.

   - Add `site-config/kerberos/sas-servers` to the resources block.

     ```yaml
     resources:
     ...
     - site-config/kerberos/sas-servers
     ```

   - Add the following to the transformers block. These additions must come
     before `sas-bases/overlays/required/transformers.yaml`.

     - If TLS is enabled:

       ```yaml
       transformers:
       ...
       - sas-bases/overlays/kerberos/sas-servers/sas-kerberos-job-tls.yaml
       - sas-bases/overlays/kerberos/sas-servers/sas-kerberos-deployment-tls.yaml
       - sas-bases/overlays/kerberos/sas-servers/cas-kerberos-tls-transformer.yaml
       ```

     - If TLS is not enabled:

       ```yaml
       transformers:
       ...
       - sas-bases/overlays/kerberos/sas-servers/sas-kerberos-job-no-tls.yaml
       - sas-bases/overlays/kerberos/sas-servers/sas-kerberos-deployment-no-tls.yaml
       - sas-bases/overlays/kerberos/sas-servers/cas-kerberos-no-tls-transformer.yaml
       ```

5. Follow the instructions in
`$deploy/sas-bases/examples/kerberos/http/README.md` (for Markdown format) or
`$deploy/sas-bases/docs/configuring_kerberos_single_sign-on_for_sas_viya.htm` (for
HTML format) to configure Kerberos single sign-on. Specifically, in
`$deploy/site-config/kerberos/http/configmaps.yaml` change
`SAS_LOGON_KERBEROS_HOLDONTOGSSCONTEXT` to `true`.

6. When all the SAS Servers are configured in the base kustomization.yaml file, use
the deployment commands described in [SAS Viya Platform Deployment
Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=
dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm&locale=en) to apply
the new settings.

7. After the deployment is started, enable `Kerberos` in SAS Environment
Manager.
    1. Sign into SAS Environment Manager as sasboot or as an Administrator. Go
to the Configuration page.
    2. On the Configuration page, select `Definitions` from the list. Then
select `sas.compute`.
    3. Click the pencil (Edit) icon.
    4. Change `kerberos.enabled` to `on`.
    5. Click `Save`.

### Configure the CAS Server for Direct Kerberos Connections in SAS Viya Platform

If you want to connect to the CAS Server from external clients through the
binary port, perform the following steps in addition to the section above.

1. Copy the files in the `$deploy/sas-bases/examples/kerberos/cas-server`
directory to the `$deploy/site-config/kerberos/cas-server` directory. Create
the target directory, if it does not already exist.

2. Copy your Kerberos keytab and configuration files into the
`$deploy/site-config/kerberos/cas-server` directory, naming them `keytab` and
`krb5.conf` respectively.

3. Replace {{ .Values.SPN }} in
`$deploy/site-config/kerberos/cas-server/configmaps.yaml` under the
`cas-server-kerberos-config` stanza with the name of the service
principal as it appears in the keytab file without the @DOMAIN.COM.

4. Replace {{ .Values.HTTP_SPN }} with the HTTP SPN used for the krb5 proxy sidecar
container without the @DOMAIN.COM.
SAS recommends that you use the same keytab file and SPN for both the CAS
Server and the krb5 proxy sidecar for consistency and to allow REST port direct
Kerberos connections.

5. Make the following changes to the base kustomization.yaml file in the $deploy
directory.

   - Add `site-config/kerberos/cas-server` to the resources block.

     ```yaml
     resources:
     ...
     - site-config/kerberos/cas-server
     ```

   - Add the following to the transformers block.  These additions must come
     before `sas-bases/overlays/required/transformers.yaml`.

     ```yaml
     transformers:
     ...
     - sas-bases/overlays/kerberos/sas-servers/cas-kerberos-direct.yaml
     ```

6. Edit your `$deploy/site-config/kerberos/cas-server/krb5.conf` file. Add the
following to the `[libdefaults]` section:

   ```bash
   [libdefaults]
   ...
   dns_canonicalize_hostname=false
   ```

### Configure SAS/CONNECT for Direct Kerberos Connections in SAS Viya Platform

If you are using SAS/CONNECT from external clients, such as SAS 9.4, perform the
following steps in addition to the section above.

1. Add a reference to
sas-bases/overlays/kerberos/sas-servers/sas-connect-spawner-kerberos-transformer
.yaml
in the transformers block of the kustomization.yaml file in the $deploy
directory.
The reference must come before
`sas-bases/overlays/required/transformers.yaml`. Here is an example:

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/kerberos/sas-servers/sas-connect-spawner-kerberos-transformer.yaml
   - sas-bases/overlays/required/transformers.yaml
   ```

2. Uncomment the `sas-connect-spawner-kerberos-secrets` stanza in
`$deploy/site-config/kerberos/sas-servers/secrets.yaml`. If you are using
separate keytab files for the HTTP service account and SAS service account,
change the `keytab` name to the actual keytab file name in each stanza.

3. Uncomment the `sas-connect-spawner-kerberos-config` stanza in
`$deploy/site-config/kerberos/sas-servers/configmaps.yaml`.

   - Replace {{ .Values.SPN }} with the HTTP SPN from the keytab file without the
     @DOMAIN.COM.

   - If you are using separate keytab files for the HTTP service account and
     SAS service account, change the `keytab` name to the actual keytab file name
     in each stanza.  The keytab file name must match the name used in `secrets.yaml`
     for step 2.

4. Edit your `$deploy/site-config/kerberos/sas-servers/krb5.conf` file. Add the
following to the `[libdefaults]` section:

   ```bash
   [libdefaults]
   ...
   dns_canonicalize_hostname=false
   ```

### Configure Kerberos Unconstrained Delegation

If you are using MIT Kerberos as your KDC, then enabling delegation involves
setting the flag `ok_as_delegate` on the principal.  For example, the following
command adds this flag to the existing HTTP principal:

```bash
kadmin -q "modprinc +ok_as_delegate HTTP/mywebserver.company.com"
```

If you are using Microsoft Active Directory for your KDC, you must set the
delegation option after registering the SPN.  The Active Directory Users and
Computers GUI tool does not expose the delegation options until at least one SPN
is registered against the service account.  The HTTP Service account must be
able to delegate to any applicable data sources.

1. For the HTTP service account, as a Windows domain administrator, right-click
the name and select `Properties`.

2. In the `Properties` dialog, select the `Delegation` tab.

3. On the `Delegation` tab, you must select `Trust this user for delegation to
any services (Kerberos only).`

4. In the `Properties` dialog, select `OK`.

If you are using SAS/CONNECT, repeat the steps in this section for the SAS service account.

### Configure Kerberos Constrained Delegation

1. In `$deploy/site-config/kerberos/http/configmaps.yaml`, set
`SAS_LOGON_KERBEROS_HOLDONTOGSSCONTEXT` to `false`.

2. In the `sas-servers-kerberos-sidecar-config` stanza of `$deploy/site-config/kerberos/sas-servers/configmaps.yaml`,
add the following under `literals`:

   ```yaml
   - SAS_CONSTRAINED_DELEG_ENABLED="true"
   ```

3. If you are using SAS/CONNECT, in the `sas-connect-spawner-kerberos-config`
stanza, add the following under `literals`:

   ```yaml
   - SAS_SERVICE_PRINCIPAL={{ .Values.SAS_service_account_SPN }}
   - SAS_CONSTRAINED_DELEG_ENABLED="true"
   ```

If you are using MIT Kerberos as your KDC, then enabling delegation involves
setting the flag `ok_to_auth_as_delegate` on the principal.  For example, the
following command adds the flag to the existing HTTP principal:

```bash
kadmin -q "modprinc +ok_to_auth_as_delegate HTTP/mywebserver.company.com"
```

If you are using Microsoft Active Directory for your KDC, you must set the
delegation option after registering the SPN.  The Active Directory Users and
Computers GUI tool does not expose the delegation options until at least one SPN
is registered against the service account.  The HTTP Service account must be
able to delegate to any applicable data sources.

1. For the HTTP service account, as a Windows domain administrator, right-click
the account name and select `Properties`.

2. In the `Properties` dialog, select the `Delegation` tab.

3. On the `Delegation` tab, select `Trust this user for delegation to
the specified services only` and `Use any authentication protocol`.

4. Select `Add...`

5. In the `Add Services` panel, select `Users and Computers...`

   1. In the `Select Users or Computers` dialog box, complete the following for
      the Kerberos-protected services that the SAS Servers access:

      1. In the `Enter the object names to select` text box, enter the account
         for the Kerberos protected services the SAS Server accesses, such as Microsoft
         SQL Server.  Then, select `Check Names`.

      2. If the name is found, select `OK`.

      3. Repeat the previous two steps to select additional SPNs for the SAS
         Servers to access.

      4. When you are done, select `OK`.

   2. In the `Add Services` dialog box, select `OK`.

6. In the `Properties` dialog, select `OK`.

If you are using SAS/CONNECT, repeat the steps in this section for the SAS service account.

### Configure Kerberos Resource-Based Constrained Delegation

1. In `$deploy/site-config/kerberos/http/configmaps.yaml`, set
`SAS_LOGON_KERBEROS_HOLDONTOGSSCONTEXT` to `false`.

2. In the `sas-servers-kerberos-sidecar-config` stanza of `$deploy/site-config/kerberos/sas-servers/configmaps.yaml`,
add the following under `literals`:

   ```yaml
   - SAS_CONSTRAINED_DELEG_ENABLED="true"
   ```

3. If you are using SAS/CONNECT, in the `sas-connect-spawner-kerberos-config`
stanza, add the following under `literals`:

   ```yaml
   - SAS_SERVICE_PRINCIPAL={{ .Values.SAS_service_account_SPN }}
   - SAS_CONSTRAINED_DELEG_ENABLED="true"
   ```

Kerberos Resource-based Constrained Delegation can only be configured using
Microsoft PowerShell.  Resource-based constrained delegation gives control of
delegation to the administrator of the back-end service, therefore, the
delegation permissions are applied on the back-end service being accessed.

**Note:** The examples below demonstrate adding a single identity that is trusted for
delegation. To add multiple identities, use the format: `($identity1),($identity2)`.

If the back-end service being accessed is running on Windows under the Local System account, then
the front-end service principal is applied to the back-end service Computer Object.

```powershell
$sashttpidentity = Get-ADUser -Identity <HTTP service account>
Set-ADComputer <back-end service hostname> -PrincipalsAllowedToDelegateToAccount $sashttpidentity
```

If the back-end servers being accessed is running on Unix/Linux or on Windows under a Domain Account,
then the front-end service principal is applied to the Domain Account of the back-end
service where the service principal is registered.

```powershell
$sashttpidentity = Get-ADUser -Identity <HTTP service account>
Set-ADUser <back-end service Domain Account> -PrincipalsAllowedToDelegateToAccount $sashttpidentity
```

If you are using SAS/CONNECT, the HTTP service account must trust the SAS service account.

```powershell
$sasidentity = GetADUser -Identity <SAS service account>
Set-ADUser <HTTP service account> -PrincipalsAllowedToDelegateToAccount $sasidentity
```

If you are using SAS/CONNECT and the back-end service is running on Windows under the Local System account, then
the SAS service principal is applied to the back-end service Computer Object.

```powershell
$sasidentity = GetADUser -Identity <SAS service account>
Set-ADComputer <back-end service hostname> -PrincipalsAllowedToDelegateToAccount $sasidentity
```

If you are using SAS/CONNECT and the back-end service is running on UNIX/Linux or on Windows under a Domain Account,
then the SAS service principal is applied to the Domain Account of the back-end service where the principal
is registered.

```powershell
$sasdentity = Get-ADUser -Identity <SAS service account>
Set-ADUser <back-end service Domain Account> -PrincipalsAllowedToDelegateToAccount $sasidentity
```

### Configure Kerberos Stored Credentials

Configure the usage of stored credentials:

1. In the `sas-servers-kerberos-sidecar-config` block of `$deploy/site-config/kerberos/sas-servers/configmaps.yaml`, set the desired Authentication Domain to query for stored credentials.

   ```yaml
   literals:
   ...
   - SAS_KRB5_PROXY_CREDAUTHDOMAIN=KerberosAuth # Name of authentication domain to query for stored credentials
   ```

2. Uncomment these lines in the `sas-servers-kerberos-container-config` block of `$deploy/site-config/kerberos/sas-servers/configmaps.yaml`:

   ```yaml
   literals:
   ...
   - SAS_KRB5_PROXY_CHECKCREDSERVICE="true" # Set to true if SAS should prefer stored credentials over Constrained Delegation
   - SAS_KRB5_PROXY_LOOKUPINGROUP="true"    # Set to true if SAS should look for a group credential if no user credential is stored
   ```
