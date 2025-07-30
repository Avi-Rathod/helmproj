---
category: updateChecker
tocprty: 1
---

# Update Checker Cron Job

The Update Checker cron job builds a report comparing the currently
deployed release with available releases in the upstream repository.
The report is written to the stdout of the launched job pod and
indicates when new content related to the deployment is available.

This example includes the following kustomize transform that
defines proxy environment variables for the report when it
is running behind a proxy server:

```
$deploy/sas-bases/examples/update-checker/proxy-transformer.yaml
```

For information about using the Update Checker, see [View the Update Checker Report](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm&locale=en#p09ingu4hyzgaun14w4b80koghr9).

**Note:** Ensure that the version indicated by the version selector for the
document matches the version of your SAS Viya platform software.
