---
category: haAndScaling
tocprty: 5
---

# Single Replica Scaling the SAS Viya Platform


## Overview

The SAS Viya platform deploys stateful components in a High Availability configuration by
default. This feature requires additional resources to run and can be disabled if it is not needed.
Do not perform these steps on an environment that has already been configured.

This feature triggers outages during updates as the single replica components update.

- RabbitMQ
- Consul
- internal instances of PostgreSQL


## Installation


A series of kustomize transformers modifies the appropriate SAS Viya platform
deployment components to a single replica mode.

Add `sas-bases/overlays/scaling/single-replica/transformer.yaml` to the
transformers block in your base kustomization.yaml file. Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/scaling/single-replica/transformer.yaml
```

To apply the change, run `kustomize build -o site.yaml`
