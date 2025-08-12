---
category: SAS Startup Sequencer
tocprty: 1
---

# Disabling the SAS Start-Up Sequencer

## Overview

The SAS Start-Up Sequencer is configured to start pods in an predetermined, ordered sequence to ensure that pods are efficiently and effectively
started in a manner that improves startup time.   This design ensures that certain components start before others and allows Kubernetes to pull container Images in a
priority-based sequence.  It also provides a degree of resource optimization, in that resources are more efficiently spent during SAS Viya platform start-up with a
priority given to starting essential components first.

However, there may be cases where this optimization is not desired by an administrator.  For these cases, we provide the ability to disable this feature
by applying a transformer that updates the components in your cluster that prevents the start sequencer functionality from executing. 

## Installation

Add `sas-bases/overlays/startup/disable-startup-transformer.yaml` to the transformers block in your base kustomization.yaml (`$deploy/kustomization.yaml`) file.  Ensure that ordered-startup-transformer.yaml is listed after `sas-bases/overlays/required/transformers.yaml`.

Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/required/transformers.yaml
- sas-bases/overlays/startup/disable-startup-transformer.yaml
```

To apply the change, perform the appropriate steps at [Deploy the Software](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/p127f6y30iimr6n17x2xe9vlt54q.htm).
