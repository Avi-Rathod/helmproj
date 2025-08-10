---
category: siteDefaultFile
tocprty: 1
---

# Modify the sitedefault.yaml File

## Overview

The sitedefault.yaml file specifies configuration properties that will be
written to the Consul key value store when the sas-consul-server is started.

Each property in the sitedefault.yaml file will be written to the Consul key
value store if it does not already exist.

Example:

The following properties specify the configuration for the LDAP provider and
base points from which to search for groups and users.

```yaml
- sas.identities.providers.ldap:
    - connection:
      - host: ldap.example.com
      - password:
      - port: 3269
      - url: ldaps://${sas.identities.providers.ldap.connection.host}:${sas.identities.providers.ldap.connection.port}
      - userDN: cn=AdminUser,dn=example,dn=com
    - group:
      - baseDN: ou=groups,dc=example,dn=com
    - user:
      - baseDN: DC=example,DC=com
```

## Instructions

**Caution:** The example requires a value for a password. Due to security 
concerns for providing a value for the required password field, an alternative 
method is described. Using the sitedefault file to set LDAP properties is not 
required because an administrator can set the LDAP connection using SAS 
Environment Manager.   

1. Copy the sitedefault.yaml file from `$deploy/sas-bases/examples/configuration`
to the site-config directory.

2. In the file you just copied, provide the values you want to use for your
deployment as described in the "Properties" section below.

3. After you have entered the values for your deployment, revise the base
kustomization.yaml file as described in ["Add a sitedefault File to Your Deployment"](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm&locale=en#n19f4zubzxljtdn12lo0nkv4n4cf).

**Note:** There will be an LDAP AuthenticationException in the log for the 
identities service. It can be safely ignored if you follow the remaining steps.

4. Log in to SAS Environment Manager as sasboot. 

5. Using SAS Environment Manager, replace the temporary values you used for the
ldap.connection password and userDN with real values.

6. When the changes are picked up by SAS Environment Manager, select the SAS 
Administrators group under Custom Groups to see the LDAP users. You can add any 
LDAP user that is listed as an administrator.

7. Log out of SAS Environment Manager and log back in as a user that was added 
in step 6. Use that user to get administrator privileges.

## Properties
This section describes the properties associated with Lightweight Directory
Access Protocol (LDAP) that can be specified in the sitedefault.yaml file.
Any required properties must have a value specified in order to have their 
defaults applied.

For information about all the properties that can be configured in the
sitedefault.yaml file, see ["Configuration Properties: Reference (Services)"](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calconfigref&docsetTarget=n1wpcytddbiu6in1blfiul3bnh19.htm&locale=en).

### Lightweight Directory Access Protocol (LDAP)
The set of properties that are used to configure the LDAP provider.

#### sas.identities.providers.ldap.connection
The set of properties that are used to configure the connection to the LDAP provider.

##### host
The LDAP server's host name.

Example: `ldap.example.com`

##### password
The password for logging on to the LDAP server.

Example: `tempPassword`

**Caution:** SAS recommends setting the password to a temporary string,
such as tempPassword. See the [Instructions](#instructions) for post-deployment steps to insert a real password.

##### port
The LDAP server's port.

Example: `3269`

##### url
The URL for connecting to the LDAP server.

Example: `ldaps://${sas.identities.providers.ldap.connection.host}:${sas.identities.providers.ldap.connection.port}`

##### userDN
The distinguished name (DN) of the user account for logging on to the LDAP server.

Example: `tempUser`

**Caution:** SAS recommends setting the userDN to a temporary string,
such as tempUser. See the [Instructions](#instructions) for post-deployment steps to insert a real userDN.


#### sas.identities.providers.ldap.group
The set of properties that are used to configure information for retrieving group information from the LDAP provider.

##### baseDN
The point from which the LDAP server searches for groups.

Example: `ou=groups,dc=example,dn=com`


#### sas.identities.providers.ldap.user
The set of properties that are used to configure additional information for retrieving user information from the LDAP
provider.

##### baseDN
The point from which the LDAP server searches for users.

Example: `DC=example,DC=com`

## Additional Resources
For more information about the sitedefault.yaml file, see ["Add a sitedefault File to Your Deployment"](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm&locale=en#n19f4zubzxljtdn12lo0nkv4n4cf).