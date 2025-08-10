---
category: security
tocprty: 1
---

# Configure Network Security and Encryption Using SAS Security Certificate Framework

* [Prerequisites](#prerequisites)
* [Configuring the Certificate Generator](#configuring-the-certificate-generator)
  * [Using the openssl Certificate Generator](#using-the-openssl-certificate-generator)
  * [Using the cert-manager Certificate Generator](#using-the-cert-manager-certificate-generator)
    * [Configure the SAS Viya Platform to Use cert-manager](#configure-the-sas-viya-platform-to-use-cert-manager)
    * [Configure cert-manager Issuers to Support the SAS Viya Platform](#configure-cert-manager-issuers-to-support-the-sas-viya-platform)
* [Configuring TLS for the Ingress Controller](#configuring-tls-for-the-ingress-controller)
  * [Using an IT-Provided Ingress Certificate on Your Ingress Controller](#using-an-it-provided-ingress-certificate-on-your-ingress-controller)
  * [Using a Provisional Ingress Controller Certificate](#using-a-provisional-ingress-controller-certificate)
    * [Using the openssl Certificate Generator to Generate the Ingress Controller Certificate](#using-the-openssl-certificate-generator-to-generate-the-ingress-controller-certificate)
    * [Using the cert-manager Certificate Generator to Generate the Ingress Controller Certificate](#using-the-cert-manager-certificate-generator-to-generate-the-ingress-controller-certificate)
      * [Using the cert-manager Certificate Generator to Generate the ingress-nginx Certificate](#using-the-cert-manager-certificate-generator-to-generate-the-ingress-nginx-certificate)
      * [Using the cert-manager Certificate Generator to Generate the OpenShift Ingress Operator Certificates](#using-the-cert-manager-certificate-generator-to-generate-the-openshift-ingress-operator-certificates)
* [Selecting kustomize Components to Enable TLS Modes](#selecting-kustomize-components-to-enable-tls-modes)
  * [Components to Enable Full-Stack TLS Mode](#components-to-enable-full-stack-tls-mode)
    * [Components to Enable Full-Stack TLS Mode with ingress-nginx](#components-to-enable-full-stack-tls-mode-with-ingress-nginx)
    * [Components to Enable Full-Stack TLS Mode with OpenShift Ingress Operator](#components-to-enable-full-stack-tls-mode-with-openshift-ingress-operator)
  * [Components to Enable Front-Door TLS Mode](#components-to-enable-front-door-tls-mode)
    * [Components to Enable Front-Door TLS Mode with ingress-nginx](#components-to-enable-front-door-tls-mode-with-ingress-nginx)
    * [Components to Enable Front-Door TLS Mode with OpenShift Ingress Operator](#components-to-enable-front-door-tls-mode-with-openshift-ingress-operator)
  * [Components to Enable Front-Door TLS Mode for CAS and SAS/CONNECT Spawner](#components-to-enable-front-door-tls-mode-for-cas-and-sasconnect-spawner)
  * [Components to Enable Full-Stack TLS Mode for All Servers](#components-to-enable-full-stack-tls-mode-for-all-servers)
* [Configuring Certificate Attributes](#configuring-certificate-attributes)
* [Incorporating Additional CA Certificates](#incorporating-additional-ca-certificates)
  * [Incorporating Additional CA Certificates into the SAS Viya Platform Deployment in Full-stack or Front-door TLS Mode](#incorporating-additional-ca-certificates-into-the-sas-viya-platform-deployment-in-full-stack-or-front-door-tls-mode)
  * [Incorporating Additional CA Certificates into the SAS Viya Platform Deployment in "No TLS" Mode](#incorporating-additional-ca-certificates-into-the-sas-viya-platform-deployment-in-no-tls-mode)
* [Example kustomization.yaml Files for ingress-nginx with the cert-manager Certificate Generator](#example-kustomizationyaml-files-for-ingress-nginx-with-the-cert-manager-certificate-generator)
  * [Full-stack TLS with cert-manager Certificate Generator and cert-manager-Generated Ingress Certificates](#full-stack-tls-with-cert-manager-certificate-generator-and-cert-manager-generated-ingress-certificates)
  * [Full-stack TLS with cert-manager Certificate Generator and Customer-Provided Ingress Certificates](#full-stack-tls-with-cert-manager-certificate-generator-and-customer-provided-ingress-certificates)
  * [Front-door TLS with cert-manager Certificate Generator and cert-manager-Generated Ingress Certificates](#front-door-tls-with-cert-manager-certificate-generator-and-cert-manager-generated-ingress-certificates)
  * [Front-door TLS with cert-manager Certificate Generator and Customer-Provided Ingress Certificates](#front-door-tls-with-cert-manager-certificate-generator-and-customer-provided-ingress-certificates)
* [Example kustomization.yaml Files for ingress-nginx with the openssl Certificate Generator](#example-kustomizationyaml-files-for-ingress-nginx-with-the-openssl-certificate-generator)
  * [Full-stack TLS with openssl Certificate Generator and openssl-generated Ingress Certificates](#full-stack-tls-with-openssl-certificate-generator-and-openssl-generated-ingress-certificates)
  * [Full-stack TLS with openssl Certificate Generator and Customer-Provided Ingress Certificates](#full-stack-tls-with-openssl-certificate-generator-and-customer-provided-ingress-certificates)
  * [Front-door TLS with openssl Certificate Generator and Customer-Provided Ingress Certificates](#front-door-tls-with-openssl-certificate-generator-and-customer-provided-ingress-certificates)
* [Example kustomization.yaml Files for the OpenShift Ingress Controller with the cert-manager Certificate Generator](#example-kustomizationyaml-files-for-the-openshift-ingress-controller-with-the-cert-manager-certificate-generator)
  * [Full-stack TLS with cert-manager Certificate Generator and Customer-Provided OpenShift Ingress Certificates](#full-stack-tls-with-cert-manager-certificate-generator-and-customer-provided-openshift-ingress-certificates)

## Prerequisites

Before reading this document, you should be familiar with the content in [SAS® Viya® Platform Encryption: Data in Motion](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calencryptmotion&docsetTarget=titlepage.htm). In addition, you should have made the following decisions:

* which certificate generator to use
* whether you provide your own ingress certificate or use an ingress certificate generated by the selected certificate generator
* which TLS mode to use: Full-stack, Front-door, or No TLS

## Configuring the Certificate Generator

### Using the openssl Certificate Generator

Because the openssl certificate generator is the default, the absence of references to a certificate generator in your site-config directory will result in openssl being used.  No additional steps are required.

### Using the cert-manager Certificate Generator

For information about supported versions of cert-manager, see [Kubernetes Cluster Requirements](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n1ika6zxghgsoqn1mq4bck9dx695.htm#n0mhb21pl07ohgn1hj4zsgfeq8hj).

In order to use the cert-manager certificate generator, it must be correctly configured prior to deploying the SAS Viya platform.

#### Configure the SAS Viya Platform to Use cert-manager

1. Create a configMap generator to customize the sas-certframe settings.  The steps to create these customizations are located in [Configuring Certificate Attributes](#configuring-certificate-attributes).

2. Set the `SAS_CERTIFICATE_GENERATOR` environment variable to `cert-manager` in the file you created in step 1. Here is an example:

   ```yaml
   ---
   apiVersion: builtin
   kind: ConfigMapGenerator
   metadata:
     name: sas-certframe-user-config
   behavior: merge
   literals:
   - SAS_CERTIFICATE_GENERATOR=cert-manager
   ```

#### Configure cert-manager Issuers to Support the SAS Viya Platform

Cert-manager uses a CA Issuer to create the server identity certificates used by the SAS Viya platform.  The cert-manager CA issuer requires an issuing CA certificate.  The issuing CA for the issuer is stored in a secret named sas-viya-ca-certificate-secret. Add a reference to the cert-manager issuer to the resources block of the base kustomization.yaml file. Here is an example:

```yaml
resources:
...
- sas-bases/overlays/cert-manager-issuer
```

## Configuring TLS for the Ingress Controller

### Using an IT-Provided Ingress Certificate on Your Ingress Controller

Copy this example file to your `/site-config` directory, and modify it as described in the comments:

```bash
cd $deploy
cp sas-bases/examples/security/customer-provided-ingress-certificate.yaml site-config/security
vi site-config/security/customer-provided-ingress-certificate.yaml
```

When you have completed your modifications, add the path to this file to the `generators` block of your `$deploy/kustomization.yaml` file (see the examples below to add a
`generators:` block if one does not already exist).

```yaml
generators:
- site-config/security/customer-provided-ingress-certificate.yaml # configures the ingress to use a secret that contains customer-provided certificate and key
```

### Using a Provisional Ingress Controller Certificate

#### Using the openssl Certificate Generator to Generate the Ingress Controller Certificate

An example of the code that creates an ingress controller certificate and stores it in a secret is provided in the following file:

`sas-bases/examples/security/openssl-generated-ingress-certificate.yaml`

Copy the example to your `/site-config` directory and modify it as described in the comments that are included in the code.

```bash
cd $deploy
cp sas-bases/examples/security/openssl-generated-ingress-certificate.yaml site-config/security
vi site-config/security/openssl-generated-ingress-certificate.yaml
```

When you have completed your modifications, add the path to this file to the resources block of your base kustomization.yaml file:

```yaml
resources:
- site-config/security/openssl-generated-ingress-certificate.yaml # causes openssl to generate an ingress certificate and key and store them in a secret
```

#### Using the cert-manager Certificate Generator to Generate the Ingress Controller Certificate

##### Using the cert-manager Certificate Generator to Generate the ingress-nginx Certificate

To use cert-manager to generate the ingress certificate, add the following path to the transformers block of your base kustomization.yaml file:

```yaml
transformers:
- sas-bases/overlays/cert-manager-provided-ingress-certificate/ingress-annotation-transformer.yaml # causes cert-manager to generate an ingress certificate and key and store them in a secret
```

##### Using the cert-manager Certificate Generator to Generate the OpenShift Ingress Operator Certificates

An example of the code that configures cert-manager to generate the certificate and secret is provided in the following file:

`sas-bases/examples/security/cert-manager-pre-created-ingress-certificate.yaml`

Copy the example to your `/site-config` directory and modify it as described in the comments that are included in the code.  Note that you will need to know the network DNS alias of your Kubernetes ingress controller.

```bash
cd $deploy
cp sas-bases/examples/security/cert-manager-pre-created-ingress-certificate.yaml site-config/security
vi site-config/security/cert-manager-pre-created-ingress-certificate.yaml
```

When you have completed your modifications, add the path to this file to the resources block of your base kustomization.yaml file:

```yaml
resources:
- site-config/security/cert-manager-pre-created-ingress-certificate.yaml # causes cert-manager to generate an ingress certificate and key and store them in a secret
```

## Selecting kustomize Components to Enable TLS Modes

Ensure that any of the following TLS components that are added to the `components` block of the base kustomization.yaml file come **after** any other SAS-provided components, but **before** any user-provided components. This ensures that TLS customizations are applied to the fully-formed manifests of individual SAS offerings without conflicting with any customizations applied by the user.

### Components to Enable Full-Stack TLS Mode

In Full-stack TLS mode, the ingress controller must be configured to decrypt incoming network traffic and re-encrypt traffic before forwarding it to the back-end SAS servers. Network traffic between SAS servers is encrypted in this mode. To enable Full-Stack TLS, include the customization that corresponds to your ingress controller in the `components` block of the base kustomization.yaml file:

#### Components to Enable Full-Stack TLS Mode with ingress-nginx

```yaml
components:
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls
```

#### Components to Enable Full-Stack TLS Mode with OpenShift Ingress Operator

```yaml
components:
- sas-bases/components/security/network/route.openshift.io/route/full-stack-tls
```

### Components to Enable Front-Door TLS Mode

#### Components to Enable Front-Door TLS Mode with ingress-nginx

```yaml
components:
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/front-door-tls
```

#### Components to Enable Front-Door TLS Mode with OpenShift Ingress Operator

```yaml
components:
- sas-bases/components/security/network/route.openshift.io/route/front-door-tls
```

### Components to Enable Front-Door TLS Mode for CAS and SAS/CONNECT Spawner

Add this component to your kustomization.yaml to configure the SAS Viya platform for Front-door TLS mode and configure CAS and SAS/CONNECT to encrypt network traffic:

_**IMPORTANT:**_ Do not add more than one component for SAS servers TLS. The component for each TLS mode must be used by itself.

```yaml
components:
- sas-bases/components/security/core/base/front-door-tls  # component to build trust stores for all services and enable back-end TLS for CAS and SAS/CONNECT
```

### Components to Enable Full-Stack TLS Mode for All Servers

_**Note:**_ TLS for the ingress controller is required if you are using Full-stack TLS.

_**IMPORTANT:**_ Do not add more than one TLS component. The component for each TLS mode must be used by itself. Include this customization in the `components` block of the base kustomization.yaml file:

``` yaml
components:
- sas-bases/components/security/core/base/full-stack-tls # component to support TLS for back-end servers
```

## Configuring Certificate Attributes

An example configMap is provided to help you customize configuration settings. To create this configMap with non-default settings, see the comments in the provided example file, `$deploy/sas-bases/examples/security/customer-provided-merge-sas-certframe-configmap.yaml`:

```bash
cd $deploy
cp sas-bases/examples/security/customer-provided-merge-sas-certframe-configmap.yaml site-config/security/
vi site-config/security/customer-provided-merge-sas-certframe-configmap.yaml
```

When you have completed your updates, add the path to the file to the `generators` block of your `$deploy/kustomization.yaml` file. Here is an example:

```yaml
generators:
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # merges customer-provided configuration settings into the sas-certframe-user-config configmap
```

## Incorporating Additional CA Certificates

### Incorporating Additional CA Certificates into the SAS Viya Platform Deployment in Full-stack or Front-door TLS Mode

Follow these steps to add your proprietary CA certificates to the SAS Viya platform deployment. The certificate files must be in PEM format, and the path to the files must be relative to the directory that contains the kustomization.yaml file. You might have to maintain several files containing CA certificates and update them over time. SAS recommends creating a separate directory for these files.

1. Place your CA certificate files in the `site-config/security/cacerts` directory. Ensure that the user ID that runs the kustomize command has Read access to
   the files.

2. Copy the file `$deploy/sas-bases/examples/security/customer-provided-ca-certificates.yaml` into your `$deploy/site-config/security` directory.
3. Edit the `site-config/security/customer-provided-ca-certificates.yaml` file and specify the required information.

   Instructions for editing this file are provided as comments in the file.

Here is an example:

```bash
export deploy=~/deploy
cd $deploy
mkdir -p site-config/security/cacerts
#
# the following line assumes that your CA Certificates are in a file named /tmp/my_ca_certificates.pem
#
cp /tmp/my_ca_certificates.pem site-config/security/cacerts
cp sas-bases/examples/security/customer-provided-ca-certificates.yaml site-config/security
vi site-config/security/customer-provided-ca-certificates.yaml
```

When you have completed your modifications, add the path to this file to the `generators` block of your `$deploy/kustomization.yaml` file. Here is an example:

```yaml
generators:
- site-config/security/customer-provided-ca-certificates.yaml # generates a configmap that contains CA Certificates
```

### Incorporating Additional CA Certificates into the SAS Viya Platform Deployment in "No TLS" Mode

In order to add CA certificates to pod trust bundles, add the following component to the `components` block of your base kustomization.yaml file:

_**IMPORTANT:**_ Do not add this component if you have configured Front-door TLS or Full-stack TLS mode.

```yaml
components:
- sas-bases/components/security/core/base/truststores-only # component to build trust stores when no TLS is desired
```

## Example kustomization.yaml Files for ingress-nginx with the cert-manager Certificate Generator

### Full-stack TLS with cert-manager Certificate Generator and cert-manager-Generated Ingress Certificates

```yaml
# Full-stack TLS with cert-manager certificate generator and cert-Manager generated ingress certificates
namespace: fullstacktls
resources:
- sas-bases/base
- sas-bases/overlays/cert-manager-issuer
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/full-stack-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls

transformers:
- sas-bases/overlays/required/transformers.yaml
- sas-bases/overlays/cert-manager-provided-ingress-certificate/ingress-annotation-transformer.yaml # causes cert-manager to generate the ingress certificate and key and store it in a secret

generators:
- site-config/security/customer-provided-ca-certificates.yaml # This generator is optional. Include it only if you need to add additional CA Certificates
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # make sure edits to the site-config/security/customer-provided-merge-sas-certframe-configmap.yaml file are in place
```

### Full-stack TLS with cert-manager Certificate Generator and Customer-Provided Ingress Certificates

```yaml
# Full-stack TLS with cert-manager certificate generator and customer-provided ingress certificates
namespace: fullstacktls
resources:
- sas-bases/base
- sas-bases/overlays/cert-manager-issuer
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/full-stack-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # make sure edits to the site-config/security/customer-provided-merge-sas-certframe-configmap.yaml file are in place
```

### Front-door TLS with cert-manager Certificate Generator and cert-manager-Generated Ingress Certificates

```yaml
# Front-door TLS with cert-manager certificate generator and cert-Manager generated ingress certificates
namespace: frontdoortls
resources:
- sas-bases/base
- sas-bases/overlays/cert-manager-issuer
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/front-door-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/front-door-tls

transformers:
- sas-bases/overlays/required/transformers.yaml
- sas-bases/overlays/cert-manager-provided-ingress-certificate/ingress-annotation-transformer.yaml # causes cert-manager to generate the ingress certificate and key and store it in a secret

generators:
- site-config/security/customer-provided-ca-certificates.yaml # This generator is optional. Include it only if you need to add additional CA Certificates
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # make sure edits to the site-config/security/customer-provided-merge-sas-certframe-configmap.yaml file are in place
```

### Front-door TLS with cert-manager Certificate Generator and Customer-Provided Ingress Certificates

```yaml
# Front-door TLS with cert-manager certificate generator and customer-provided ingress certificates
namespace: frontdoortls
resources:
- sas-bases/base
- sas-bases/overlays/cert-manager-issuer
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/front-door-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/front-door-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # make sure edits to the site-config/security/customer-provided-merge-sas-certframe-configmap.yaml file are in place
```

## Example kustomization.yaml Files for ingress-nginx with the openssl Certificate Generator

### Full-stack TLS with openssl Certificate Generator and openssl-generated Ingress Certificates

```yaml
# Full-stack TLS with openssl certificate generator and openssl generated ingress certificates
namespace: fullstacktls
resources:
- sas-bases/base
- sas-bases/overlays/network/networking.k8s.io
- site-config/security/openssl-generated-ingress-certificate.yaml

components:
- sas-bases/components/security/core/base/full-stack-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ca-certificates.yaml
```

### Full-stack TLS with openssl Certificate Generator and Customer-Provided Ingress Certificates

```yaml
# Full-stack TLS with openssl certificate generator and customer-provided ingress certificates
namespace: fullstacktls
resources:
- sas-bases/base
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/full-stack-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
```

### Front-door TLS with openssl Certificate Generator and Customer-Provided Ingress Certificates

```yaml
# Front-door TLS with openssl certificate generator and customer-provided ingress certificates
namespace: frontdoortls
resources:
- sas-bases/base
- sas-bases/overlays/network/networking.k8s.io

components:
- sas-bases/components/security/core/base/front-door-tls
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/front-door-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
```

## Example kustomization.yaml Files for the OpenShift Ingress Controller with the cert-manager Certificate Generator

### Full-stack TLS with cert-manager Certificate Generator and Customer-Provided OpenShift Ingress Certificates

```yaml
# Full-stack TLS with cert-manager certificate generator and customer-provided ingress certificates
namespace: fullstacktls
resources:
- sas-bases/base
- sas-bases/overlays/cert-manager-issuer
- sas-bases/overlays/network/route.openshift.io

components:
- sas-bases/components/security/core/base/full-stack-tls
- sas-bases/components/security/network/route.openshift.io/route/full-stack-tls

transformers:
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
- site-config/security/customer-provided-merge-sas-certframe-configmap.yaml # make sure edits to the site-config/security/customer-provided-merge-sas-certframe-configmap.yaml file are in place
```
