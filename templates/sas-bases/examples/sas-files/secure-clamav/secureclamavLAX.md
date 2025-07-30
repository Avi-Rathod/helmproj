---
category: SAS Viya File Service
tocprty: 25
---

Secure File service communication with clamav antivirus

Currently File service uses [clamav](https://www.clamav.net/) antivirus for scanning uploaded files. File service communicates with clamav over unsecured TCP port set through "**antivirusPort**" property in SAS Environment manager.

This readme describes how to secure file service and clamav communication.

Following example shows five steps for securing the communication.

1. **Set up ClamAV on a Remote Machine**
   1. Install and configure ClamAV on the remote machine. Reference: - <https://www.clamav.net/>
2. **Obtain an SSL Certificate**
   - There are two ways to obtain SSL certificate.
      - Option 1: Get a certificate from a trusted global organization.
      - Option 2: Generate self-signed ssl certificate (see below example)
         - Please make sure you have openssl installed on the machine
            - In power shell as Administrator run following (choco should be installed if not available)
               - choco install openssl
         - In power shell run below command

            ```powershell
                openssl req -new -x509 -days 365 -nodes -out **clamavcert.pem** -keyout **clamavkey.pem -subj "/C=US/ST=California/L=Los Angeles/O=My Company Inc/CN=www.example.com"
                #(**you can configure days and subject “-subj” as per your requirements**)**
            ```

3. **Install and Configure a Reverse Proxy on the same Remote Machine**
   - Any of the below option can be used as reverse proxy
     - Option1: Stunnel
       - Download and install stunnel from <https://www.stunnel.org/> for windows platform.
       - Add following in path/to/stunnel-installation/stunnel/config/stunnel.conf (the path should point to where clamavcert.pem and clamavkey.pem are present.)

        ```plaintext
        [clamav-proxy-service]
        accept = 3311
        connect = 127.0.0.1:3310
        cert = /path/to/clamavcert.pem
        key = /path/to/clamavkey.pem
        ```

       - Reload stunnel configurations from stunnel ui
     - Option 2: - NGINX
       - Download and install nginx <https://www.nginx.com/>
       - Add following in nginx.conf

            ```nginx
            stream {
                upstream backend {
                server 127.0.0.1:3310;
                }

                server {
                listen 3311 ssl;
                proxy_pass backend;
                ssl_certificate /path/to/clamavcert.pem;
                ssl_certificate_key /path/to/clamavkey.pem;
                ssl_ciphers HIGH:!aNULL:!MD5;
                ssl_protocols TLSv1.2 TLSv1.3;
                proxy_ssl_session_reuse on;
                }
            }
            ```

       - Start the nginx service
       - 3310 is the port on which clamav antivirus is listening
       - 3311 is the port where stunnel/nginx listens to incoming scanning request from file service. Please make sure 3311 port is open and listening to external request
       - clamavcert.pem,clamav.key these are either self-signed  certificate or made available by trusted global certificate provisioning authority.
4. Update your SAS Viya Deployment include the clamav SSL certificate references.
   - copy clamavcert.pem to $charts/uda/security/cacerts/ in the sas viya deployment directory.
   - Got to $charts/uda/security/
   - Edit customer-provided-ca-certificates.yaml append "- uda/security/cacerts/clamavcert.pem" in files section
   - example

   ```yaml
   apiVersion: builtin
   kind: ConfigMapGenerator
   metadata:
   name: sas-customer-provided-ca-certificates
   behavior: merge
   files:
    - uda/security/cacerts/digicert-chain.crt
    - uda/security/cacerts/chain.crt
    - uda/security/cacerts/clamavcert.pem
   ```

   - kustomize build . | kubectl apply -f –
5. **Configuring SAS Viya file service for secure antivirus communication**
   - In SASEnvironmentManager set following properties in “sas.files.scan.tenant” section
     - antiVirusHost: 10.120.143.84 {{IP address machine where CLAMAV and Stunnel is installed}}
     - antiVirusSSLPort: 3311 {{Secure SSL port where stunnel/nginx is listening}}
   - Save and close the configuration window.
6. Done.