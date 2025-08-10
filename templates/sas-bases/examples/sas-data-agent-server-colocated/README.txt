---
category: SAS Cloud Data Exchange
tocprty: 1
---

# Configure a Co-located SAS Data Agent

## Overview

The directory `$deploy/sas-bases/examples/sas-data-agent-server-colocated` contains files to customize your SAS Viya platform deployment for 
a co-located SAS Data Agent. This README describes the steps necessary 
to make these files available to your SAS Viya platform deployment. It also describes 
how to set required environment variables to point to these files. 

**Note:** If you make changes to these files after the initial deployment,
you must restart the co-located SAS Data Agent.

## Prerequisites

Before you start the deployment you should determine the OAUTH secret that will be used by co-located SAS Data Agent and any remote SAS Data Agents.

You should also create a subdirectory within `$deploy/site-config` to store your co-located SAS Data Agent configurations. This README uses a user-created subdirectory called 
`$deploy/site-config/sas-data-agent-server-colocated`. For more information, refer to the ["Directory Structure" section of the "Pre-installation
Tasks" Deployment Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p1goxvcgpb7jxhn1n85ki73mdxc8.htm&locale=en).

## Installation

The base kustomization.yaml file (`$deploy/kustomization.yaml`) provides configuration properties for the customization process.
The co-located SAS Data Agent requires specific customizations in order to communicate with remote SAS Data Agents and configure server options. Copy the example `sas-data-agent-server-colocated-config.properties` and `sas-data-agent-server-colocated-secret.properties` files from `$deploy/sas-bases/examples/sas-data-agent-server-colocated` to `$deploy/site-config/sas-data-agent-server-colocated`.

## Configuration

**Note:** The default values listed in the descriptions that follow should be suitable for most users.

### Configure the OAuth Secret

#### SAS_DA_OAUTH_SECRET

The sas-data-agent-server-colocated-secret.properties file contains configuration properties for the OAUTH secret. The OAUTH secret value is required and must be specified in order to communicate with a remote SAS Data Agent. There is no default value for the OAUTH secret.

**Note:** The following example is for illustration only and should not be used.

Enter a string value for the OAUTH secret that will be shared with the remote SAS Data Agent. Here is an example:

```bash
SAS_DA_OAUTH_SECRET=MyS3cr3t
```

### Configure Logging

The `sas-data-agent-server-colocated-config.properties` file contains configuration properties for logging.

#### SAS_DA_DEBUG_LOGTYPE

Enter a string value to set the level of additional logging.

   * `SAS_DA_DEBUG_LOGTYPE=TRACEALL` enables trace level for all log items.
   * `SAS_DA_DEBUG_LOGTYPE=TRACEAPI` enables trace level for api calls.
   * `SAS_DA_DEBUG_LOGTYPE=TRACE` enables trace level for most log items.
   * `SAS_DA_DEBUG_LOGTYPE=PERFORMANCE` enables tracce/debug level items for performance debugging.
   * `SAS_DA_DEBUG_LOGTYPE=PREFETCH` enables trace/debug level items for prefetch debugging.
   * `SAS_DA_DEBUG_LOGTYPE=None` disables additional tracing.

If no value is specified, the default of None is used.

Here is an example:

```bash
SAS_DA_DEBUG_LOGTYPE=None
```

### Configure Filesystem Access

The `sas-data-agent-server-colocated-config.properties` file contains configuration properties that restrict drivers from accessing the container filesystem. By default, drivers can only access the directory tree `/data` which must be mounted on the co-located SAS Data Agent container.

#### SAS_DA_RESTRICT_CONTENT_ROOT

When set to TRUE, the file access drivers can only access the directory structure specified by SAS_DA_CONTENT_ROOT.

When set to FALSE, the file access drivers can access any directories accessible from within the co-located SAS Data Agent container.

If no value is specified, the default of TRUE is used.

```bash
SAS_DA_RESTRICT_CONTENT_ROOT=None
```

#### SAS_DA_CONTENT_ROOT

Enter a string value to specify the directory tree that file access drivers are allowed to access. This value is ignored if SAS_DA_RESTRICT_CONTENT_ROOT=FALSE. If no value is specified, the default of `/data` is used.

Here is an example:

```bash
SAS_DA_CONTENT_ROOT=/accounting/data
```

### Configure Server Timeout Options

The `sas-data-agent-server-colocated-config.properties` file contains configuration properties that control how the server treats client sessions that are unused for long periods of time.  By default the server will try to gracefully shut down sessions that have not been used for one hour.

#### SAS_DA_SESSION_CLEANUP

Use this variable to specify how often the server will check for idle connections. This variable has a default of 60 seconds (1 minute).

Here is an example of how to check for idle client sessions every 5 minutes:

```bash
SAS_DA_SESSION_CLEANUP=300
```

#### SAS_DA_DEFAULT_SESSION_TIMEOUT

Use this variable to specify how long to wait before an unused client session is considered idle, and thus eligible to be killed. This value is only used when the client does not specify a value for SESSION_TIMEOUT when connecting.  This variable has a default of 3600 seconds (1 hour).

Here is an example of how to default to a 20 minute wait before an unused client session is considered idle:

```bash
SAS_DA_DEFAULT_SESSION_TIMEOUT=1200
```

#### SAS_DA_MAX_SESSION_TIMEOUT

Use this variable to specify the maximum time before an unused client session is considered idle, and thus eligible to be killed. This value applies even when SESSION_TIMEOUT or SAS_DA_DEFAULT_SESSION_TIMEOUT are set to longer times.  This variable has a default of 0 seconds (meaning no maximum wait time).

Here is an example of how to set the maximum wait time to 18000 seconds (5 hours) before an unused client session is considered idle:

```bash
SAS_DA_MAX_SESSION_TIMEOUT=18000
```

#### SAS_DA_MAX_OBJECT_TIMEOUT

Use this variable to specify the maximum time the server will wait for a database operation to complete when killing idle client sessions. This variable has a default of 0 seconds (meaning no maximum wait time).

Here is an example of how to set the maximum object timeout to 300 seconds (5 minutes) when killing idle client sessions:

```bash
SAS_DA_MAX_SESSION_TIMEOUT=300
```

#### SAS_DA_WORKER_TIMEOUT

Use this variable to specify the maximum time a worker pod will remain when there are no active client sessions. This variable has a default of 0 seconds (meaning the worker pod will remain active and available to service future requests).
If a worker pod exits a new client request will automatically start another worker pod to service it, but this might result in a slight initialization delay.

Here is an example of how to set the worker pod timeout to 3600 seconds (1 hour):

```bash
SAS_DA_WORKER_TIMEOUT=3600
```

#### SAS_DA_PRELAUNCH_WORKERS 

Use this variable to specify whether a worker pod should be launched before the first client request is received. This variable has a default of TRUE if SAS_DA_OAUTH_SECRET has been specified, otherwise the default is FALSE.
If a client request is received a worker pod will be automatically started if it is not already running, but this might result in a slight initialization delay.

Here is an example of how to disable worker pod prelaunch:

```bash
SAS_DA_PRELAUNCH_WORKERS=FALSE
```

### Configure Access to Java, Hadoop, and Spark

The `sas-data-agent-server-colocated-config.properties` file contains configuration properties for
Java, SAS/ACCESS Interface to Spark and SAS/ACCESS to Hadoop.

#### Configure SAS_DA_HADOOP_JAR_PATH and SAS_DA_HADOOP_CONFIG_PATH

If your deployment includes SAS/ACCESS Interface to Spark, you must make your Hadoop JARs and configuration file available on a PersistentVolume or mounted storage.
Set the options SAS_DA_HADOOP_JAR_PATH and SAS_DA_HADOOP_CONFIG_PATH to point to this location.
See the SAS/ACCESS Interface to Spark documentation at `$deploy/sas-bases/examples/data-access/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuring_sasaccess_and_data_connectors_for_sas_viya_4.htm` (for HTML format) for more details. These variables have no default values.

Here are some examples:

```bash
SAS_DA_HADOOP_CONFIG_PATH=/clients/hadoopconfig/prod
SAS_DA_HADOOP_JAR_PATH=/clients/jdbc/spark/2.6.22
```

#### SAS_DA_JAVA_HOME

Use this variable to specify an alternate JAVA_HOME for use by the co-located SAS Data Agent. This variable has no default value.

Here is an example:

```bash
SAS_DA_JAVA_HOME=/java/lib/jvm/jre
```

### Revise the Base kustomization.yaml File

Add these entries to the base kustomization.yaml file (`$deploy/kustomization.yaml`) in order to include 
the modified `sas-data-agent-server-colocated-config.properties` and `sas-data-agent-server-colocated-secret.properties` files.

```yaml
configMapGenerator:
...
- name: sas-data-agent-server-colocated-config
  behavior: merge
  envs:
  - site-config/sas-data-agent-server-colocated/sas-data-agent-server-colocated-config.properties
...
secretGenerator:
...
- name: sas-data-agent-server-colocated-secrets
  behavior: merge
  envs:
  - site-config/sas-data-agent-server-colocated/sas-data-agent-server-colocated-secret.properties
```

## Using  SAS/ACCESS with a Co-located SAS Data Agent

For more information about configuring SAS/ACCESS, see the README file located at `$deploy/sas-bases/examples/data-access/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuring_sasaccess_and_data_connectors_for_sas_viya_4.htm` (for HTML format).