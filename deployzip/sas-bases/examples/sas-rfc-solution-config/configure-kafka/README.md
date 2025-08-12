---
category: SAS RFC Solution Configuration
tocprty: 5
---

# SAS RFC Solution Configuration Patch to Communicate with Apache Kafka

## Overview

The SAS RFC Solution Configuration Service installs three Kubernetes resources that define how Fraud solutions communicate with Apache Kafka.

- A configmap containing basic properties like the location of the Apache Kafka cluster.
- A secret containing the credentials required to communicate with Apache Kafka.
- A secret containing the certificate needed for Apache Kafka TLS.

This README file describes how to replace the placeholders in the files with values and secret data for a specific Apache Kafka cluster.

## Prerequisites

- SAS RFC Solution Configuration service is deployed in the SAS Viya platform.
- You have a running Apache Kafka cluster that Fraud products will use for consuming and producing messages.

## Installation

1. Copy all of the files in `$deploy/sas-bases/examples/sas-rfc-solution-config/configure-kafka` to `$deploy/site-config/sas-rfc-solution-config`, where $deploy is the directory containing your SAS Viya platform installation files. Create the target directory, if it does not already exist.

2. Edit the `$deploy/site-config/sas-rfc-solution-config/kafka-configuration-patch.yaml` file. Update properties, especially the server, protocol and topics. Add any properties as  recommended by product documentation or customer support. Here is an example:

   ```yaml
   - op: replace
     path: /data
     value:
      SAS_KAFKA_SERVER: "fsi-kafka-kafka-bootstrap.kafka.svc.cluster.local:9093"
      SAS_KAFKA_CONSUMER_DEBUG: ""
      SAS_KAFKA_PRODUCER_DEBUG: ""
      SAS_KAFKA_OFFSET: earliest
      SAS_KAFKA_ACKS: "2"
      SAS_KAFKA_BATCH: ""
      SAS_KAFKA_LINGER: ""
      SAS_KAFKA_AUTO_CREATE_TOPICS: "true"
      SAS_KAFKA_SECURITY_PROTOCOL: "sasl_ssl"
      SAS_KAFKA_HOSTNAME_VERIFICATION: "false"
      SAS_DETECTION_KAFKA_TOPIC: "input-transactions"
      SAS_DETECTION_KAFKA_TDR_TOPIC: "tdr-topic"
      SAS_DETECTION_KAFKA_REJECTTOPIC: "transaction-reject"
      SAS_TRIAGE_KAFKA_TDR_TOPICS: "tdr-topic"
      SAS_TRANSACTION_MARK_TOPIC: "transaction-topic-outbound"
      SAS_RWS_KAFKA_BROKERS: "fsi-kafka-kafka-bootstrap.kafka.svc.cluster.local:9093"
      SAS_RWS_KAFKA_INPUT_TOPIC: "rws-input-transactions"
      SAS_RWS_KAFKA_OUTPUT_TOPIC: "rws-output-transactions"
      SAS_RWS_KAFKA_ERROR_TOPIC: "rws-error-transactions"
      SAS_RWS_KAFKA_REJECT_TOPIC: "rws-reject-transactions"
   ```


3. Edit the `$deploy/site-config/sas-rfc-solution-config/kafka-cred-patch.yaml` file. If the security protocol for Apache Kafka includes SASL, then modify the patch to include a base64 representation of the user ID and password. Here is an example:

   ```yaml
   - op: replace
     path: /data
     value:
       username: ...
       password: ...
   ```


4. Edit the `$deploy/site-config/sas-rfc-solution-config/kafka-truststore-patch.yaml` file. If the security protocol for kafka includes SSL, then update the patch to use the correct certificate.  Here is an example:

   ```yaml
   - op: replace
     path: /data
     value:
       ca.crt: LS0tLS1CRU...
       ca.p12: MIIGogIBAz...
       ca.password: ...
   ```


5. After updating the example files, add references to them to the base kustomization.yaml file (`$deploy/kustomization.yaml`). Add a reference to the kafka-configuration-patch.yaml file as a patch.

   For example, if you made the changes described above, then the base kustomization.yaml file should have entries similar to the following:

   ```yaml

   patches:
   - target:
       version: v1
       kind: ConfigMap
       name: sas-rfc-solution-config-kafka-config
     path: site-config/sas-rfc-solution-config/kafka-configuration-patch.yaml
   - target:
       version: v1
       kind: Secret
       name: sas-rfc-solution-config-kafka-creds
     path: site-config/sas-rfc-solution-config/kafka-cred-patch.yaml
   - target:
       version: v1
       kind: Secret
       name: sas-rfc-solution-config-kafka-ca-cert
     path: site-config/sas-rfc-solution-config/kafka-truststore-patch.yaml
   ```

6. As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Deploy the Software](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).
