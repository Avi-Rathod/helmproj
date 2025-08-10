---
category: security
tocprty: 10
---

# Configuring Ingress for Cross-Site Cookies

## Overview

When you configure the SAS Viya platform to enable cross-site cookies via the `sas.commons.web.security.cookies.sameSite` configuration property, you must also update the ingress configuration so that cookies managed by the ingress controller have the same settings. Ingress or Route annotations for same-site cookie settings are applied by adding the appropriate transformer component to your kustomization.yaml.

## Installation

Add the `samesite-none` transformer component to the components block of the base kustomization.yaml in the $deploy directory.

Example:
```yaml
components:
...
- sas-bases/components/security/web/samesite-none
```
