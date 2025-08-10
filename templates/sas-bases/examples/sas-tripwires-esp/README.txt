---
category: SAS Law Enforcement Intelligence
tocprty: 1
---

# SAS Law Enforcement Intelligence - Tripwires ESP

## Overview

Tripwires ESP provides real-time notifications for the Investigation Content
Pack Tripwires functionality.

The example files provided require SAS Event Stream Processing to be licensed
in addition to SAS Law Enforcement Intelligence.

## Summary of Deployment

Tripwires ESP comprises an ESP project XML model and an ESP server instance.

## Instructions

### Copy the Examples

The directory `$deploy/sas-bases/examples/sas-tripwires-esp` contains the
example project and server definition.

1. Copy `$deploy/sas-bases/examples/sas-tripwires-esp` to
`$deploy/site-config/sas-tripwires-esp`.

2. Add `site-config/sas-tripwires-esp` to the `resources` block of the
base kustomization.yaml (`$deploy/kustomization.yaml`) file.

   Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/sas-tripwires-esp
   ```

### Configuration

1. The `$deploy/site-config/sas-tripwires-esp/tripwires.env` file is used to
configure the ESP server instance. The variables in the file should be updated
to reflect the requirements of your deployment.

   Here is an example:

   ```
   # The IP or hostname of the smtp server used to send notifications
   SMTPHOST=mailhost
   # The tripwire entity configured in SAS Visual Investigator
   ENTITY=tripwire
   # The interval at which to refresh information from PostgreSQL
   PGINTERVAL=60
   # The duration to throttle multiple events into a single notification
   THROTTLE=10
   ```

2. The `$deploy/site-config/sas-tripwires-esp/kustomization.yaml` file contains
transformers to configure TLS, PostgreSQL and RabbitMQ. If the deployment uses
external PostgreSQL or does not use TLS, then additional configuration is
required.