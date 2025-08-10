---
category: OpenSearch
tocprty: 70
---

# OpenSearch Security Audit Logs

## Overview 

Security audit logs track a range of OpenSearch cluster events. The OpenSearch audit logs can provide beneficial information for compliance purposes or assist in the aftermath of a security breach.

The audit logs are written to audit indices in the OpenSearch cluster. Audit indices can build up over time and use valuable resources. By default, an Index State Management (ISM) policy named 'viya_delete_old_security_audit_logs' is applied by the operator which deletes security audit log indices after seven days with an ISM priority of 50. OpenSearch enables ISM history logs, which are also stored to new indices. By default, ISM history retention is seven days. 

The ISM policy can be disabled or configured to retain OpenSearch audit log indices for a specified length of time. 

If you have already manually created an ISM policy for OpenSearch audit logs, the policy with the higher priority value will take precedence. 

## Configure the viya_delete_old_security_audit_logs ISM policy

### Configurable Parameters

| Configurable Parameter  |  Description |  Default |
|---|---|---|
| enableIndexCleanup  | Apply the ISM policy to remove OpenSearch security audit log indices after the length of time specified in *indexRetentionPeriod*. If you want to retain the indices indefinitely, set to "false". <br> **Note**: In order to prevent performance issues, SAS recommends that you change the *indexRetentionPeriod* to a higher period rather than disabling index cleanup. |  true |
| indexRetentionPeriod | Period of time an OpenSearch audit log is retained for if the ISM policy is applied. Supported units are *d* (days), *h* (hours), *m* (minutes), *s* (seconds), *ms* (milliseconds), and *micros* (microseconds).  |  7d |
| ismPriority | A priority to disambiguate when multiple policies match an index name. OpenSearch takes the settings from the template with the highest priority and applies it to the index.  | 50  | 
| enableISMPolicyHistory | Additional indices are also created to log ISM history data. Specifies whether ISM audit history is enabled or not.  |  true | 
| ismLogRetentionPeriod | Period of time ISM history indices are kept if they are enabled. Supported units are *d* (days), *h* (hours), *m* (minutes), *s* (seconds), *ms* (milliseconds), and *micros* (microseconds).   | 7d  | 

### Configuration Instructions

1. Copy the audit log retention transformer from `$deploy/sas-bases/examples/configure-elasticsearch/internal/security-audit-logs/audit-log-retention-transformer.yaml` into the `$deploy/site-config` directory. Adjust the value for each parameter listed above that you would like to change. 

2. Add the audit-log-retention-transformer.yaml file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:
   
   ```yaml
   transformers:
   ...
   - site-config/audit-log-retention-transformer.yaml
   ```

**Note**: The ISM policy values can be adjusted and reconfigured after the initial deployment.

## Disable Security Audit Logs 

OpenSearch security audit logging can be disabled completely.

1. Copy the disable security audit transformer from `$deploy/sas-bases/examples/configure-elasticsearch/internal/security-audit-logs/disable-security-audit-transformer.yaml` into the `$deploy/site-config` directory.

2. Add the disable-security-audit-transformer.yaml file to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:
   
   ```yaml
   transformers:
   ...
   - site-config/disable-security-audit-transformer.yaml
   ```

## Additional Resources 

For more information on OpenSearch audit logs or Index State Management (ISM) policies, see the [OpenSearch Documentation](https://opensearch.org/docs/latest/).