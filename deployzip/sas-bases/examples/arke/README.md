---
category: messaging
tocprty: 2
---

# Configuration Settings for Arke

## Overview

Arke is a message broker proxy that sits between all services and RabbitMQ.
This README file describes the settings available for deploying Arke.

## Installation

Based on the following description of the available example files, determine if you
want to use any example file in your deployment. If you do, copy the example
file and place it in your site-config directory.

Each file has information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ MEMORY-LIMIT }}. Replace the
entire variable string, including the braces, with the value you want to use.

After you have edited the file, add a reference to it in the transformers block
of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an
example using the Arke transformers:

```yaml
transformers:
...
- site-config/arke/arke-modify-cpu.yaml
- site-config/arke/arke-modify-memory.yaml
- site-config/arke/arke-modify-hpa-replicas.yaml
```

## Examples

The example files are located at `$deploy/sas-bases/examples/arke`.
The following list contains a description of each example file for Arke settings
and the file names.

- modify the resource allocation for CPU (arke-modify-cpu.yaml)
- modify the resource allocation for RAM (arke-modify-memory.yaml)
- modify the HorizontalPodAutoscaler replicas (arke-modify-hpa-replicas.yaml)
