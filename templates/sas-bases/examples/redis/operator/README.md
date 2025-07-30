---
category: redis
tocprty: 3
---

# Configuration Settings for Redis Operator

## Overview

Redis is used as a distributed cache for SAS Viya platform services. This
README file describes the settings available for deploying the Redis Operator.

## Installation

You can customize your Redis instance for your SAS Viya platform deployment
by adding a transformer. Example transformers have been provided and are
described below. Based on these descriptions, you can determine whether you
want to customize your Redis deployment.

If you decide to add a transformer, copy the example file that you have
selected and save it in your site-config directory.

Each file contains information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ PRIMARY-COUNT }}. Replace the
entire variable string, including the braces, with the value you want to use.

After you have edited the file, add a reference to it in the transformers block
of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an
example:

```yaml
transformers:
...
- site-config/redis/operator/redis-disable-persistence.yaml
- site-config/redis/operator/redis-modify-cluster-replicas.yaml
- site-config/redis/operator/redis-modify-server-config.yaml
- site-config/redis/operator/redis-modify-storage.yaml
```

## Examples

The example files are located at `$deploy/sas-bases/examples/redis/operator`.
The following list contains a description of each example file for Redis
Operator settings and the file names.

- modify the persistent storage allocation and class (redis-modify-storage.yaml)
- modify the cluster replica count (redis-modify-cluster-replicas.yaml)
- disable persistence (redis-disable-persistence.yaml)
