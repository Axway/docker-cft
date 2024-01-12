# Axway Transfer CFT Podman

### Prerequisites

- [podman](https://podman.io/getting-started/installation) version 4.3.0 or higher

## How to use the Transfer CFT podman files

This `README` refers to managing single-node installations of Transfer CFT using podman.

The [`podman.yml`](./podman.yml) describes and allows you to configure the Transfer CFT deployment.
The [`secrets.yml`](./secrets.yml) can be used to create the secrets for the Transfer CFT deployment, this file requires modification before being used.

The script [`podman-helper.sh`](./podman-helper.sh) can be used to help managing Transfer CFT.

**Note:** If you change YAML parameter values, adequate values in [`podman-helper.sh`](./podman-helper.sh) before using the script.

> **Tip**: There is also the executable [Podman Compose](https://github.com/containers/podman-compose) that can be used with the YAML files present in the [`compose`](../compose) folder.

### How to use the official Transfer CFT Container image

1) Log in to the Axway Docker registry.

You only need to perform this step for the initial login. If you do not have your Axway service account credentials, you can follow the instructions in [Axway Documentation](https://docs.axway.com/search?q=Installing+Transfer+CFT+in+a+container) to obtain them.

```console
podman login docker.repository.axway.com --username <service_account_client_id>
```

Enter as password, your service_account_client_secret.

2) Log in to [Axway Repository](https://repository.axway.com/).

Use same credentials used for [Axway Support](https://support.axway.com/)

3) Find Transfer CFT official container image in the catalog.

Search for "Transfer CFT DockerImage" and select the appropriate version.

4) Pull Transfer CFT container image:

```console
podman pull docker.repository.axway.com/transfercft-docker-prod/3.10/cft:3.10.2206
```

**Note:** Podman tag can be used to rename/retag the official container image, for example:

```console
podman tag docker.repository.axway.com/transfercft-docker-prod/3.10/cft:3.10.2206 axway/cft:3.10.2206
```

### How to manage the Transfer CFT pod from your podman YAML file

You can use `podman play kube` to automate application deployment and customization.

#### 1. Customization

Before you start, customize the parameters in the [`podman.yml`](./podman.yml) and [`secrets.yml`](./secrets.yml) files.

Set the image parameter to match the image you want to use. For example: "image: axway/cft:3.10.2206".

You must accept the applicable General Terms and Conditions in the [`podman.yml`](./podman.yml) to be able to continue. These are located at [https://www.axway.com/en/legal/contract-documents](https://www.axway.com/en/legal/contract-documents).

You need to add a key for Transfer CFT to start correctly. You can find more information about the key in the section [Transfer CFT license key](#2-transfer-cft-license-key)

If you want your Transfer CFT to be fully functional, you should change the `CFT_FQDN` parameter to reflect the host machine's name in the network (IP address can also be used).

**Note:** You cannot connect to some Transfer CFT interfaces if this parameter is not properly set.

To register Transfer CFT with Flow Manager or Central Governance, set `CFT_CG_ENABLE` to "YES", and configure the `CFT_CG_HOST`, `CFT_CG_PORT`, and `CFT_CG_SHARED_SECRET` parameters.

Customizing other parameters is optional.

##### 1.1 Secrets YAML parameters

The following values can be set using the [`secrets.yml`](./secrets.yml) file. The values after the colon, should be the base64 conversion of the value.
In linux systems, the base64 conversion can be performed as:

```console
echo "value" | base64
```

 **Parameter**              |  **Description**
 -------------------------- | ---------------
cft.key                     | base64 conversion of the key value.
xfbadm.pwd                  | base64 conversion of the XFBADM user's password.
shared_secret               | base64 conversion of the shared secret needed to register with the Central Governance server.
copilot_p12.pwd             | base64 conversion of the Copilot server certificate password.

##### 1.2 Podman YAML parameters

The following parameters are available in the [`podman.yml`](./podman.yml) file. Use these parameters to customize the Transfer CFT container and pod. All values are transmitted to Transfer CFT using environment variables.

In this `README`, Central Governance can represent either Central Governance or Flow Manager.

 **Parameter**              |  **Values**  |  **Description**
 -------------------------- | :----------: | ---------------
ACCEPT_GENERAL_CONDITIONS   |  "YES"/"NO"  |  Set to YES to accept the  General Terms and Conditions. See https://www.axway.com/en/legal/contract-documents
CFT_FQDN                    |  \<string>   |  Host address of the local server.
CFT_LOAD_BALANCER_HOST      |  \<string>   |  Load balancer address (FQDN or IP address) used by Central Governance to connect to Transfer CFT UI server for multinode active/active deployment.
CFT_LOAD_BALANCER_PORT      |  \<number>   |  Load balancer port used by Central Governance to connect to Transfer CFT UI server CFT_COPILOT_CG_PORT port. Used for multinode active/active deployment.
CFT_INSTANCE_ID             |  \<string>   |  Name of the Transfer CFT instance.
CFT_INSTANCE_GROUP          |  \<string>   |  The Transfer CFT instance's group.
CFT_CATALOG_SIZE            |  \<number>   |  Catalog size.
CFT_COM_SIZE                |  \<number>   |  Communication file size.
CFT_PESIT_PORT              |  \<number>   |  Port number of the PeSIT protocol called PESITANY.
CFT_PESITSSL_PORT           |  \<number>   |  Port number of the PeSIT protocol called PESITSSL.
CFT_SFTP_PORT               |  \<number>   |  Port number of the SFTP protocol.
CFT_COMS_PORT               |  \<number>   |  Port number of the synchronous communication media called COMS.
CFT_COPILOT_PORT            |  \<number>   |  Port number for the Transfer CFT UI server that listens for incoming unsecured and secured (SSL) connections.
CFT_COPILOT_CG_PORT         |  \<number>   |  Port number for the Transfer CFT UI server used to connect to Central Governance.
CFT_RESTAPI_PORT            |  \<number>   |  Port number used to connect to the REST API server.
CFT_CG_ENABLE               |  "YES"/"NO"  |  Connectivity with Flow Manager or Central Governance.
CFT_CG_HOST                 |  \<string>   |  Host address of the Central Governance server.
CFT_CG_PORT                 |  \<number>   |  Listening port of the Central Governance server.
CFT_CG_SHARED_SECRET        |  \<string>   |  Shared secret needed to register with the Central Governance server.
CFT_CG_POLICY               |  \<string>   |  Central Governance configuration policy to applied at Transfer CFT registration.
CFT_CG_PERIODICITY          |  \<number>   |  Central Governance interval between notifications.
CFT_CG_AGENT_NAME           |  \<string>   |  Central Governance agent name.
CFT_SENTINEL_ENABLE         |  "YES"/"NO"  |  Connectivity to Sentinel. This shouldn't be used if connectivity with Central Governance activated.
CFT_SENTINEL_HOST           |  \<string>   |  Host address of the Sentinel server.
CFT_SENTINEL_PORT           |  \<number>   |  Listening port of the Sentinel server.
CFT_SENTINEL_SSL            |  "YES"/"NO"  |  Enables SSL cryptography when connecting to Sentinel
CFT_SENTINEL_LOG_FILTER     |  \<string>   |  Sentinel Log Filter: (I)nformation, (W)arning, (E)rror, (F)atal. Authorized characters are I, W, E, F, each used only once.
CFT_SENTINEL_TRANSFER_FILTER|  \<string>   |  Sentinel Transfer Filter. Possible values are: ALL, SUMMARY, NO, ERROR.
CFT_JVM                     |  \<number>   |  Amount of memory that the Secure Relay JVM can use.
CFT_KEY                     |  \<string>   |  A command that returns the Transfer CFT license key.
CFT_CFTDIRRUNTIME           |  \<string>   |  Location of the Transfer CFT runtime.
CFT_MULTINODE_ENABLE        |  "YES"/"NO"  |  Activate multinode architecture.
CFT_MULTINODE_NUMBER        |  \<number>   |  Number of nodes.
CFT_MULTINODE_NODE_PER_HOST |  \<number>   |  Number of Transfer CFT nodes per container. The recommended value is 1. Be sure to have as many or more replicas as the number of nodes.
USER_SCRIPT_INIT            |  \<string>   |  Path to a script executed when you create the container.
USER_SCRIPT_START           |  \<string>   |  Path to a script that executes each time you start the container.
USER_CG_CA_CERT             |  \<string>   |  Central Governance root CA certificate.
USER_SENTINEL_CA_CERT       |  \<string>   |  Sentinel CA certificate.
USER_COPILOT_CERT           |  \<string>   |  Copilot server certificate. It must refer to a PKCS12 certificate.
USER_COPILOT_CERT_PASSWORD  |  \<string>   |  A command that returns the Copilot server certificate password.
USER_XFBADM_LOGIN           |  \<string>   |  Xfbadm user login to create when creating the container. If both `USER_XFBADM_LOGIN` and `USER_XFBADM_PASSWORD` are defined, the corresponding user is added to xfbadmusr database.
USER_XFBADM_PASSWORD        |  \<string>   |  A command that returns the XFBADM user's password.

#### 2. Transfer CFT license key

You require a linux-x86-64 platform key that does not have a specified hostname.

There are 3 ways of setting the key, to use secrets, add the base64 conversion of the key in the [`secrets.yml`](./secrets.yml) file. You can also include a command to access a remote key in CFT_KEY parameter in the [`podman.yml`](./podman.yml) file, you could also put the key value directly in the CFT_KEY parameter in the [`podman.yml`](./podman.yml) file, but this is not recommended.

#### 3. Data persistence

The Transfer CFT [`podman.yml`](./podman.yml) file makes reference to a volume named `cft_data`. This volume is set automatically when the container is created using `podman play kube ./podman.yml` or `podman-helper.sh create`

The Transfer CFT runtime is placed in this volume so it can be reused when creating and starting a new Transfer CFT container. See the Upgrade section for details.

#### 4. Create and start the Transfer CFT pod

From the folder where the podman.yml file is located, run the command:

```console
podman play kube ./secrets.yml
podman play kube ./podman.yml
```

Using the [`podman-helper.sh`](./podman-helper.sh), this would be:

```console
podman-helper.sh create
```

To see the running containers, run:

```console
podman pod ps -f name=cft-pod
```

or

```console
podman-helper.sh status
```

#### 5. Stop and remove the Transfer CFT pod

You can stop the containers using the command:

```console
podman pod stop cft-pod
```

or, from the folder where the [`podman.yml`](./podman.yml) file is located, run the command:

```console
podman-helper.sh stop
```

To remove the pod, run the command:

```console
podman pod rm -f cft-pod
```

or, from the folder where the [`podman.yml`](./podman.yml) file is located, run the command:

```console
podman-helper.sh delete
```

To remove the volume and secrets while deleting the pod, run the command:

```console
podman-helper.sh purge
```

#### 6. Start the Transfer CFT pod

You can start the containers using the command:

```console
podman pod start cft-pod
```

or, from the folder where the [`podman.yml`](./podman.yml) file is located, run the command:

```console
podman-helper.sh start
```

#### 7. Access Transfer CFT directories in the container

For debugging purpose, you can require access to the Transfer CFT container.

Using the container name, run the following command:

```console
podman exec -it cft-pod-cft /bin/bash
```

From within the container you can then run Transfer CFT commands:

```console
axway@cft-pod:~$ pwd
/opt/axway
axway@cft-pod:~$ cd data/runtime/
axway@cft-pod:~/data/runtime$ . ./profile
axway@cft-pod:~/data/runtime$ CFTUTIL ...
```

#### 8. Upgrade Transfer CFT

You can use the upgrade option to change the image used for Transfer CFT without losing Transfer CFT's data (i.e. keep the runtime). This could be useful, for example, if you want to work with a newly released 3.10.2209 instead of the current 3.10.2206, or you want to add some security options to the Linux kernel.

You must first load the new Transfer CFT image in your repository. You can either:
- Use an official Transfer CFT image, as described in the section [How to use the official Transfer CFT Container image](#how-to-use-the-official-transfer-cft-container-image)
- Build a new Transfer CFT image, using the instructions in [`docker/README.md`](../docker/README.md)

##### 1. Export Transfer CFT data

This step is currently mandatory.

```console
curl -k -u user:password -X PUT "https://${CFT_FQDN}:1768/cft/api/v1/cft/container/export" -H "accept: application/json"
```
where user:password refers to the credentials that you use to connect to the UI or the REST API.

Check that the REST API call returns 200.

##### 2. Update the image parameter

Set the image parameter to match the image you want to use. For example: "image: axway/cft:3.10.2206".

##### 3. Stop, remove, recreate and start the pod

To stop and remove the container, run the commands:

```console
podman pod stop cft-pod
podman pod rm -f cft-pod
```

To recreate and start the pod, from the folder where the [`podman.yml`](./podman.yml) file is located, run the command:

```console
podman play kube ./podman.yml
```

These can also be run using the helper:

```console
podman-helper.sh update
```

### Connecting to interfaces

When you start the Transfer CFT container for the first time, if both `USER_XFBADM_LOGIN` and `USER_XFBADM_PASSWORD` are defined, the corresponding user is added to the xfbadmusr database.

When a user is created, the container logs display:
```
Creating user $USER_XFBADM_LOGIN...
User $USER_XFBADM_LOGIN created.
```
Otherwise, the following message displays:
```
WARNING: Password required to create an user. Not creating one!
```

Access the Transfer CFT REST API documentation by connecting to:

```
https://${CFT_FQDN}:1768/cft/api/v1/ui/index.html
```

Access the Transfer CFT UI by connecting to:

```
https://${CFT_FQDN}:1768/cft/ui
```

### Customization

This section explains how to customize the default XFBADM user, the Central Governance SSL CA certificate, the Sentinel SSL CA certificate, the Copilot server SSL certificate, and scripts invoked when creating or starting a container.
To enable customization, you must define a mapped volume that refers to a local directory containing the SSL certificates and/or the user's password files.
For each of the parameters listed in this section, uncoment the corresponding lines in the env, volumes and volumeMounts sections of the podman.yml file.

#### Default XFBADM user

To create an XFBADM user during the container creation, set variables `USER_XFBADM_LOGIN` and `USER_XFBADM_PASSWORD` as follow:
- `USER_XFBADM_LOGIN`: A string that refers to the login.
- `USER_XFBADM_PASSWORD`: A command that returns the XFBADM user's password.

For details, see `USER_XFBADM_PASSWORD` in the [`podman.yml`](./podman.yml) and xfbadm.pwd in the [`secrets.yml`](./secrets.yml).

#### SSL Certificates

To specify your SSL certificates as a Central Governance CA certificate, a Sentinel CA certificate, and a Copilot server certificate, use the following parameters:
- `USER_CG_CA_CERT`: The path to the Central Governance CA certificate.
- `USER_SENTINEL_CA_CERT`: The path to the Sentinel CA certificate.
- `USER_COPILOT_CERT`: The path to the Copilot server certificate. It must refer to a PKCS12 certificate.
- `USER_COPILOT_CERT_PASSWORD`: A command that returns the Copilot server certificate password.

For example:
- podman.yaml:
```
spec:
  containers:
    - name: cft
      env:
        - name: USER_CG_CA_CERT
          value: "/run/secrets/cg_ca_cert.pem"
        - name: USER_SENTINEL_CA_CERT
          value: "/run/secrets/sentinel_ca_cert.pem"
        - name: USER_COPILOT_CERT
          value: "/run/secrets/copilot.p12"
        - name: USER_COPILOT_CERT_PASSWORD
          value: "base64 -d /run/cft_secrets/copilot_p12.pwd"
      volumeMounts:
        - name: cg_ca_cert.pem
          readOnly: true
          mountPath: /run/secrets/cg_ca_cert.pem
        - name: sentinel_ca_cert.pem
          readOnly: true
          mountPath: /run/secrets/sentinel_ca_cert.pem
        - name: copilot.p12
          readOnly: true
          mountPath: /run/secrets/copilot.p12
  volumes:
    - name: cg_ca_cert.pem
      hostPath:
        path: ./conf/cg_ca_cert.pem
        type: File
    - name: sentinel_ca_cert.pem
      hostPath:
        path: ./conf/sentinel_ca_cert.pem
        type: File
    - name: copilot.p12
      hostPath:
        path: ./conf/copilot.p12
        type: File
```

- secrets.yaml:
```
data:
  copilot_p12.pwd : XXXXXXX

```


If one of the specified certificates has changed, when the container starts it is automatically updated so that the container always uses last certificate mapped in the container from the host directory.

#### Custom scripts

The `USER_SCRIPT_INIT` and `USER_SCRIPT_START` parameters let you specify, respectively, a script that executes when the container is created, and another that executes each time the container starts.

For example:

```
spec:
  containers:
    - name: cft
      env:
        - name: USER_SCRIPT_INIT
          value: "/opt/app/custom/init.sh"
        - name: USER_SCRIPT_START
          value: "/opt/app/custom/startup.sh"
      volumeMounts:
        - name: custom
          mountPath: /opt/app/custom/
  volumes:
    - name: custom
      hostPath:
        path: ./custom
        type: Directory
```

## Copyright

Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.
