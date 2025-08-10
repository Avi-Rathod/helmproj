---
category: haAndScaling
tocprty: 3
---

# High Availability (HA) in the SAS Viya Platform

## Overview

The SAS Viya platform can be deployed as a High Availability (HA) system. In this mode,
the SAS Viya platform has redundant stateless and stateful services to handle service outages,
such as an errant Kubernetes node.

## Enable High Availability

A kustomize transformer enables High Availability (HA) in the SAS Viya platform among the
stateless microservices. Stateful services, with the exception of SMP CAS, are
enabled HA at initial deployment.

Add the `sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml` to the
transformers block in your base kustomization.yaml file.

```yaml
...
transformers:
...
- sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml
```
After the base kustomization.yaml file is modified, deploy the software using the commands
that are described in [Deploy the Software](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).

**Note:** Ensure that the version indicated by the version selector for the
document matches the version of your SAS Viya platform software.
