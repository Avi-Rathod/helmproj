---
category: OpenSearch
tocprty: 50
---

# Configure a Run User for OpenSearch

In a default deployment of the SAS Viya platform, the OpenSearch JVM process runs under the fixed user ID (UID) of 1000. A fixed UID is required so that files that are written to storage for the search indices can be successfully read after subsequent restarts.

If you do not want OpenSearch to run with UID 1000, you can specify a different UID for the process. You can take the following steps to apply a transformer that changes the UID of the OpenSearch processes to another value.

**Note:** The decision to change the UID of the OpenSearch processes must be made at the time of the initial deployment. The UID cannot be changed after the SAS Viya platform has been deployed.

## Configure Run User

To configure OpenSearch to run as a different UID:

1. Copy the Run User transformer from `$deploy/sas-bases/examples/configure-elasticsearch/internal/run-user/run-user-transformer.yaml` into the `$deploy/site-config` directory.

2. Open the run-user-transformer.yaml file for editing. Replace `{{ USER-ID }}` with the UID under which the OpenSearch processes should run.

3. Add the run-user-transformer.yaml file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:
   
   ```yaml
   transformers:
   ...
   - site-config/run-user-transformer.yaml
   ```

## Limitations

* Changing the UID of the OpenSearch processes can be done at initial deployment time only.
* It is not possible to change the group ID (GID) of the OpenSearch processes.

## Additional Resources

For more information, see
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).