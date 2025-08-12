---
category: sasProgrammingEnvironment
tocprty: 7
---

# Adding Classes to Java Security Policy File Used by SAS Programming Environment

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for managing the Java security policy file that is generated for
the SAS Programming Environment.

By default the SAS Programming Environment generates a Java security policy
file to prevent SAS programmers from executing Java code directly from SAS code
that would be deemed unsafe by the administrator. This README describes the
customizations that can be made by the Kubernetes administrator for managing
the Java security policy file that is generated for the SAS Programming
Environment.

If a class is determined acceptable by the Kubernetes administrator, the
following steps allow that class to be added.

## Installation

The default behavior generates a Java security policy file similar to

```text
grant {
permission java.lang.RuntimePermission "*";
permission java.io.FilePermission "<<ALL FILES>>", "read, write, delete";
permission java.util.PropertyPermission "*", "read, write";
permission java.net.SocketPermission "*", "connect,accept,listen";
permission java.io.FilePermission "com.sas.analytics.datamining.servertier.SASRScriptExec", "exec";
permission java.io.FilePermission "com.sas.analytics.datamining.servertier.SASPythonExec", "exec";
};
```

The Java security policy file can be modified by using the
add-allowed-java-class.yaml file.

1. Copy the
`$deploy/sas-bases/examples/sas-programming-environment/java-security-policy/add-allowed-java-class.yaml`
file to the site-config directory.

2. To add classes with an `exec` permission to this generated policy file,
replace the following in the copied file.

   - Replace {{ NAME }} with an unique name for the class.   This is for
   internal identification.
   - Replace {{ CLASS-NAME}} with the Java class name that is to be allowed.

   For example,

   ```yaml
   ...
   patch: |-
     - op: add
       path: /data/SAS_JAVA_POLICY_ALLOW_TESTCLASS
       value: "my.org.test.testclass"
   ...
   ```

3. After you edit the file, add a reference to it in the transformers block of
the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example assuming the file has been saved
   to `$deploy/site-config/sas-programming-environment/java-security-policy`:

   ```yaml
   transformers:
   ...
   - /site-config/sas-programming-environment/java-security-policy/add-allowed-java-class.yaml
   ...
   ```

## Additional Resources

For more information about deployment and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).