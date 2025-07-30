---
category: OpenSearch
tocprty: 30
---

# Configure a Default StorageClass for OpenSearch

OpenSearch requires a StorageClass to be configured in the Kubernetes cluster that provides block storage (e.g. virtual disks)
or a local file system mount to store the search indices. Remote file systems, such as NFS, should not be used to store the search indices.

By default, the OpenSearch deployment uses the default StorageClass defined in the Kubernetes cluster. If a
different StorageClass is required to meet the requirements, this README file describes how to specify a new StorageClass and
configure it to be used by OpenSearch.

**Note:** The default StorageClass should be set according to the target environment and usage requirements. The transformer can reference an existing or custom StorageClass.

In order to specify a default StorageClass to be used by OpenSearch, you must customize your deployment to include a transformer.

## Configure Storage Class

If a new StorageClass must be defined in the target cluster to meet the requirements for OpenSearch, consult the documentation for the target Kubernetes platform 
for details on available storage options and how to configure a new StorageClass.

## Configure Default Storage Class 

1. Copy the StorageClass transformer from `$deploy/sas-bases/examples/configure-elasticsearch/internal/storage/storage-class-transformer.yaml` 
   into the `$deploy/site-config` directory.

2. Open the storage-class-transformer.yaml file for editing and replace `{{ STORAGE-CLASS }}` with the name of the StorageClass to be used by OpenSearch.

3. Add the storage-class-transformer.yaml file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:
   
   ```yaml
   transformers:
   ...
   - site-config/storage-class-transformer.yaml
   ```

## StorageClass Limitations

* The StorageClass for an existing PersistentVolumeClaim cannot be changed. 
* Changing a StorageClass requires the cluster to be redeployed.

## Additional Resources

For more information, see
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

 