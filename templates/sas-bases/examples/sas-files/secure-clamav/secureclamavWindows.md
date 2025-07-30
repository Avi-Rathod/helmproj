---
category: SAS Viya File Service
tocprty: 27
---

Secure file service and ClamAV Communication

**Secure File service communication with clamav antivirus**

Currently File service uses [clamav](https://www.clamav.net/) antivirus for scanning uploaded files. File service communicates with clamav over unsecured TCP port set through " **antivirusPort**" property in SAS Environment manager.

This readme describes how to secure file service and clamav communication.

Following example shows four steps for securing the communication.

1. **Set up ClamAV on a Remote Machine**

- Install and configure ClamAV on the remote machine. Reference: <https://docs.clamav.net/>

2. **Obtain an SSL Certificate**

- There are two ways to obtain SSL certificate.
  - Option 1: Get a certificate from a trusted global organization.
    - Option 2: Generate self-signed ssl certificate (see below example)

    ```bash
    sudo apt update
    sudo apt install openssl
    openssl version
    sudo openssl req -new -x509 -days 365 -nodes -out /etc/clamav/ **clamavcert.pem** -keyout /etc/clamav/**clamavkey.pem -subj "/C=US/ST=California/L=Los Angeles/O=My Company Inc/CN=www.example.com" 
       #(you can configure days and subject "-subj" as per your requirements)
      ```

- **Install and Configure a Reverse Proxy on the same Remote Machine**
  - Any of the below option can be used as reverse proxy (sudo permissions might be required)
  - Option 1: - stunnel <https://www.stunnel.org/>

    ```bash
    sudo apt update
    sudo apt install stunnel4
    nano /etc/stunnel/stunnel.conf
    ```

    - Add following in stunnel.conf

    ```plaintext
    [clamav-proxy-service]
    accept = 3311
    connect = 127.0.0.1:3310
    cert = /etc/clamav/clamavcert.pem
    key = /etc/clamav/clamavkey.pem
    ```

    - Restart the stunnel service:

    ```bash
    service stunnel4 restart
    ```

    - Check the status of the stunnel service:

    ```bash
    systemctl status stunnel4.service
    ```

  - Option 2: - Install and configure NGINX <https://www.nginx.com/>

    ```bash
    sudo apt update
    sudo apt install nginx
    sudo nano /etc/nginx/nginx.conf
    ```

    - Add following in nginx.conf

    ```nginx
            stream {
                upstream backend {
                    server 127.0.0.1:3310;
                }
                server {
                    listen 3311 ssl;
                    proxy_pass backend;
                    ssl_certificate /etc/clamav/clamavcert.pem;
                    ssl_certificate_key /etc/clamav/clamavkey.pem;
                    ssl_ciphers HIGH:!aNULL:!MD5;
                    ssl_protocols TLSv1.2 TLSv1.3;
                    proxy_ssl_session_reuse on;
                }
            }
    ```

    - 3310 is the port on which clamav antivirus is listening
    - 3311 is the port where stunnel/nginx listens to incoming scanning request from file service. Please make sure 3311 port is open and listening to external request
    - clamavcert.pem, clamav.key these are either self-signed certificate or made available by trusted global certificate provisioning authority.
    - make sure clamavcert.pem and clamav.key are present in /etc/clamav/ folder

    - Restart the nginx service:

      ```bash
      service nginx restart
      ```

    - Check the status of the nginx service:

      ```bash
      systemctl status nginx.service
      ```

2. **Update your SAS Viya Deployment include the clamav SSL certificate references.**

   - copy **clamavcert.pem** to $charts/uda/security/cacerts/ in the sas viya deployment directory.
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

3. **Configuring SAS Viya file service for secure antivirus communication**

   - In SASEnvironmentManager set following properties in "sas.files.scan.tenant" section
        - antiVirusHost: 10.120.143.84 {{IP address machine where CLAMAV and Stunnel is installed}}
        - antiVirusSSLPort: 3311 {{Secure SSL port where stunnel/nginx is listening}}
   - Save and close the configuration window.

4. **Done**.