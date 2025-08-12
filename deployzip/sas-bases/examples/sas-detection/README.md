---
category: SAS Detection Architecture
tocprty: 1
---

# SAS Detection Engine Configuration

## Overview

This README file describes the configuration settings available for deploying and running SAS Detection Engine. The sections of this README correspond to sections of the full example template, detection-engine-deployment.yaml. In addition to the full template, examples of how to complete each section are also available in `/$deploy/sas-bases/examples/sas-detection/`.

## Installation 

Create a copy of the example template in `/$deploy/sas-bases/examples/sas-detection/detection-engine-deployment.yaml`. Save this copy in `/$deploy/site-config/sas-detection/detection-engine-deployment.yaml`.

Placeholders are indicated by curly brackets, such as {{ DECISION }}. Find and replace the placeholders with the values you want for your deployment. After all placeholders have been filled in, directly apply your deployment yaml via kubectl apply, indicating the file you've just filled in.

```sh
kubectl apply -f detection-engine-deployment.yaml
```

## Examples

The example files are located at `/$deploy/sas-bases/examples/sas-detection/`. Each item in the list includes a description of the example and the example file name.

- Full template including all required pieces for the Detection Engine (detection-engine-deployment.yaml)
- Minimal example of the configurations of each container (container-configuration.yaml)
- Example of each container configuration with TLS enabled (container-configuration-secure.yaml)
- Service and Ingress configuration example, without TLS enabled (ingress-setup-insecure.yaml)
- Service and Ingress configuration, with TLS enabled (ingress-setup-secure.yaml)
- Openshift Route as an alternative to using an Ingress if you are deploying in Openshift (openshift-route.yaml)
- Roles and Rolebinding example, required for metrics reporting and autoupdating, as described below (roles-and-rolebinding.yaml)
- Selfsigned certificate generation using cert-manager (selfsigned-certificates.yaml)

### Deployment Resource Section

This is the most customizeable section of the template. Each container has various environmental options that can be set. 

#### sas-sda-scr container

The SAS Container Runtime (SCR) container requires an image to be specified. This will be available in your configured Docker registry. This is where the output from your design time work using the SAS Viya platform will be. 

```yaml
containers:
- name: sas-sda-scr
    # Image from your docker registry
    image: {{ DECISION }}
```

Other than the image, the only required properties for the sas-sda-scr container are SAS_REDIS_HOST and SAS_REDIS_PORT. The other properties are optional security properties covered in detail in the security section. See the container-configuration.yaml file for the minimal required configuration.

#### sas-detection container

The sas-detection container includes a few categories of environmental properties: logging properties, Kafka properties, Redis properties, and processing options. Optional security-related properties are covered further in the security section. See the container-configuration.yaml file for the minimal required configuration.

##### Logging Properties

SAS_LOG_LEVEL can be DEBUG, INFO, WARN, or ERROR. The value determines the verbosity of the log output. WARN or ERROR should be used where performance is important.

SAS_LOG_LOCALE determines which locale messages should be included in the output, where the default is "en".

##### Kafka Properties

There is a property for the bootstrap server to connect, a few properties to indicate the topics sas-detection will use to read/write, and a boolean determining whether reading from Kafka is enabled. 

SAS_DETECTION_KAFKA_SERVER is the Kafka bootstrap server.

SAS_DETECTION_KAFKA_TDR_TOPIC is the the transaction detection repository (output) topic.

SAS_DETECTION_KAFKA_REJECTTOPIC is the reject topic for when errors occur.

SAS_DETECTION_KAFKA_TOPIC is the input message topic.

SAS_DETECTION_KAFKA_CONSUMER_ENABLED determines whether sas-detection will consume messages from the SAS_DETECTION_KAFKA_TOPIC.

##### Redis Properties

SAS_DETECTION_REDIS_HOST is the Redis host and SAS_DETECTION_REDIS_PORT is the port used to connect to Redis.

SAS_DETECTION_REDIS_POOL_SIZE is the size of the connection pool for the go-redis client. If not specified, this defaults to 10.

##### Processing Options

For metrics gathering and reporting to work correctly, SAS_DETECTION_DEPLOYMENT_NAME must match your deployment name and SAS_DETECTION_PROCESSING_DISABLEMETRICS must be set to "false".

SAS_DETECTION_PROCESSING_SLA determines the threshold in milliseconds after which a transaction should fail with an SLA error.

SAS_DETECTION_PROCESSING_SETVERBOSE is an integer between 1 and 13, inclusive, which determines the logging level within the sas-sda-scr container. 

SAS_DETECTION_PROCESSING_OUTPUT_FILTER allows the output REST response to be filtered. It is a comma separated list of variable sets or variables in your message. message.sas.system,message.request,message.sas.decision, for example.

SAS_DETECTION_KAFKA_BYPASS disables Kafka reads and writes if set to "true".

SAS_DETECTION_WATCHER_INTERVAL_SEC is the interval in seconds at which the watcher will check your docker registry for an update to the image in your sas-sda-scr container. 

### Services and Ingresses

These resources don't need much customization. They require the SUFFIX to be filled in, and the NAMESPACE to be specified, as indicated in the template. The ingresses additionally require the host property be specified. There is a service and ingress for each of the containers defined in the deployment.

The services are ClusterIP services, accessed externally via the ingress resources. The ports are already filled in and line up with the prefilled ingress ports. 

The ingresses include the host, and rules for directing requests. For the sas-detection ingress, anything sent with /detection as the path prefix will use this ingress. The services above are referenced in these ingresses. 

See the ingress-setup-insecure.yaml file for an example.

#### Openshift

If you are deploying your SAS Detection Engine on Openshift, you will not be able to use the Ingress resource. In this case, replace your ingress resource with an Openshift Route.

See the openshift-route.yaml file for an example.

### Roles and RoleBindings

These only require that the NAMESPACE be specified.

The reader role allows the pods in the specified namespace to retrieve info on deployments and pods used to report metrics for all replicas. The scaler role allows the pods to scale themselves up or down, which is necessary for them to restart themselves upon seeing an update to a decision image. The secretReader role allows the pods to access Kubernetes secrets, in order to get the authorization information required to interact with the tag registry.

The RoleBinding resources add these roles to the service account in your NAMESPACE, in order to attach and enable these Roles. 

See the roles-and-rolebinding.yaml file for an example.

### Readiness Probe

The sas-detection container uses a readiness probe, which allowes Kubernetes to determine when that pod is ready to receive transactions. The initialDelaySeconds field specifies how many seconds Kubernetes should wait before performing the initial probe. The periodSeconds field specifies how many seconds Kubernetes should wait between probes.

More information on readiness probes is available here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

### Security 

#### TLS Secrets 

There are optional, commented out sections that may be used to create the secrets containing TLS certificates and keys. The data must be base64 encoded and included in these definitions. These secrets could optionally be created manually via kubectl, or managed via cert-manager. If the secrets are created via some other method, the secret names must still match those referenced in the volumes and ingress definitions. 

An alternative is using the selfsigned-certificates.yaml example file. Placeholders in this file are indicated by curly brackets, such as {{ DNS_NAME }}. Find and replace the placeholders with the values you want for your certificates. This file is optional and may be edited as needed to fit your purposes. As with the detection-engine deployment file, you create these resources directly using kubectl apply. This file must be applied once, and it will generate secrets containing your certificates and keys. 

#### Secure Ingress Definition 

To add TLS to your ingress, some annotations and spec fields must be added. These will require certificates either included in this template, or created and supplied previously. The template includes a TLS ingress that is commented out, but the below examples break down what is different in this ingress. 

To secure your ingress, the following annotations can be used to add one-way TLS, mutual TLS, or both.

```yaml
annotations:
    # Used to enable TLS
    nginx.ingress.kubernetes.io/auth-tls-secret: {{ NAMESPACE }}/detection-ingress-tls-ca-config-{{ ORGANIZATION }}   
    # used to enable mTLS
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"    
```

For one-way TLS, fill in the tls field under the spec field. This also includes a secretName, which includes your TLS certificate.

```yaml
tls:
    - hosts:
        - {{ ORGANIZATION }}.{{ INGRESS-TYPE }}.{{ HOST }}
    secretName: detection-ingress-tls-config-{{ ORGANIZATION }}
```

See the ingress-setup-secure.yaml file for an example of where to add these fields to your deployment yaml.

#### Volumes and Volume Mounts

Depending on the security configuration, mounting additional trusted certificates in your containers may be necessary. The areas to add these are tagged with SECURITY, and can be uncommented as necessary. The secret names must match whatever secrets have been configured for these certificates.

There are three volumes created from secrets containing TLS certificates. One volume is for sas-detection certificates, one volume is for Redis certificates, and one volume is for Kafka certificates. These are defined for each container in the Deployment spec. 

After being created, these volumes may be mounted in the sas-sda-scr and sas-detection containers. As defined in the template, the detection certificates are mounted in /security, the redis certificates are mounted in /security/redis, and the kafka certificates are mounted in /security/kafka. The sas-sda-scr container does not access Kafka, so it does not require the Kafka mount. 

See the container-configuration-secure.yaml file for an example. Note that the volumes are created once outside the container definitions, and then used to create volumeMounts within each container.

#### Security Related Environmental Properties 

##### sas-sda-scr

The security properties for this container deal with Redis TLS. Not all are required. They cover authentication, one-way TLS, and mutual TLS. 

SAS_REDIS_AUTH_USER and SAS_REDIS_AUTH_PASSWORD are required when the Redis service is configured with user password. They can be entered directly, or referenced from a Kubernetes secret. 

SAS_REDIS_CA_CERT is the path to the certificate in the container for one-way TLS.

SAS_REDIS_TRUST_CERT_PATH is optional and may be used to add additional trusted certificates.

SAS_REDIS_CLIENT_CERT_FILE and SAS_REDIS_CLIENT_PRIV_KEY_FILE are required only to configure mutual TLS. They contain the client certificate and key used for client verification by the server. 

SAS_REDIS_TLS is used with a TLS-enabled Redis. A value of "1", "Y", or "T" will allow TLS. A value of "0", "N", or "F" will prohibit TLS. If a value is not entered, the default behavior is to prohibit TLS.

##### sas-detection

SAS detection includes properties to enable TLS for Redis and Kafka.

###### For Redis: 

SAS_DETECTION_REDIS_AUTH_PASS allows a password to be entered for Redis, using the default user.

SAS_DETECTION_REDIS_TLS_ENABLED should be set to true if the Redis server has TLS enabled. 

SAS_DETECTION_REDIS_TLS_CACERT is optional and may be used to add a trusted CA.

SAS_DETECTION_REDIS_SERVER_DOMAIN can be used to supply the correct hostname for hostname verification of the certificate

###### For Kafka

SAS_DETECTION_KAFKA_SECURITY_PROTOCOL can be PLAINTEXT, SSL, SASL_PLAINTEXT, or SASL_SSL to indicate which combination of TLS enabled and Authentication enabled protocol Kafka is using. This defaults to PLAINTEXT. SAS_DETECTION_KAFKA_TRUSTSTORE can be used to add trusted certificates.

SAS_DETECTION_KAFKA_ENABLE_HOSTNAME_VERIFICATION enables DNS verification for TLS, defaulting to true. 

SAS_DETECTION_KAFKA_SASL_USERNAME and SAS_DETECTION_KAFKA_SASL_PASSWORD define the username and password if authentication is enabled for the Kafka cluster. 
