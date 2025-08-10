---
category: migration
tocprty: 5
---

# Activate sas-migration-manager

## Overview

The SAS Migration Management service interacts with SAS 9 Content Assessment to
migrate applicable content from a SAS 9 system to SAS Viya 4.

    The SAS Migration Management service accesses and maintains information about SAS 9 objects and their statuses in the migration process.

    The SAS Migration Management service provides the following functions:

    1. Upload content from the SAS 9 system captured by SAS Content Assessment.
    2. Upload profiling information for an object.
    3. Upload code check information for an object.
    4. Update or append objects to the content.
    5. List content based on a filter.
    6. Create migration batches to subset content to be assessed by SAS Content Assessment.
    7. Maintain migration batches, including adding and deleting content based on a filter.
    8. Download a migration batch as a CSV file.
    9. Log migration batch events.

The sas-migration-manager, microservice is deployed in an idle state (scale=0)
by default to save resources in Viya unless the user wants to use the migration
manager. In order to use the migration manager service it will have to be
activated in a deployment. To activate sas-migration-manager follow the
installation steps in this document.

## Installation

To activate sas-migration-manager in your deployment, copy the
`$deploy/sas-bases/examples/sas-migration-manager/scale-migration-on.yaml` file
to your `$deploy/site-config/sas-migration-manager` directory.

After you copy the file, add a reference to it in the transformer block of the
base `kustomization.yaml` file.

```yaml
transformers:
  - sas-migration-manager/scale-migration-on.yaml
```

## Additional Resources

For more information about configuration and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
