---
category: migration
tocprty: 8
---

# Convert CAS Server Definitions for Migration

## Overview

This readme describes how to convert SAS Viya 3.x CAS server definitions into
SAS Viya 4 Custom Resources (CR) using the sas-migration-cas-converter.sh script.

## Prerequisites

To convert SAS Viya 3.x CAS servers into compatible SAS Viya 4 CRs, you must
first run the inventory playbook to create a migration package. The package will
contain a YAML file with the name of each of your CAS servers, such as
cas-shared-default.yaml. Instructions to create a migration package using
this playbook are given in the SAS Viya Platform Administration Guide.

You perform the conversion process by specifying the name of the YAML file as an
argument to the sas-migration-cas-converter.sh script. You can specify the `-f`
or `--file` argument. You can specify the `-o` or `--output` option to specify
the location of the output file for the converted custom resource. By default,
if no output option is specified, the YAML file is created in the current
directory.

When you run the conversion script, a file with the custom resource is created
in the format of {{ CAS-SERVER-NAME }}-migration-cr.yaml.

## Restore from a Backup Location

If you have data and permstore content to restore, use the `cas-migration.yaml`
patch in `\$deploy/sas-bases/examples/migration/cas/cas-components` to specify
the backup location to restore from. This patch is already included in the
kustomization.yaml file in the `cas-components` directory. To configure this
patch:

1. Open cas-migration.yaml to modify its contents.

2. Set up the NFS mount by replacing the NFS-MOUNT-PATH and NFS-SERVER tokens
   with the mounted path to your backup location and the NFS server where it
   lives:

   ```yaml
   nfs:
     path: {{NFS-MOUNT-PATH}}
     server: {{NFS-SERVER}}
   ```

3. To include the newly created CAS custom resource in the manifest, add a
   reference to it in the resources block of the base kustomization.yaml file
   in the migration example (there is an example commented out). After you
   run `kustomize build` and apply the manifest, your server is created.
   Your backup content is restored if you included the cas-migration.yaml
   patch with a valid backup location.

## Enable State Transfer

Enabling state transfers allows the sessions, tables and state of a running cas server to be preserved
between a running CAS server and a new CAS server instance which will be started as part of the CAS server upgrade.

In the base kustomization.yaml file in the migration example (there are examples commented out):

* Uncomment the `- cas-components/state-transfer/transfer-pvc.yaml` line from the resources block.
* Uncomment the `- cas-components/state-transfer/support-state-transfer.yaml` line from the transformers block.

## Example

Run the script:

```bash
./sas-migration-cas-converter.sh -f cas-shared-default.yaml -o .
```

The output from this command is a file named
`cas-shared-default-migration-cr.yaml`.

## Additional Resources

For more information about CAS migration, see [SAS Viya Platform Administration: Promotion and Migration](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=promigwlcm&docsetTarget=home.htm).

**Note:** Ensure that the version indicated by the version selector for the document matches the version of your SAS Viya platform software.
