---
category: deployOperator
tocprty: 5
---

# Disassociate a SAS Viya Platform Deployment from the SAS Viya Platform Deployment Operator

To remove SAS Viya Platform Deployment Operator management of updates to a SAS
Viya platform deployment, you must disassociate the deployment from the
SASDeployment custom resource and then delete the SASDeployment custom resource.
The
`$deploy/sas-bases/examples/deployment-operator/disassociate/disassociate-deployment-operator.sh`
script performs these actions.

Running the script requires `bash`, `kubectl`, and `jq`. SAS recommends that you
save the current SASDeployment custom resource before executing the script
because the script deletes it.

First, make the script executable with the following command.

```bash
chmod 755 ./disassociate-deployment-operator.sh
```

Then execute the script, specifying the namespace which contains the
SASDeployment custom resource.

```bash
./disassociate-deployment-operator.sh <name-of-namespace>
```

The script removes the SASDeployment ownerReference from the `.metadata.
ownerReferences` field and the
`kubectl.kubernetes.io/last-applied-configuration` annotation in all resources
in the namespace. It then removes the SASDeployment custom resource. The SAS
Viya platform deployment is otherwise unchanged.

**Note:** Running the disassociate script might cause the following message to be displayed.
This message can be safely ignored.

```bash
Warning: path <API-path-for-URLs> cannot be used with pathType Prefix
```

If you want to use the SAS Viya Platform Deployment Operator for this SAS Viya
platform deployment in the future, a SASDeployment custom resource can be
reintroduced into the namespace. See the [SAS Viya Platform: Deployment
Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
for details.

