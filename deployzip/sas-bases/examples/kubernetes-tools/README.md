---
category: kubernetesTools
tocprty: 1
---

# Using Kubernetes Tools from the sas-orchestration Image

## Overview

The sas-orchestration image includes several tools that help
deploy and manage the software. It includes a `lifecycle` command
that can run various lifecycle operations as well as the recommended
versions of both `kustomize` and `kubectl`. These latter tools may
be used with the `--entrypoint` option that is available on both Docker
and Podman container runtime CLIs.

Note: The examples use Docker, but the Podman container engine can also
be used.

Note: All examples below are auto-generated based on your order.

## Prerequisites

To run the sas-orchestration image, Docker must be installed.
Pull the `sas-orchestration` image:

```
docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.128.2-20241002.1727879835425
```

Replace 'cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.128.2-20241002.1727879835425' with a local tag for ease of use in the examples that will follow:

```
docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.128.2-20241002.1727879835425 sas-orchestration
```

## Examples

The examples that follow assume:

* `$deploy` refers to the directory that will contain the deployment assets.
* The deployment assets for the order have been downloaded to `$deploy`. To download the deployment assets
  for an order from `my.sas.com`, go to [http://my.sas.com](http://my.sas.com), log in, find your order
  and select `Download Deployment Assets`. Extract the downloaded tarball to `$deploy`.
* A kubeconfig file called `config` exists in `/home/user/kubernetes`. The kubeconfig file defines the cluster
  the lifecycle operations will connect to.
* The orchestration image has been pulled and has the local tag 'sas-orchestration'
* The `$deploy` directory is the current working directory.
  `cd` to $deploy and use `$(pwd)` to mount the current directory into the container.
* The software has been deployed into the namespace '{{ NAME-OF-NAMESPACE }}'

### lifecycle

The `lifecycle` command executes deployment-wide operations over the assets deployed from an order.
See the README file at `$deploy/sas-bases/examples/kubernetes-tools/README.md` (for Markdown)
or `$deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm` (for HTML) for
lifecycle operation documentation.

Docker uses the following options:

* `-v` to mount the directories
* `-w` to define the working directory
* `-e` to define the needed environment variables

### Additional `Lifecycle` command documentation
* `$deploy/sas-bases/examples/kubernetes-tools/lifecycle-operations/deploy/README.md`
* `$deploy/sas-bases/examples/kubernetes-tools/lifecycle-operations/scale-to-zero/README.md`
* `$deploy/sas-bases/examples/kubernetes-tools/lifecycle-operations/scale-up/README.md`

#### lifecycle list

The `list` sub-command displays the available operations of a deployment

##### `lifecycle list` example

```
cd $deploy
docker run --rm \
  -v "$(pwd):/cwd" \
  -v /home/user/kubernetes:/kubernetes \
  -e "KUBECONFIG=/kubernetes/config" \
  -w /cwd \
  sas-orchestration \
  lifecycle list --namespace {{ NAME-OF-NAMESPACE }}
```

#### lifecycle run

The `run` sub-command runs a given operation.
Arguments before `--` indicate the operation to run and how lifecycle should locate the operation's
definition. Arguments after `--` apply to the operation itself, and may vary between operations.

##### `lifecycle run` example

```
cd $deploy
docker run --rm \
  -v "$(pwd):/cwd" \
  -v /home/user/kubernetes:/kubernetes \
  -e "KUBECONFIG=/kubernetes/config" \
  sas-orchestration \
  lifecycle run \
    --operation assess \
    --deployment-dir /cwd \
    -- \
    --manifest /cwd/site.yaml \
    --namespace {{ NAME-OF-NAMESPACE }}
```

As indicated in the example, the `run` sub-command needs an operation (`--operation`) and the location of
your assets (--deployment-dir). The `assess` lifecycle operation needs a manifest (`--manifest`) and the
Kubernetes namespace to assess, (`--namespace`). To connect and assess the Kubernetes cluster,
the KUBECONFIG environment variable is set on the container; (`-e`).

To see all possible `assess` operation arguments, run `assess` with the `--help` flag:
```
docker run --rm \
      -v "$(pwd):/cwd" \
      sas-orchestration \
      lifecycle run \
          --operation assess \
          --deployment-dir /cwd/sas-bases \
          -- \
          --help
```

### kustomize

The example assumes that the $deploy directory contains the kustomization.yaml
and supporting files. Note that the `kustomize` call here is a simple example.
Refer to the deployment documentation for full usage details.

```
cd $deploy
docker run --rm \
  -v "$(pwd):/cwd" \
  -w /cwd \
  --entrypoint kustomize \
  sas-orchestration \
  build . > site.yaml
```

### kubectl

This example assumes a `site.yaml` manifest file exists in `$deploy`.
See the [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
for instructions on how to create the site.yaml manifest.

**Note** The `kubectl` call here is a simple example.
Refer to the deployment documentation for full usage details.

```
cd $deploy
docker run --rm \
  -v "$(pwd):/cwd" \
  -v /home/user/kubernetes:/kubernetes \
  -w /cwd \
  --entrypoint kubectl \
  sas-orchestration \
  --kubeconfig=/kubernetes/kubeconfig apply -f site.yaml
```

## Additional Resources
* https://docs.docker.com/get-docker/
* https://kustomize.io/
* https://kubectl.docs.kubernetes.io/