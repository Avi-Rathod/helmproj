---
category: kubernetesTools
tocprty: 4
---

# Lifecycle Operation: schedule-start-stop

The start-all and stop-all Cronjobs can be run on a schedule using the example file in `$deploy/sas-bases/examples/kubernetes-tools/lifecycle-operations/schedule-start-stop`. Copy the 'schedule-start-stop.yaml' into the site-config directory and revise it to insert a schedule for start-all and another schedule for stop-all. Add a reference to the file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
site-config/kubernetes-tools/lifecycle-operations/schedule-start-stop/schedule-start-stop.yaml
```

**Note:** This file should be included *after* the line

```yaml
- sas-bases/overlays/required/transformers.yaml
```
