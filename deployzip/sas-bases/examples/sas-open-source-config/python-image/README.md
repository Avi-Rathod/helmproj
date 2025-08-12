---
category: openSourceConfiguration
tocprty: 3
---

# Configure Python for the SAS Viya Platform Using a Docker Image

## Overview

The SAS Viya platform can use a customer-prepared environment consisting of a Python installation (and any required packages) that are stored on a Kubernetes PersistentVolume or a Docker image. This README describes how to make a Docker image that contains a Python installation available to your deployment.

**Note:** Python can be used by the Micro Analytic Score service, Cloud Analytic Services (CAS) and the Compute service. However, accessing Python via a Docker image is currently available as an option only for the Micro Analytic Score service. Therefore, if you use this method and you require Python for CAS or the Compute Server, a Python distribution must also be available via a Kubernetes persistent volume.

## Prerequisites

Because Python can be used from a Docker image only by the Micro Analytic Score service, until the Docker image is available to other pods, make sure that the Python environment in the Docker image is available in the mounted volume for other pods. The SAS Viya platform provides YAML files that the Kustomize tool uses to configure Python. Before you use those files, you must perform the following tasks:

1. Prepare the Python Docker image with all the necessary Python packages that you will be using. Make note of the Python image URL  in the Docker registry ( {{ PYTHON-DOCKER-IMAGE-URL }} parameter in python-transformer.yaml) and the configuration settings for accessing the registry with the Python image ( {{ DOCKER-REGISTRY-CONFIG }} parameter in kustomization.yaml).

   Here is a sample Docker registry configuration setting:

   ```json
   {"auths": {"registry.company.com": {"username": "myusername","password": "mypassword","email":"myemail@company.com","auth":"< mysername:mypassword in base64 encoded form>"}}}
   ```

   For more information about Python image preparation and registry configuration settings, see [Additional Resources](#additional-resources).

2. Make note of the attributes for the volume where Python and the associated packages are to be deployed. For example, note the server and directory for NFS.
   For more information about various types of PersistentVolumes in Kubernetes, see [Additional Resources](#additional-resources).

3. Install Python and any necessary packages on the volume.

4. In addition to the volume attributes, you must have the following information:

   * {{ PYTHON-IMAGE-EXECUTABLE }} - the name of the Python executable file (for example, python or python3.8) in the Python image.
   * {{ PYTHON-IMAGE-EXE-DIR }} - the directory (relative to the root) that contains the executable (for example, /bin).
   * {{ PYTHON-EXECUTABLE }} - the name of the Python executable file (for example, python or python3.8) in the Python mount.
   * {{ PYTHON-EXE-DIR }} - the directory or partial path (relative to the mount) that contains the executable (for example, /bin or /virt_environs/envron_dm1/bin). Note that the mount point for your Python deployment should be its top-level directory.
   * {{ SAS-EXTLANG-SETTINGS-XML-FILE }} - the configuration file used to enable Python and R integration in CAS. This is required only if you are using Python with CMP or the EXTLANG package.
   * {{ SAS-EXT-LLP-PYTHON-PATH }} - the list of directories to look for when searching for run-time shared libraries (similar to LD_LIBRARY_PATH).

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-open-source-config/python` directory to the `$deploy/site-config/sas-open-source-config/python` directory.
   Create the destination directory, if it does not already exist.

   **Note:** If the destination directory already exists, [verify that the overlay](#verify-the-overlay-for-the-python-docker-image) has been applied.
   If the output contains the `/mas2py` mount directory path, you do not need to take any further action unless you want to change the overlay parameters to use a different Python environment.

2. Use the kustomization.yaml file to define the necessary environment variables. Replace all tags, such as {{ PYTHON-EXE-DIR }}, with the values that you gathered in the [Prerequisites](#prerequisites) step.
   Then set the following parameters according to the SAS products that you will be using:

   * MAS_PYPATH and MAS_M2PATH are used by SAS Micro Analytic Service.
   * PROC_PYPATH and PROC_M2PATH are used by PROC PYTHON in the Compute Server. PROC_M2PATH defaults to the correct location in the install, so it is not required to be provided in the kustomization.yaml. However, the example file shows the correct path as the value.
   * DM_PYPATH is used by the Open Source Code node in SAS Visual Data Mining and Machine Learning. You can add DM_PYPATH2, DM_PYPATH3, DM_PYPATH4 and DM_PYPATH5 if you need to specify multiple Python environments. The Open Source Code node allows you to choose which of these five environment variables to use during execution.
   * SAS_EXTLANG_SETTINGS is used by applications that run Python and R code on CAS. This includes PROC FCMP and the Time Series External Languages (EXTLANG) package.
     SAS_EXTLANG_SETTINGS should be set in only one example file; for example, if you set it in the Python example, you should not set it in the R example.
     SAS_EXTLANG_SETTINGS should point to an XML file that is readable by all users. The path can be in the same volume that contains the R environment or in any other volume that is accessible to CAS.
     Refer to the documentation for the Time Series External Languages (EXTLANG) package for details about the expected XML schema.
   * SAS_EXT_LLP_PYTHON is used when the base distribution or packages for open-source software require additional run-time libraries that are not part of the shipped container image.

   **Note:** Any environment variables that you define in this example will be set on all pods, although they might not have an effect.
   For example, setting MAS_PYPATH will not affect the Python executable used by the EXTLANG package. That executable is set in the SAS_EXTLANG_SETTINGS file.
   However, if you define $MAS_PYPATH you can then use it in the SAS_EXTLANG_SETTINGS file. Here is an example:

   ```<LANGUAGE name="PYTHON3" interpreter="$MAS_PYPATH"></LANGUAGE>```

3. Attach storage to your SAS Viya platform deployment. The python-image-transformer.yaml file uses PatchTransformers in Kustomize to attach the Python installation volume to the SAS Viya platform.
   Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification.

   For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be replaced with `nfs: {path: /vol/python, server: myserver.sas.com}`
   where `myserver.sas.com` is the NFS server and `/vol/python` is the NFS path that you recorded in the Prerequisites step.

   Here is the relevant code excerpt from the python-image-transformer.yaml file before the change:

   ```yaml
   patch: |-
   # Add side car Container
     - op: add
       path: /spec/template/spec/containers/-
       value:
         name: viya4-mas-python-runner
         image: {{ PYTHON-DOCKER-IMAGE-URL }}
   ```

   ```yaml
   patch: |-
   # Add Python Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: python-volume, {{ VOLUME-ATTRIBUTES }} }
   ```

   Here is the relevant code excerpt from the python-image-transformer.yaml file after the change:

   ```yaml
   patch: |-
   # Add side car Container
     - op: add
       path: /spec/template/spec/containers/-
       value:
         name: viya4-mas-python-runner
         image: registry.company.com/python-env:latest
    ```

   ```yaml
   patch: |-
   # Add Python Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: python-volume, nfs: {path: /vol/python, server: myserver.sas.com} }
   ```

    Here is the relevant code excerpt from the kustomization.yaml file before the change:

   ```yaml
   secretGenerator:
   - name: python-regcred
     type: kubernetes.io/dockerconfigjson
     literals:
     - '.dockerconfigjson={{ DOCKER-REGISTRY-CONFIG }}'
   ```

   The relevant code excerpt from the kustomization.yaml file after the change:

   ```yaml
   secretGenerator:
   - name: python-regcred
     type: kubernetes.io/dockerconfigjson
     literals:
     - '.dockerconfigjson={"auths": {"registry.company.com": {"username": "myusername","password": "mypassword","email":"myemail@company.com","auth":"< mysername:mypassword in base64 encoded form>"}}}'
    ```

4. The python-image-transformer.yaml file contains a PatchTransformer called sas-python-sas-java-policy-allow-list.  This PatchTransformer sets paths to the Python executable so that the SAS runtime
   allows execution of the Python code.  Replace the {{ PYTHON-EXE-DIR }} and {{ PYTHON-EXECUTABLE }} tags with the appropriate values.  If you are specifying multiple Python
   environments, each need to be set here.   Here is an example:

   ```yaml
   apiVersion: builtin
   kind: PatchTransformer
   metadata:
     name: add-python-sas-java-policy-allow-list
   patch: |-
     - op: add
       path: /data/SAS_JAVA_POLICY_ALLOW_DM_PYPATH
       value: /python/python3/bin/python3.8
     - op: add
       path: /data/SAS_JAVA_POLICY_ALLOW_DM_PYPATH2
       value: /python/python2/bin/python2.7
   target:
     kind: ConfigMap
     name: sas-programming-environment-java-policy-config
   ```

5. Python runs in a separate container in the sas-microanalytic-score pod. Default resource limits are defined for the Python container in the python-image-transformer.yaml file. Depending on your application requirements, the CPU and memory values can be modified in the resources section of that file. Here is an example:

   ```yaml
    command: ["$(MAS_PYPATH)", "$(MAS_M2PATH)"]
    envFrom:
    - configMapRef:
        name: sas-open-source-config-python-image-mas
    resources:
      requests:
        memory: 50Mi
        cpu: 50m
      limits:
        memory: 500Mi
        cpu: 500m
   ```

6. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   * Add site-config/sas-open-source-config/python-image to the resources block.
   * Add site-config/sas-open-source-config/python-image/python-image-transformer.yaml to the transformers block before the `sas-bases/overlays/required/transformers.yaml`.

   Here is an example:

   ```yaml
    resources:
    - site-config/sas-open-source-config/python-image

    transformers:
    ...
    - site-config/sas-open-source-config/python-image/python-image-transformer.yaml
    - sas-bases/overlays/required/transformers.yaml
   ```

7. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

   * If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
   * If you are applying the overlay after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.

   All affected pods, except the CAS Server pod, are automatically restarted when the overlay is applied. If the overlay is applied after the initial deployment, the CAS Server might need an explicit restart. For information, see [Restart CAS Server](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calserverscas&docsetTarget=n03003viyaservers000000admin.htm&locale=en#p10hialoaqhwrtn1fuhsuakffwtv).

## Verify the Overlay for the Python Docker Image

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```

2. Verify that the output contains the following mount directory paths:

   ```yaml
   Mounts:
     /mas2py
   ```

## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Persistent Volumes in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
* [Volume Types in Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)
* [Docker Registry Configuration in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#inspecting-the-secret-regcred)
* [Docker Image for Python](https://www.docker.com/blog/containerized-python-development-part-1/)
* [External Languages Access Control Configuration](http://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=castsp&docsetTarget=castsp_extlang_sect002.htm) in _SAS Viya Platform Programming Documentation_
* [Configuring SAS Micro Analytic Service to Use a Python Distribution](http://documentation.sas.com/?cdcId=mascdc&cdcVersion=default&docsetId=masag&docsetTarget=n149q46z3dnttzn1v4tt2adb1ebc.htm) in _SAS Micro Analytic Service: Programming and Administration Guide_
* [PYTHON Procedure](http://documentation.sas.com/doc/en/pgmsascdc/default/proc/p1iycdzbxw2787n178ysea5ghk6l.htm)
