---
category: SAS Business Orchestration Services
tocprty: 2
---

# SAS Business Orchestration Worker Configuration

## Overview

This README file describes the configuration settings for a cloud-native engine that enables users to declare their orchestrations through a set of workloads and flows in YAML format. This version of the product is also referred to as SAS Business Orchestration Worker.

SAS Business Orchestration Services has two versions. The first is the one that has been shipping for some time and uses an engine that is based on Apache Camel. The README for deploying and configuring that version of SAS Business Orchestration Services is located at $deploy/sas-bases/examples/sas-boss/README.md (for Markdown format) or at $deploy/sas-bases/docs/deploying_sas_business_orchestration_services.htm (for HTML format).

## Installation 

### Configure with Initial SAS Viya Platform Deployment

Create a copy of the example template in `$deploy/sas-bases/examples/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml`. Save this copy in `$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml`.

Placeholders are indicated by curly brackets, such as {{ .values.NAMESPACE }}. Find and replace the placeholders with the values you want for your deployment. After all placeholders have been filled in, directly apply your deployment yaml via SAS Viya platform Kustomize or direct kubectl apply commands.

If you are using the SAS Viya platform Kustomize process, add the resource `$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml` to the
resources block of the base kustomization.yaml file.  The use case here is to deploy a SAS Business Orchestration Worker project with SAS Viya platform. Here is an example:

```yaml
resources:
...
- site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml
...
```

### Data in Motion - TLS

The [Deployment Resource](#deployment-resource) sections below describe several TLS configurations for sas-business-orchestration-worker deployments. These configurations must align with SAS Viya security requirements, as specified in SAS Viya Platform Operations guide [Security Requirements](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#n0w1os9ufnn7xwn1an3qbhxjxze9). Here are the specific TLS deployment requirements:

* "No TLS" mode can ignore the Deployment Resources TLS sections.
* "Front-Door TLS" mode terminates TLS at the ingress. Therefore, sas-business-orchestration-worker needs an ingress-specific TLS configuration.
* "Full-Stack TLS" mode needs one-way TLS or two-way mTLS configured in addition to the ingress TLS specific configurations. 

### Deployment Resource

The business-orchestration-worker-deployment.yaml resource has customizable sections.

#### Section - config map

This section provides a ConfigMap example that mounts the project.yaml into pods. The project.yaml describes the orchestration. 

#### Section - image pull secrets

This section provides an image pull secret example that grants access to the container registry images.

The image pull secret can be grepped from the SAS Viya platform Kustomize build command output:

```shell
kustomize build . > site.yaml
grep '.dockerconfigjson:' site.yaml
    .dockerconfigjson: <SECRET>
```

Alternatively, if SAS Viya platform has already been deployed the image pull secret can be queried:

```shell
kubectl -n {{ .values.NAMESPACE }} get secret --field-selector=type=kubernetes.io/dockerconfigjson -o yaml | grep '.dockerconfigjson:'
    .dockerconfigjson: <SECRET>
```

Replace the namespace and image pull secret values in the example.

#### Section - service

This section provides an example that configures high availability routing for sas-business-orchestration-worker pods.

#### Section - deployment

This section provides an example that shows pod configuration and behaviors.

##### Configure the sas-business-orchestration-worker init Container

When using ODE processor, you must create a sas-business-orchestration-worker init container that fetches the required SFM jar files from by pulling a docker image. 

1. Create a docker image that contains the required SFM jar files. Here is a sample Dockerfile.

   ```shell
   FROM ubuntu
    
   # Package updates and install dependencies
   RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
       curl \
       apt-transport-https \
       ca-certificates \
       && rm -rf /var/lib/apt/lists/*
    
   # Install kubectl
   RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
   RUN chmod +x ./kubectl
   RUN mv ./kubectl /usr/local/bin
    
   # Grab SAS Fraud Management JARs (boss-worker-sb ode plugin dependency, used in performance/component/processor-ode.yaml)
   RUN mkdir /sfmlibs
   RUN mkdir /sfmlibs/44
   RUN cd /sfmlibs/44 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/f0rapt44/DEVD/ivy-repo/SAS_content/sas.finance.fraud.transaction/404001.0.0.20161020100850_f0rapt44/sas.finance.fraud.transaction.jar
   RUN cd /sfmlibs/44 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/f0rapt44/DEVD/ivy-repo/SAS_content/sas.finance.fraud.engine/404001.0.0.20161020100936_f0rapt44/sas.finance.fraud.engine.jar
   RUN mkdir /sfmlibs/61
   RUN cd /sfmlibs/61 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/f0rapt61/DEVD/ivy-repo/SAS_content/sas.finance.fraud.transaction/601002.0.0.20220622174613_f0rapt61/sas.finance.fraud.transaction.jar
   RUN cd /sfmlibs/61 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/f0rapt61/DEVD/ivy-repo/SAS_content/sas.finance.fraud.engine/601002.0.0.20220622174651_f0rapt61/sas.finance.fraud.engine.jar
   RUN mkdir /sfmlibs/62
   RUN cd /sfmlibs/62 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/d4rapt62/DEVD/ivy-repo/SAS_content/sas.finance.fraud.transaction/602000.0.0.20231003221024_d4rapt62/sas.finance.fraud.transaction.jar
   RUN cd /sfmlibs/62 && curl -LO http://ivy.fyi.sas.com/Repositories/sds/dev/d4rapt62/DEVD/ivy-repo/SAS_content/sas.finance.fraud.engine/602000.0.0.20231003221203_d4rapt62/sas.finance.fraud.engine.jar
   ```

2. Run the following docker command to create a docker image that is used in the init container.

   ```shell
   docker build -t <image_name>:<tag> <path_to_Dockerfile_directory>
   ```

3. Tag the image and push it to a Docker registry.

   ```
   docker tag <image_name>:<tag> <repository_url>/<image_name>:<tag>
   ```

   Replace <image_name>:<tag> with the name and tag of your Docker image, and <repository_url> with the URL of your Docker repository. For example:

   ```
   docker tag myimage:latest myrepository/myimage:latest
   ```

   Log in to the Docker registry and push the Docker image to the repository.

   ```
   docker login <registry_url>

   docker push <repository_url>/<image_name>:<tag>
   ```

   For example:

   ```
   docker push myrepository/myimage:latest
   ```

4. Edit the `$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml` file. In the Deployment section, uncomment the init container for "fetch-ode-jars", and replace {{ .VALUES.SFM_JAR_IMAGE }} with the URL to the Docker image generated in Step 2. Here is an example:

   ```yaml
   initContainers:
   - name: fetch-ode-jars
       image: myrepository/myimage:latest
       command: ["sh", "-c"]
       args: ["cp -R /sfmlibs/* /tmp/data"]
       imagePullPolicy: Always
       volumeMounts:
       - name: sfmlibs
           mountPath: "/tmp/data"
   ```

##### sas-business-orchestration-worker Container

The sas-business-orchestration-worker container includes categories of environmental properties. The properties include properties for logging, external services (such as Apache Kafka, Redis and RabbitMQ), processing options, and probe options. Optional security-related properties are covered in the Security section.

##### Images

Update the two image values that are contained in the `$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml` file. Revise the value "sas-business-orchestration-worker" to include the registry server, relative path, name, and tag.  The registry relative server and relative path are the same as other SAS Viya platform deployment images. 

The name of the container is 'sas-business-orchestration-worker'. The registry relative path, name, and tag values are found in the sas-components-* configmap in the Viya deployment.

Perform the following commands to determine the appropriate information. When you have the information, add it to the appropriate places in the three files listed above.

```shell
$ # generate site.yaml file
$ kustomize build -o site.yaml 

## get the sas-business-orchestration-worker registry information
$ cat manifests.yaml | grep 'sas-business-orchestration-worker:' | grep -v -e "VERSION" -e 'image'

$ # manually update the sas-business-orchestration-worker-example images using the information gathered below: <container registry>/<container relative path>/sas-business-orchestration-worker:<container tag>

$ # apply site.yaml file
$ kustomize apply -f site.yaml 
``` 
     
Perform the following commands to get the required information from a running SAS Viya platform deployment.
    
```shell
    
# get the registry server, kubectl needs to point to the SAS Viya platform deployment namespace, and replace {{ .values.NAMESPACE }} with the namespace value 
$ kubectl -n {{ .values.NAMESPACE }} get deployment sas-readiness -o yaml | grep -e "image:.*sas-readiness" | sed -e 's/image: //g' -e 's/\/.*//g'  -e 's/^[ \t]*//'
    <container registry> 
    
# get registry relative path and tag, kubectl needs to point to the SAS Viya platform deployment namespace, and replace {{ .values.NAMESPACE }} with the namespace value
$ CONFIGMAP="$(kubectl -n {{ .values.NAMESPACE }} get cm | grep sas-components | tr -s '' | cut -d ' ' -f1)"
$ kubectl -n {{ .values.NAMESPACE }} get cm "$CONFIGMAP" -o yaml | grep 'sas-business-orchestration-worker:' | grep -v "VERSION"
    SAS_COMPONENT_RELPATH_sas-business-orchestration-worker: <container relative path>/sas-business-orchestration-worker
    SAS_COMPONENT_TAG_sas-business-orchestration-worker: <container tag>
```

##### Logging Properties

The SAS_LOG_LEVEL environment variable specifies the minimum severity level for emitting logs. To control the verbosity of the log output, the level can be set to TRACE, DEBUG, INFO, WARN, or ERROR.

The SAS_LOG_FORMAT environment variable specifies the format of the emitted logs. The format can be set to json or plain.

The SAS_LOG_LOCALE environment variable determines which locale messages should be included in the output. The default value is "en".

##### External Services Properties

External services that are used by a workload require defined properties that are specific to the technology in use. See the comments in the `$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml` resource file for specific examples.

##### Processing Options

Project yaml files can include multiple workloads that scale independently.  This means that a pod can run only one workload.  Use the WORKLOAD_ENABLED_BY_INDEX environment variable to specify which workload to execute.  If the property is missing the index 0, meaning the first, workload is executed.

##### Readiness Probe

The sas-business-orchestration-worker container uses a readiness probe, which allows Kubernetes to determine when a pod is ready to receive data. The initialDelaySeconds field specifies how many seconds Kubernetes should wait before performing the initial probe. The periodSeconds field specifies how many seconds Kubernetes should wait between probes.

For more information about readiness probes, see https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/.

##### sas-business-orchestration-worker-sb Container

The sas-business-orchestration-worker-sb container includes a Spring Boot application sidecar.  Some orchestration components need to leverage Java libraries to connect to other Java services. This includes SAS Fraud Management engines or when parsing certain SWIFT and ISO standardized message formats is required.  See comments in the resource file for specifics.  This sidecar can be removed or commented out if those JAVA specific implemented features are not needed by the project orchestration workload being executed. 

#### Section - horizontal pod autoscaler

This section provides an example of a Horizontal Pod Autoscaler.

#### Section - OpenShift route

This section provides an example of an ingress in an OpenShift environment. If you use this ingress, comment out other ingresses in the file.

#### Section - ingress

This section provides an example of an ingress in an OpenShift environment. If you use this ingress, comment out other ingresses in the file.

#### Section - ingress tls

This section provides an example of NGINX for HTTP traffic using TLS. If you use this ingress, comment out other ingresses in the file.

#### Section - ingress tls secret for tls certs and keys

This section provides an example of a secret that holds TLS certificates and keys.

#### Section - secret for a ca cert and key to make a request to sign a client cert for two-way tls

This section provides an example of a secret that holds the certificate authority certificate and key that are used for two-way TLS (mTLS).

#### Section - create separate cert and key for external service such as Redis, Apache Kafka, Rabbitmq, etc.

This section provides an example of a secret that holds the certificate authority certificate and key that are used for two-way TLS (mTLS) with external services.

Duplicate this section as needed if multiple external services are used by the orchestration project.

### Services and Ingresses

These resources do not require much customization. They require the SUFFIX to be filled in, and the NAMESPACE to be specified, as indicated in the template. The ingresses additionally require the host property be specified. 

The services are ClusterIP services, accessed externally via the ingress resources. The ports are already filled in and line up with the prefilled ingress ports. 

The ingresses include the host, and rules for directing requests. For the sas-business-orchestration-worker ingress, anything sent with /sas-business-orchestration-worker as the path prefix will use this ingress. The service referenced above uses the ingress in most cases. You might not need ingress if all traffic is within the Kubernetes cluster or if the containers are hosted by another cloud technology.

#### OpenShift

If you are deploying your SAS Business Orchestration Worker on OpenShift, you will not be able to use the Ingress resource. In this case, replace your ingress resource with an [OpenShift Route](#section---openshift-route).

### Security 

#### TLS Secrets 

There are optional, commented out sections that may be used to create the secrets containing TLS certificates and keys. The data must be base64 encoded and included in these definitions. These secrets could optionally be created manually via kubectl or kustomize secrets generators. If the secrets are created via some other method, the secret names must still match those referenced in the volumes and ingress definitions. 

#### Secure Ingress Definition 

To add TLS to your ingress, some annotations and spec fields must be added. These will require certificates either included in this template, or created and supplied previously. The template includes a TLS ingress that is commented out, but the below examples break down what is different in this ingress. 

To secure your ingress, the following annotations can be used to add one-way TLS, two-way TLS (mTLS), or both.

```yaml
annotations:
    # Used to enable TLS
    nginx.ingress.kubernetes.io/auth-tls-secret: {{ .values.NAMESPACE }}/business-orchestration-worker-ingress-tls-ca-config-{{ .VALUES.SUFFIX }}   
    # used to enable mTLS
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"    
```

For one-way TLS, fill in the tls field under the spec field. This also includes a secretName, which includes your TLS certificate.

```yaml
tls:
    - hosts:
        - {{ .values.PREFIX }}.{{ INGRESS-TYPE }}.{{ HOST }}
    secretName: business-orchestration-worker-ingress-tls-config-{{ .VALUES.SUFFIX }}
```

See the resource comments for more specific details.

#### Volumes and Volume Mounts

Depending on the security configuration, mounting additional trusted certificates in your containers may be necessary. The areas to add these are tagged with SECURITY, and can be uncommented as necessary. The secret names must match whatever secrets have been configured for these certificates.

There are three volume examples created from secrets containing TLS certificates. One volume example is for sas-business-orchestration-worker certificates, one volume is for an external service certificate. These are defined for each container in the Deployment spec. 

After being created, these volumes may be mounted in the sas-business-orchestration-worker container. As defined in the template, the business-orchestration-worker certificates are mounted in /var/run/security, the external service certificates are mounted in /var/run/security/<some external service> which can be duplicated if multiple external services are used by the workload.

#### Inline Comments of the Deployment Resource

Read through all the inline comments of deployment resource.  There is considerable overlap with these instructions here.  However, there are more specifics and a higher degree of detail in the actual deployment resource template.

## Additional Resources

[Deploy the software](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).

### Configure after the Initial Deployment

Alternatively, SAS Business Orchestration Worker can be installed separately from the SAS Viya platform. Complete steps above, except "Deploy the Software" in the "Additional Resources" section. The use case here is to deploy a SAS Business Orchestration Worker project in a Kubernetes namespace that is not a SAS Viya platform deployment.  Instead, perform the following command:

```sh
kubectl apply -f "$deploy/site-config/sas-business-orchestration-worker/business-orchestration-worker-deployment.yaml"
```
