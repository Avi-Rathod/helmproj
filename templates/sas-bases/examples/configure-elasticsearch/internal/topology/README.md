---
category: OpenSearch
tocprty: 40
---

# Configure a Default Topology for OpenSearch

## Overview

This README file describes the files used to specify and modify the topology to be used by the sas-opendistro operator.

**Note:** The default topology should be set according to the target environment and usage requirements.
The transformer can reference an existing or custom topology.

**Note:** SAS terminology standards prohibit the use of the term "master." However, this document refers to the term "master node" to maintain alignment with OpenSearch documentation.

## Modifying Topologies

The default installation topology consists of one OpenSearch node configured as both a master and a data node. Although this topology is acceptable for initial small scale data imports, configuration, and testing, SAS does not recommend that it be used in a production environment.

The recommended production topology should consist of no less than three master nodes and no less than three data storage nodes. This topology provides the following benefits:

* High availability - Query loads are shared amongst the available data nodes.
* High resiliency - Failure of any one node does not bring down the service. Performance is degraded while the failed node is brought back online.
* Data resiliency - Data is redundantly shared amongst the data nodes. A failure of one data node, even complete corruption of its disks, does not result in any loss of data. When the failed node is brought back on line the data is reconstructed from duplicate copies on other nodes. 

## Migrating to Production Setup

If you wish to migrate your initial data from the initial setup to the production setup, you must modify the cluster topology in such a manner that no data or configuration is lost.

One way of doing this is to transition your topology through an intermediate state into your final production state. Here is an example 

|         Initial State       |   Intermediate State     |   Final State |
| :---:                         | :---:                      | :---: |
|       [Master/Data Node] | [Master/Data Node] | |
|                             |   [Master Node 1]   |      [Master Node 1]|
|                             |   [Master Node 2]   |      [Master Node 2]|
|                             |   [Master Node 3]   |      [Master Node 3]|
|                             |   [Data Node 1]      |      [Data Node 1]|
|                             |   [Data Node 2]      |      [Data Node 2]|
|                             |  [Data Node 3]       |     [Data Node 3] |

This example allows the cluster to copy the data stored on the Master/Data Node across to the data nodes. The migration will have to pause in the intermediate state for a period while the data is spread across the cluster. Depending on the volume of data, this should be completed within a few tens of minutes.

### Migration Process

1. Copy the `migrate-topology-step1.yaml` file into your site-config directory.

2. Edit the example topology to reflect your desired topology:
   * set the appropriate number of master nodes and data nodes
   * set the heap size for each of the nodes - data nodes will need more heap space
   * set the amount of disk space allowed to store the indexes

3. Remove the following line from the transformers block of the base kustomization file (`$deploy/kustomization.yaml`) if it is present.

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/internal-elasticsearch/ha-transformer.yaml
   ...
   ```

4. Add the topology reference to the transformers block of the base kustomization.yaml file.  Here is an example of a modified base kustomization.yaml file with a reference to the custom topology example:

   ```yaml
   transformers:
   ...
   - site-config/configure-elasticsearch/internal/topology/migrate-topology-step1.yaml
   ```

5. Perform the commands to update the software. These are the same as the commands to originally deploy the software as outlined in [SAS Viya Platform: Deployment Guide: Deployment: Installation: Deploy the Software](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).
The important difference to note is that as you have now modified the `$deploy/kustomization.yaml` file to include your topology changes, the deployment process will not 
perform a complete rebuild but will instead adapt the existing system to your new configuration. 

6. Once the new configuration has deployed, wait for the new servers to share out all the data.

7. Repeat steps 1 through 5 using the `migrate-topology-step2.yaml` file. Ensure that you make the same modifications to the step2 file as you made in the step1 file.

## Topology Examples

### Custom Topology Example

The custom topology example should be used to define and customize highly available production OpenSearch deployments. See the example file located at 
`sas-bases/examples/configure-elasticsearch/internal/topology/custom-topology.yaml`. 

### Single Node Topology Example

The single node topology example should not be used in production.  The single node topology is intended to minimize resources in development, demonstration, class, and test deployments.
`sas-bases/examples/configure-elasticsearch/internal/topology/single-node-topology.yaml`.

## Additional Configuration

In addition to the general cluster topology, properties such as the heap size and disk size of each individual node set can be adjusted depending on the  use case for the OpenSearch cluster, expected index sizes, shard numbers, and/or hardware constraints. 

### Configuring the Volume Claim
When the volume claim's storage capacity is not specified in the node spec, the operator creates a PersistentVolumeClaim with a capacity of 128Gi for each node in the OpenSearch cluster by default. 

Similarly, when the volume claim's storage class is not specified in the node spec, the operator creates a PersistentVolumeClaim using either the default StorageClass for that OpenSearch cluster (if specified) or the default storage class for the Kubernetes cluster (see `sas-bases/examples/configure-elasticsearch/internal/storage/README.md` for instructions for configuring a default storage class for the OpenSearch cluster).

To define your own volume claim template with your desired storage capacity and the Kubernetes storage class that is associated with the persistent volume, see the example file located at `sas-bases/examples/configure-elasticsearch/internal/topology/custom-topology-with-custom-volume-claim.yaml` . Replace {{ STORAGE-CLASS }} with the name of the StorageClass and {{ STORAGE-CAPACITY }} with the desired storage capacity for this volume claim.

### Configuring the Heap Size

The amount of heap size dedicated to each node directly impacts the performance of OpenSearch. If the heap is too small, the garbage collection will cause frequent pauses, resulting in reduced throughput and regular small latency spikes. If the heap is too large, on the other hand, full-heap garbage collection may cause infrequent but long latency spikes.

Generally, the heap size value should be up to half of the available physical RAM with a maximum of 32GB. 

The maximum heap size also affects the maximum number of shards that can be safely stored on the node without suffering from oversharding and circuit breaker events. As a rule of thumb you should aim for 25 shards or fewer per GB of heap memory with each shard not exceeding 50 GB. 

See `sas-bases/examples/configure-elasticsearch/internal/topology/custom-topology-with-custom-heap-size.yaml` for an example of how to configure the amount of heap memory dedicated to OpenSearch nodes. Replace {{ HEAP-SIZE }} with the appropriate heap size for your needs. 

## Installing a Custom Topology

1. Copy the example topology file into your site-config directory.

2. Edit the example topology as directed by comments in the file.

3. Remove the following line from the transformers block of the base kustomization file (`$deploy/kustomization.yaml`) if it is present.

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/internal-elasticsearch/ha-transformer.yaml
   ...
   ```

4. Add the topology reference to the transformers block of the base kustomization.yaml file.  Here is an example of a modified base kustomization.yaml file with a reference to the custom topology example:

   ```yaml
   transformers:
   ...
   - site-config/configure-elasticsearch/internal/topology/custom-topology.yaml
   ```

## Additional Resources

For more information, see
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

 