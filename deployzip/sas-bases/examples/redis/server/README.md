---
category: redis
tocprty: 1
---

# Configuration Settings for Redis

## Overview

Redis is used as a distributed cache for SAS Viya platform services. This README file describes the settings available for deploying Redis.

## Installation

The `redis-modify-memory.yaml` transformer file allows you to change the memory resources for Redis nodes. The default required value is 90Mi, and the default limit is 500Mi. The Redis 'maxmemory' setting is set to 90% of the container memory limit. To change those values:

1. Copy the `$deploy/sas-bases/examples/redis/server/redis-modify-memory.yaml` file to `site-config/redis/server/redis-modify-memory.yaml`.

2. The variables in the copied file are set
off by curly braces and spaces, such as {{ MEMORY-LIMIT }}. Replace
each variable string, including the braces, with the values you want to use. If you want to use the default for a variable, make no changes to that variable.

3. After you have edited the file, add a reference to it in the transformers block
of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an
example:

   ```yaml
   transformers:
   ...
   - site-config/redis/server/redis-modify-memory.yaml
   ```