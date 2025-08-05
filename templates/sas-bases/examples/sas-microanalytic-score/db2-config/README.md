---
category: SAS Micro Analytic Service
tocprty: 6
---

# Configure SAS Micro Analytic Service to Enable Access to the IBM DB2 Client

## Overview

This document describes customizations that must be performed by the Kubernetes administrator for deploying SAS Micro Analytic Service to enable access to a DB2 database.

SAS Micro Analytic Service uses the installed DB2 client environment. This environment must be accessible from a PersistentVolume.

**Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

## Prerequisites

The DB2 Client must be installed. After the initial DB2 Client setup, two directories (for example, /db2client and /db2) must be created and accessible to SAS Micro Analytic Service.
Ensure that the two directories contain the installed client files (for example, /db2client) and the configured server definition files (/db2).

## Installation

1. Copy the files in `$deploy/sas-bases/examples/sas-microanalytic-score/db2-config` to the `$deploy/site-config/sas-microanalytic-score/db2-config` directory. Create the destination directory, if it does not already exist.

2. Modify the three files under the site-config/sas-microanalytic-score/db2-config folder to point to your settings.

   * Modify the `$deploy/site-config/sas-microanalytic-score/db2-config/data-mounts-mas.yaml` file:
     * Replace each instance of {{ DB2_CLIENT_DIR_NAME }} with a desired name (for example, db2client)
     * Replace {{ DB2_CLIENT_DIR_MOUNT_PATH }} with an appropriate path for the installed DB2 client files (for example, "/db2client")
     * Replace {{ DB2_CLIENT_DIR_PATH }} with the location of the db2client folder (for example, /shared/gelcontent/access-clients/db2client)
     * Replace {{ DB2_CLIENT_DIR_SERVER_NAME }} with the name of the server where DB2 Client is installed (for example, cloud.example.com)
     * Replace each instance of {{ DB2_CONFIGURED_DIR_NAME }} with a desired name (for example, db2)
     * Replace {{ DB2_CONFIGURED_DIR_MOUNT_PATH }} with an appropriate path for the DB2 configured server definition files (for example, "/db2")
     * Replace {{ DB2_CONFIGURED_DIR_PATH }} with the location where the DB2 configured server definition files exist (for example, /shared/gelcontent/access-clients/db2)
     * Replace {{ DB2_CONFIGURED_DIR_SERVER_NAME }} with the name of the server where the DB2 configured server definition files exist (for example, cloud.example.com)

   * Modify the `$deploy/site-config/sas-microanalytic-score/db2-config/etc-hosts-mas.yaml` file:
     * Replace {{ DB2_DATABASE_IP }} with the IP address of the DB2 database server (for example, "192.0.2.0")
     * Replace {{ DB2_DATABASE_HOSTNAME }} with the DB2 database host name (for example, "MyDBHost")

   * Modify the `$deploy/site-config/sas-microanalytic-score/db2-config/db2-environment-variables-mas.yaml` file:
     * Replace {{ .Values.VALUE_1 }} with the appropriate value of DB2DIR (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_2 }} with the appropriate value of DB2INSTANCE (for example, "sas")
     * Replace {{ .Values.VALUE_3 }} with the appropriate value of DB2LIB (for example, "/db2client/sqllib/lib")
     * Replace {{ .Values.VALUE_4 }} with the appropriate value of DB2_HOME (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_5 }} with the appropriate value of DB2_NET_CLIENT_PATH (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_6 }} with the appropriate value of IBM_DB_DIR (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_7}} with the appropriate value of IBM_DB_HOME (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_8}} with the appropriate value of IBM_DB_INCLUDE (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_9}} with the appropriate value of IBM_DB_LIB (for example, "/db2client/sqllib/lib")
     * Replace {{ .Values.VALUE_10}} with the appropriate value of INSTHOME (for example, "/db2")
     * Replace {{ .Values.VALUE_11}} with the appropriate value of INST_DIR (for example, "/db2client/sqllib")
     * Replace {{ .Values.VALUE_12}} with the appropriate value of DB2 (for example, "/db2client/sqllib/lib64:/db2client/sqllib/lib64/gskit:/db2client/sqllib/lib32")
     * Replace {{ VALUE_13 }} with the appropriate value of DB2_BIN (for example, "/db2client/sqllib/bin:/db2client/sqllib/adm:/db2client/sqllib/misc")
     * Replace {{ VALUE_14 }} with the appropriate value of SAS_EXT_LLP_ACCESS (for example, "/db2client/sqllib/lib64:/db2client/sqllib/lib64/gskit:/db2client/sqllib/lib32")
     * Replace {{ VALUE_15 }} with the appropriate value of SAS_EXT_PATH_ACCESS (for example, "/db2client/sqllib/bin:/db2client/sqllib/adm:/db2client/sqllib/misc")


3. Make the following changes to the transformers block of base kustomization.yaml file ('$deploy/kustomization.yaml')

   * Add site-config/sas-microanalytic-score/db2-config/data-mounts-mas.yaml
   * Add site-config/sas-microanalytic-score/db2-config/etc-hosts-mas.yaml
   * Add site-config/sas-microanalytic-score/db2-config/db2-environment-variables-mas.yaml

   Here is an example:

   ```yaml
   transformers:
   - site-config/sas-microanalytic-score/db2-config/data-mounts-mas.yaml # patch to setup mount for mas
   - site-config/sas-microanalytic-score/db2-config/etc-hosts-mas.yaml # Host aliases
   - site-config/sas-microanalytic-score/db2-config/db2-environment-variables-mas.yaml  # patch to inject environment variables for DB2
   ```

4. Complete one of the following deployment steps to apply the new settings.
   
   * If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, and then see [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_ for more information.
   * If you are applying the overlay after the initial deployment of the SAS Viya platform, see [Modify Existing Customizations in a Deployment](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm) in _SAS Viya Platform: Deployment Guide_ for information about how to redeploy the software.

## Verify Overlays for the Persistent Volumes

1. Run the following command to verify whether the overlays have been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```

2. Verify that the output contains the following mount directory paths:

   ```yaml
   Mounts:
     /db2 from db2 (rw)
     /db2client from db2client (rw)
   ```

3. Verify that the output shows that each environment variable is assigned the appropriate value. Here is an example:
   ```yaml
   Environment:
      SAS_K8S_DEPLOYMENT_NAME:               sas-microanalytic-score
      DB2DIR:                                /db2client/sqllib
      DB2INSTANCE:                           sas
      DB2LIB:                                /db2client/sqllib/lib
      DB2_HOME:                              /db2client/sqllib
      DB2_NET_CLIENT_PATH:                   /db2client/sqllib
      IBM_DB_DIR:                            /db2client/sqllib
      IBM_DB_HOME:                           /db2client/sqllib
      IBM_DB_INCLUDE:                        /db2client/sqllib/
      IBM_DB_LIB:                            /db2client/sqllib/lib
      INSTHOME:                              /db2
      INST_DIR:                              /db2client/sqllib
      DB2:                                   /db2client/sqllib/lib64:/db2client/sqllib/lib64/gskit:/db2client/sqllib/lib32
      DB2_BIN:                               /db2client/sqllib/bin:/db2client/sqllib/adm:/db2client/sqllib/misc
      SAS_EXT_LLP_ACCESS:                    /db2client/sqllib/lib64:/db2client/sqllib/lib64/gskit:/db2client/sqllib/lib32
      SAS_EXT_PATH_ACCESS:                   /db2client/sqllib/bin:/db2client/sqllib/adm:/db2client/sqllib/misc
   ```
## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
* [Accessing Analytic Store Model Files](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calmodels&docsetTarget=n10916nn7yro46n119nev9sb912c.htm) in _SAS Viya Platform: Models Administration_
* [Configuring Analytic Store and Python Model Directories](http://documentation.sas.com/?cdcId=mascdc&cdcVersion=default&docsetId=masag&docsetTarget=n0er040gsczf7bn1mndiw7znffad.htm) in _SAS Micro Analytic Service: Programming and Administration Guide_