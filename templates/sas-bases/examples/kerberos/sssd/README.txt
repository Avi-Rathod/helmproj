---
category: security
tocprty: 11
---

# Configure System Security Services Daemon

## Overview

System Security Services Daemon (SSSD) provides access to remote identity providers,
such as LDAP and Microsoft Active Directory. SSSD can be used when using SAS/ACCESS
Interface to Hadoop with a Kerberos-protected Hadoop deployment where identity lookup
is required.

**Note:** Alternatively, nss_wrapper can be used with SAS/ACCESS Interface to Hadoop.
To implement nss_wrapper, follow the instructions in the "nss_wrapper" section of
the README file located at `$deploy/sas-bases/examples/kerberos/sas-servers/README.md`
(for Markdown format) or at `$deploy/sas-bases/docs/configuring_sas_servers_for_kerberos_in_sas_viya_platform.htm` (for HTML format).

## Enable the SSSD Container

1. Add `sas-bases/overlays/kerberos/sssd/add-sssd-container-transformer.yaml` to
the transformers block of the base kustomization.yaml file
(`$deploy/kustomization.yaml`).

    **Important:** This line must come before any network transformers
(transformers that start with "- sas-bases/overlays/network/") and the required
transformer ("- sas-bases/overlays/required/transformers.yaml"). Note that your
configuration may not have network transformers if security is not configured.
This line must also be placed after any Kerberos transformers (transformers
starting with "- sas-bases/overlays/kerberos/sas-servers").

    ```yaml
        transformers:
        ...
        # Place after any sas-bases/overlays/kerberos lines
        - sas-bases/overlays/kerberos/sssd/add-sssd-container-transformer.yaml
        # Place before any sas-bases/overlays/network lines and before
        # sas-bases/overlays/required/transformers.yaml
    ```

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment
Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=
dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm&locale=en).

## Add a Custom Configuration for SSSD

Use these steps to provide a custom SSSD configuration to handle user
authorization in your environment.

1. Copy the files in the `$deploy/sas-bases/examples/kerberos/sssd`
directory to the `$deploy/site-config/kerberos/sssd` directory. Create
the target directory, if it does not already exist.

2. Copy your customer sssd.conf configuration file to
`$deploy/site-config/kerberos/sssd/sssd.conf`.

3. Make the following changes to the base kustomization.yaml file in the $deploy
directory.

    - Add the following to the generators block.

    ```yaml
    generators:
    ...
    - site-config/kerberos/sssd/secrets.yaml
    ```
    - Add a reference to `sas-bases/overlays/kerberos/sssd/add-sssd-configmap-transformer.yaml`
    to the transformers block. The new line must come
after  `sas-bases/overlays/kerberos/sssd/add-sssd-container-transformer.yaml`.

    ```yaml
    transformers:
    ...
    - sas-bases/overlays/kerberos/sssd/add-sssd-configmap-transformer.yaml
    ```

4. Deploy the software using the commands in
[SAS Viya Platform: Deployment
Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=
dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm&locale=en).
