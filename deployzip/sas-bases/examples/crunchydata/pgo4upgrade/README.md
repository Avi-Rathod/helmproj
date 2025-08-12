---
category: dataServer
tocprty: 40
---

# Upgrade to PostgreSQL Operator v5

## Overview

Beginning with version 2022.10, the SAS Viya platform uses version 5 of the Crunchy Data PostgreSQL Operator. This README describes how to upgrade the PostgreSQL Operator and the PostgreSQL clusters it manages.

**Note:** The PostgreSQL Operator is specific to internal PostgreSQL. If the SAS Viya platform is configured to use external PostgreSQL, skip the contents of this README. You should also skip the contents of this README if the deployment is managed by the SAS Viya Platform Deployment Operator or you have already deployed the correct PostgreSQL Operator version. To check the version that is deployed, run the following command. If it returns an error or a message "No resources found in <your-namespace> namespace", you are at version 5 of the operator.

```bash
kubectl get pgclusters.crunchydata.com -n {{ NAME-OF-NAMESPACE }}
```

## Instructions

Perform the steps under each of the following subsections in the order they are written.

### Scale Down the SAS Data Server Operator

1. Scale down the existing SAS Data Server Operator deployment. In the following command, replace the entire variable `{{ NAME-OF-NAMESPACE }}`, including the braces, with your SAS Viya platform namespace.

    ```bash
    kubectl scale deployment --replicas=0 sas-data-server-operator -n {{ NAME-OF-NAMESPACE }}
    ```

    If you receive the following error, your SAS Viya platform deployment did not include the SAS Data Server Operator. In this case, skip to [Prepare and Terminate PostgreSQL Clusters](#prepare-and-terminate-postgresql-clusters).

    ```bash
    Error from server (NotFound): deployments.apps "sas-data-server-operator" not found
    ```

2. Wait for the SAS Data Server Operator pod to be terminated:

    ```bash
    kubectl wait --for=delete --selector="app.kubernetes.io/name=sas-data-server-operator" pods --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

### Prepare and Terminate PostgreSQL Clusters

1. List the PostgreSQL clusters included in your deployment using the command below.

    ```bash
    kubectl get pgclusters.crunchydata.com -n {{ NAME-OF-NAMESPACE }}
    ```

    The remaining steps in this section should be performed for *each* PostgreSQL cluster listed by the command. Replace the variable `{{ PGCLUSTER-NAME }}` in any later commands with the PostgreSQL cluster resource you are targeting.

2. Scale down the replica deployments. Scaling down fails back the primary if it was failed over to a replica.

    ```bash
    kubectl scale --replicas=0 deployment --selector=crunchy-pgha-scope={{ PGCLUSTER-NAME }},name!={{ PGCLUSTER-NAME }} -n {{ NAME-OF-NAMESPACE }}

    kubectl wait --for=delete --selector=crunchy-pgha-scope={{ PGCLUSTER-NAME }},name!={{ PGCLUSTER-NAME }} pods --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

    Ignore the following error, which is returned if the pods are already down before the wait command.

    ```bash
    error: no matching resources found
    ```

3. Check the cluster to ensure only one pod is running as Leader.

    ```bash
    kubectl exec deployment/{{ PGCLUSTER-NAME }} -c database -n {{ NAME-OF-NAMESPACE }} -- patronictl list
    ```

    The output should look something like the following:

    ```bash
    + Cluster: sas-crunchy-data-postgres (7016764262444130456) -----------+---------+---------+----+-----------+
    | Member                                                | Host        | Role    | State   | TL | Lag in MB |
    +-------------------------------------------------------+-------------+---------+---------+----+-----------+
    | sas-crunchy-data-postgres-7f846c5d94-wlwrp            | 10.244.2.88 | Leader  | running | 19 |           |
    +-------------------------------------------------------+-------------+---------+---------+----+-----------+
    ```

4. Delete the replica PVCs.

    ```bash
    kubectl delete pvc $(kubectl get deploy --selector=crunchy-pgha-scope={{ PGCLUSTER-NAME }},name!={{ PGCLUSTER-NAME }} -o jsonpath='{.items[*].metadata.name}' -n {{ NAME-OF-NAMESPACE }} ) --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

5. Scale down the primary deployment.

    ```bash
    kubectl scale --replicas=0 deployment --selector=crunchy-pgha-scope={{ PGCLUSTER-NAME }},name={{ PGCLUSTER-NAME }} -n {{ NAME-OF-NAMESPACE }}

    kubectl wait --for=delete --selector=crunchy-pgha-scope={{ PGCLUSTER-NAME }},name={{ PGCLUSTER-NAME }} pods --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

    Ignore the following error, which is returned if the pods are already down before the wait command.

    ```bash
    error: no matching resources found
    ```

6. Patch the security context of the pgBackrest deployment. If your deployment is running on OpenShift, skip this step.

    ```bash
    kubectl patch -n {{ NAME-OF-NAMESPACE }} deployment {{ PGCLUSTER-NAME }}-backrest-shared-repo --type json -p '[{"op": "replace", "path": "/spec/template/spec/securityContext", "value": { "runAsNonRoot": true, "runAsUser": 2000, "runAsGroup": 26, "fsGroup": 26, "supplementalGroups": [26, 2000]}}]'

    kubectl rollout status -n {{ NAME-OF-NAMESPACE }} deployment {{ PGCLUSTER-NAME }}-backrest-shared-repo
    ```

7. Modify file permissions for the pgBackrest directory. If your deployment is running on OpenShift, skip this step.

    ```bash
    kubectl exec -n {{ NAME-OF-NAMESPACE }} deployment/{{ PGCLUSTER-NAME }}-backrest-shared-repo -- chmod -R 770 /backrestrepo/{{ PGCLUSTER-NAME }}-backrest-shared-repo/

    kubectl exec -n {{ NAME-OF-NAMESPACE }} deployment/{{ PGCLUSTER-NAME }}-backrest-shared-repo -- chgrp -R postgres /backrestrepo/{{ PGCLUSTER-NAME }}-backrest-shared-repo/
    ```

8. Terminate the PostgreSQL cluster.

    Copy the template file `$deploy/sas-bases/examples/crunchydata/pgo4upgrade/pgtask-rmdata.yaml` to your site-config directory, `$deploy/site-config/`. If a copy already exists, you may overwrite it. Then, follow the instructions within the copied file to populate any necessary variables.

    After copying and filling out the file, apply it to terminate the PostgreSQL cluster. Replace the entire variable `{{ PGTASK-PATH }}`, including the braces, with the expanded location of your copy of the file `$deploy/sas-bases/examples/crunchydata/pgo4upgrade/pgtask-rmdata.yaml`.

    ```bash
    kubectl apply -f {{ PGTASK-PATH }} -n {{ NAME-OF-NAMESPACE }}
    ```

    **Note:** Your copy of the file `$deploy/sas-bases/examples/crunchydata/pgo4upgrade/pgtask-rmdata.yaml` should NOT be added or referenced in any kustomization files. After applying it, you may delete your copy of the file.

9. Wait for the internal PostgreSQL pods to be terminated.

    ```bash
    kubectl wait --for=delete --selector=pg-cluster={{ PGCLUSTER-NAME }} pods --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

10. Wait for the custom resource pgtask to be terminated.

    ```bash
    kubectl wait --for=delete --selector=pg-cluster={{ PGCLUSTER-NAME }} pgtask --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

11. Remove the TLS artifacts for the PostgreSQL cluster.

    ```bash
    kubectl delete job "{{ PGCLUSTER-NAME }}-tls-generator" --ignore-not-found=true --timeout=300s -n {{ NAME-OF-NAMESPACE }}

    kubectl delete secret "{{ PGCLUSTER-NAME }}-tls-secret" --ignore-not-found=true --timeout=300s -n {{ NAME-OF-NAMESPACE }}
    ```

12. Modify PostgreSQL file permissions. If your deployment is running on a provider other than OpenShift, skip this step.

    1. Inside your `$deploy` directory, build the Kubernetes manifest.

        ```bash
        kustomize build -o site.yaml
        ```

    2. Run Kubernetes jobs to modify PVC file permissions.

        ```bash
        kubectl -n {{ NAME-OF-NAMESPACE }} apply -f site.yaml -l "webinfdsvr.sas.com/upgrade-crunchy-step-1={{ PGCLUSTER-NAME }}"
        kubectl -n {{ NAME-OF-NAMESPACE }} wait --for=condition=complete job --timeout=300s -l "webinfdsvr.sas.com/upgrade-crunchy-step-1={{ PGCLUSTER-NAME }}"

        kubectl -n {{ NAME-OF-NAMESPACE }} apply -f site.yaml -l "webinfdsvr.sas.com/upgrade-crunchy-step-2={{ PGCLUSTER-NAME }}"
        kubectl -n {{ NAME-OF-NAMESPACE }} wait --for=condition=complete job --timeout=300s -l "webinfdsvr.sas.com/upgrade-crunchy-step-2={{ PGCLUSTER-NAME }}"

        kubectl -n {{ NAME-OF-NAMESPACE }} apply -f site.yaml -l "webinfdsvr.sas.com/upgrade-crunchy-step-3={{ PGCLUSTER-NAME }}"
        kubectl -n {{ NAME-OF-NAMESPACE }} wait --for=condition=complete job --timeout=300s -l "webinfdsvr.sas.com/upgrade-crunchy-step-3={{ PGCLUSTER-NAME }}"
        ```

13. Repeat steps 2-12 for any remaining PostgreSQL clusters listed in step 1.

### Return to the SAS Deployment Notes

To complete the upgrade to Crunchy Data 5, return to step 5 of the "Update to Crunchy Data 5 for Internal Instances of PostgreSQL" [deployment note](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplynotes&docsetTarget=p1bpcvd3sr8au8n1w9ypcvu31taj.htm#p0wzpjfrqqt8e7n1ark37upbs4t7).

