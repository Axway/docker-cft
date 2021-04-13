# AMPLIFY Transfer CFT Docker Compose

AMPLIFY Transfer CFT Docker image

## Before you begin

This document assumes a basic understanding of core Docker concepts such as containers, container images, and basic Docker commands.
If needed, see [Get started with Docker](https://docs.docker.com/get-started/) for a primer on container basics or [Docker Compose Overview](https://docs.docker.com/compose/) for details on using Docker Compose.

### Prerequisites

- Docker version 17.11 or higher
- Docker Compose version 1.17.0 or higher

## How to use the Transfer CFT docker-compose.yml files

The docker-compose.yml describes and allows the management of the Transfer CFT service.
The docker-compose-multinode.yml describes the Transfer CFT service in a multinode environment, and allows management of a scalable Transfer CFT service.

You can use the ../docker/Dockerfile to build your own Transfer CFT image or use the official Axway Transfer CFT Docker image.

### docker-compose parameters

The following parameters are available in the Dockerfile and docker-compose.yml files. Use these parameters to customize the Transfer CFT image and service. The values can be a string, number, or null.
  
 **Parameter**              |  **Values**  |  **Description**
 -------------------------- | :----------: | --------------- 
CFT_FQDN                    |  \<string>   |  Host address of the local server.
CFT_LOAD_BALANCER_HOST      |  \<string>   |  Load balancer address (FQDN or IP address) used by Central Governance to connect to Transfer CFT UI Server for multinode active/active deployment.
CFT_LOAD_BALANCER_PORT      |  \<number>   |  Load balancer port used by Central Governance to connect to Transfer CFT UI Server CFT_COPILOT_CG_PORT port. Used for multinode active/active deployment.
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
CFT_CG_ENABLE               |  "YES"/"NO"  |  Connectivity with Central Governance.
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
CFT_SENTINEL_LOG_FILTER     |  \<string>   |  Sentinel Log Filter: (I)nformation, (W)arning, (E)rror, (F)atal. Authorized characters are only I, W, E, F. Each of them only once.
CFT_SENTINEL_TRANSFER_FILTER|  \<string>   |  Sentinel Transfer Filter. Possible values are: ALL, SUMMARY, NO, ERROR.
CFT_JVM                     |  \<number>   |  Amount of memory that the Secure Relay JVM can use.
CFT_KEY                     |  \<string>   |  A command that returns the Transfer CFT license key.
CFT_CFTDIRRUNTIME           |  \<string>   |  Location of the Transfer CFT runtime.
CFT_MULTINODE_ENABLE        |  "YES"/"NO"  |  Activate multinode architecture.
CFT_MULTINODE_NUMBER        |  \<number>   |  Number of nodes.
CFT_MULTINODE_NODE_PER_HOST |  \<number>   |  Number of CFT nodes per container. The recommended value is 1. Be sure to have as many or more replicas as the number of nodes.
USER_SCRIPT_INIT            |  \<string>   |  Path to a script executed when you create the container.
USER_SCRIPT_START           |  \<string>   |  Path to a script that executes each time you start the container.
USER_CG_CA_CERT             |  \<string>   |  Central Governance root CA certificate.
USER_SENTINEL_CA_CERT       |  \<string>   |  Sentinel CA certificate.
USER_COPILOT_CERT           |  \<string>   |  Copilot server certificate. It must refer to a PKCS12 certificate.
USER_COPILOT_CERT_PASSWORD  |  \<string>   |  A command that returns the Copilot server certificate password.
USER_XFBADM_LOGIN           |  \<string>   |  Login of the xfbadm user to create at container creation. If both USER_XFBADM_LOGIN and USER_XFBADM_PASSWORD are defined, the corresponding user is added to xfbadmusr database.
USER_XFBADM_PASSWORD        |  \<string>   |  A command that returns the XFBADM user's password.

### How to use the official Transfer CFT Docker image

1) Download the Transfer CFT DockerImage from [Axway Support](https://support.axway.com/).

2) Load the image.

From the folder where the Transfer_CFT_3.8_DockerImage_linux-x86-64_BN13377000.tar.gz is located, run the command:

```console
docker image load -i Transfer_CFT_3.8_DockerImage_linux-x86-64_BN13377000.tar.gz
```

4) Check that the image is successfully loaded.

Run the command:

```console
docker images --filter reference=cft/cft
```

You should get an output like:
```console

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
cft/cft             3.8                 c6cb57d34461        18 hours ago        506MB
```

### How to manage the Transfer CFT service from your docker-compose.yml file

You can use Docker Compose to automate building container images, as well as application deployment and customization.

#### 1. Customization

Before you start, customize the parameters in the docker-compose.yml.

Set the image parameter to match the image you want to use. For example: "image: cft/cft:3.8".

If you want your Transfer CFT to be fully functional, you should change the CFT_FQDN variable to reflect the actual host machine’s address.  
**ATTENTION:** You cannot connect to an interface if this parameter is incorrect.

If you want to register Transfer CFT with Central Governance, set CFT_CG_ENABLE to "YES", and configure the CFT_CG_HOST, CFT_CG_PORT, and CFT_CG_SHARED_SECRET parameters.

Customizing other parameters is optional.

#### 2. Transfer CFT license key

Enter your Transfer CFT license key in the conf/license-key file. You need a license for the linux-x86-64 platform. The hostname defined for the key must match the hostname value set in the docker-compose.yml file.

**Note**: The default value for hostname in docker-compose.yml is docker0, if you do not change this, this is the value you should use for your key.

#### 3. Data persistence

The Transfer CFT docker-compose.yml file defines a volume as a mechanism for persisting data generated and used by Transfer CFT.  
The Transfer CFT runtime is placed in this volume so it can be reused when creating and starting a new Transfer CFT container. See the Upgrade section for details.

You can change the volume configuration to use a previously created volume, as described in [Volumes configuration reference](https://docs.docker.com/compose/compose-file/#volume-configuration-reference) and [Create and manage volumes](https://docs.docker.com/storage/volumes/#create-and-manage-volumes).

#### 4. Create and start the Transfer CFT service

From the folder where the docker-compose.yml file is located, run the command:

```console  
docker-compose up  
```

The `up` command builds (if needed), recreates, starts, and attaches to a container for services.  
Unless they are already running, this command also starts any linked services.

You can use the -d option to run containers in the background.

```console  
docker-compose up -d  
```

You can use the -V option to recreate anonymous volumes instead of retrieving data from the previous containers.

```console
docker-compose up -V
```

Run the `docker ps` command to see the running containers.

```console
docker ps
```

#### 5. Stop and remove the Transfer CFT service

From the folder where the docker-compose.yml file is located, you can stop the containers using the command:

```console
docker-compose down
```

The `down` command stops containers, and removes containers, networks, anonymous volumes, and images created by `up`.  
You can use the -v option to remove named volumes declared in the `volumes` section of the Compose file, and anonymous volumes attached to containers.

#### 6. Start the Transfer CFT service

From the folder where the docker-compose.yml file is located, you can start the Transfer CFT service using `start` if it was stopped using `stop`.

```console
docker-compose start
```

#### 7. Stop the Transfer CFT service

From the folder where the docker-compose.yml file is located, you can stop the containers using the command:

```console
docker-compose stop
```

#### 8. Upgrade Transfer CFT

It is possible to change the image used for Transfer CFT without losing Transfer CFT's data (i.e. keep the runtime) using the upgrade option. This could be useful, for example, if you want to work with a newly released SP2 instead of the current SP1, or you want to add some security options to the Linux kernel.

You must first load the new Transfer CFT image in your repository. You can either:
- Use an official Transfer CFT image, as describe in the section "How to use the official Transfer CFT Docker image"
- Build a new Transfer CFT image, using the instructions in ../docker/README.md
   
Upgrade as follows:
   
##### 1. Update the image parameter

Set the image parameter to match the image you want to use. For example: "image: cft/cft:3.8".

##### 2. Export the Transfer data (optional)

This step is only mandatory if you upgrade to a new major release of Transfer CFT.

```console
curl -k -u user:password -X PUT "https://10.110.173.125:1768/cft/api/v1/cft/container/export" -H "accept: application/json"
```
Check that the REST API call returns 200.

##### 3. Stop and remove the container

To stop and remove the container, run the command:

```console
docker-compose down
```

##### 4. Recreate and start the Transfer CFT service

From the folder where the docker-compose.yml is located, run the command:

```console
docker-compose up
```

This command recreates and starts a Transfer CFT container based on the new image. When the container starts, it detects the exported data and imports it during startup.


### Multinode architecture

There are two ways of configuring the Transfer CFT in multinode architecture using docker-compose.

#### Multinode on a Docker cluster

In this use case, all the Transfer CFT nodes run in the same Docker cluster and the scale command from docker-compose defines the number of nodes to start.

The file docker-compose-multinode.yml is written considering this case. Using the list described [here](#docker-compose-parameters) you can change the parameters as needed.

The information presented in topics from [Customization](#1-customization) through [Data persistence](#3-data persistence) are valid in this case.

**NOTE:** You need to change the file nginx.conf to integrate the desired number of nodes.

##### 1. Create and start the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, run the command:

```console  
docker-compose -f docker-compose-multinode.yml up --scale cft=<NUMBER OF NODES>
```
Where NUMBER_OF_NODES should have the same value as CFT_MULTINODE_NUMBER inside the docker-compose-multinode.yaml file.

The `up` command builds (if needed), recreates, starts, and attaches to a container for services.  
Unless they are already running, this command also starts any linked services.

You can use the -d option to run containers in the background.

```console  
docker-compose -f docker-compose-multinode.yml up --scale cft=<NUMBER OF NODES> -d  
```
##### 2. Stop and remove the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, you can stop the containers using the command:

```console
docker-compose -f docker-compose-multinode.yml down
```

The `down` command stops containers, and removes containers, networks, anonymous volumes, and images created by `up`.  
You can use the -v option to remove named volumes declared in the `volumes` section of the Compose file, and anonymous volumes attached to containers.

##### 3. Start the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, you can start the Transfer CFT service using `start` if it was stopped using `stop`.

```console
docker-compose -f docker-compose-multinode.yml start
```

##### 4. Stop the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, you can stop the containers using the command:

```console
docker-compose -f docker-compose-multinode.yml stop
```

##### 5. Upgrade Transfer CFT

It is possible to change the image used for Transfer CFT without losing Transfer CFT's data (i.e. keep the runtime) using the upgrade option. This could be useful, for example, if you want to work with a newly released SP2 instead of the current SP1, or you want to add some security options to the Linux kernel.

You must first load the new Transfer CFT image in your repository. You can either:
- Use an official Transfer CFT image, as describe in the section "How to use the official Transfer CFT Docker image"
- Build a new Transfer CFT image, using the instructions in ../docker/README.md
   
Upgrade as follows:
   
###### 1. Update the image parameter

Set the image parameter to match the image you want to use. For example: "image: cft/cft:3.8".

###### 2. Export the Transfer data (optional)

This step is only mandatory if you upgrade to a new major release of Transfer CFT.

```console
curl -k -u user:password -X PUT "https://10.110.173.125:1768/cft/api/v1/cft/container/export" -H "accept: application/json"
```
Check that the REST API call returns 200.

###### 3. Stop and remove the container

To stop and remove the container, run the command:

```console
docker-compose -f docker-compose-multinode.yml down
```

###### 4. Recreate and start the Transfer CFT service

From the folder where the docker-compose-multinode.yml is located, run the command:

```console
docker-compose -f docker-compose-multinode.yml up --scale cft=<NUMBER OF NODES>
```

This command recreates and starts a Transfer CFT container based on the new image. When the container starts, it detects the exported data and imports it during startup.

**NOTE:** This command should use the same NULBER_OF_NODES previously used.


#### Multinode on multiple standalone Docker servers

In this set-up, different Docker servers will be used to run each of the Transfer CFT containers.

The file docker-compose-multinode.yml need to be changed to adapt do this case and there are a few prerequisites to make it work.

Prerequisites:

1. External load-balancer;
2. External NFS shared disk.

The modifications are:

1. NGINX wont be used, so the block for service nginx should be removed from file docker-compose-multinode.yml;
2. CFT_LOAD_BALANCER_HOST and CFT_LOAD_BALANCER_PORT should be set to refflect the load balancer information;
3. CFT_FQDN should be set using the host machine information, this should change from each of the host machines;
4. You need to add `- "33000-33100"` to the expose section of file docker-compose-multinode.yml;
5. You need to define the Transfer CFT's listening port range, according to the port range set in the previous step. For that, you must set up a custom initialization script using the parameter USER_SCRIPT_INIT. The script must contain the following lines:
```console
. $CFT_CFTDIRRUNTIME/profile
CFTUTIL uconfset id=cft.multi_node.listen_port_range, value="33000-33100"
```

After that, using the list described [here](#docker-compose-parameters) you can change the parameters as needed.

The information presented in topics from [Customization](#1-customization) and [License Key](#2-transfer-cft-license-key) are valid in this case.

##### 1. Data persistence

Transfer CFT volume should point to a NFS disk. The volumes section of file docker-compose-multinode.yml should look like:

```console
volumes:
  cft_data:
    driver: local
    driver_opts:
      type: "nfs4"
      o: "addr=[YOUR_EFS_DNS],nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,cto,nointr,lock,async"
      device: "[YOUR_EFS_DNS]:/"
```

##### 2. Create and start the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, on each Docker server, run the command:

```console  
docker-compose -f docker-compose-multinode.yml up
```

The `up` command builds (if needed), recreates, starts, and attaches to a container for services.  
Unless they are already running, this command also starts any linked services.

You can use the -d option to run containers in the background.

```console  
docker-compose -f docker-compose-multinode.yml up -d  
```
##### 2. Stop and remove the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, on each Docker server, you can stop the containers using the command:

```console
docker-compose -f docker-compose-multinode.yml down
```

The `down` command stops containers, and removes containers, networks, anonymous volumes, and images created by `up`.  
You can use the -v option to remove named volumes declared in the `volumes` section of the Compose file, and anonymous volumes attached to containers.

##### 3. Start the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, on each Docker server, you can start the Transfer CFT service using `start` if it was stopped using `stop`.

```console
docker-compose -f docker-compose-multinode.yml start
```

##### 4. Stop the Transfer CFT service

From the folder where the docker-compose-multinode.yml file is located, on each Docker server, you can stop the containers using the command:

```console
docker-compose -f docker-compose-multinode.yml stop
```

##### 5. Upgrade Transfer CFT

It is possible to change the image used for Transfer CFT without losing Transfer CFT's data (i.e. keep the runtime) using the upgrade option. This could be useful, for example, if you want to work with a newly released SP2 instead of the current SP1, or you want to add some security options to the Linux kernel.

You must first load the new Transfer CFT image in your repository. You can either:
- Use an official Transfer CFT image, as describe in the section "How to use the official Transfer CFT Docker image"
- Build a new Transfer CFT image, using the instructions in ../docker/README.md
   
Upgrade as follows:
   
###### 1. Update the image parameter

Set the image parameter to match the image you want to use. For example: "image: cft/cft:3.8".

###### 2. Export the Transfer data (optional)

This step is only mandatory if you upgrade to a new major release of Transfer CFT, and should be executed only once.

```console
curl -k -u user:password -X PUT "https://10.110.173.125:1768/cft/api/v1/cft/container/export" -H "accept: application/json"
```
Check that the REST API call returns 200.

###### 3. Stop and remove the container

To stop and remove the container, run the command, on each Docker server:

```console
docker-compose -f docker-compose-multinode.yml down
```

###### 4. Recreate and start the Transfer CFT service

From the folder where the docker-compose-multinode.yml is located, on each Docker server, run the command:

```console
docker-compose -f docker-compose-multinode.yml up
```

This command recreates and starts a Transfer CFT container based on the new image. When the container starts, it detects the exported data and imports it during startup.


### Connecting to interfaces

When you start the Transfer CFT container for the first time, if both USER_XFBADM_LOGIN and USER_XFBADM_PASSWORD are defined, the corresponding user is added to xfbadmusr database.

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
https://CFT_FQDN:1768/cft/api/v1/ui/index.html
```

Access the Transfer CFT UI by connecting to:

```
https://CFT_FQDN:1768/cft/ui
```

Access the former Transfer CFT UI (Copilot UI) by connecting to:

```
http://CFT_FQDN:1766/index.html
```

**NOTE:** When using multinode, instead of CFT_FQDN, the load balancer address should be used.

### Customization

This section explains how to customize the default XFBADM user, the Central Governance SSL CA certificate, the Sentinel SSL CA certificate, the Copilot server SSL certificate, and scripts invoked when creating or starting a container.
To enable customization, you must define a mapped volume that refers to a local directory containing the SSL certificates and/or the user's password files.
In this example, the directory '/opt/app/custom' in the container maps the local directory './custom'. The mapped directory '/opt/app/custom' is in read-only mode.

```
volumes:
  - ./custom:/opt/app/custom:ro
```

#### Default XFBADM user

To create an XFBADM user during the container creation, set variables USER_XFBADM_LOGIN and USER_XFBADM_PASSWORD as follow:
- USER_XFBADM_LOGIN: A string that refers to the login.
- USER_XFBADM_PASSWORD: A command that returns the password such as 'cat userpassword.txt', where the file, for example userpassword.txt, contains the password.

For more details, see USER_XFBADM_PASSWORD in the docker-compose.yml.

#### SSL Certificates

To specify your SSL certificates as a Central Governance CA certificate, a Sentinel CA certificate, and a Copilot server certificate, use the following variables:
- USER_CG_CA_CERT: The path to the Central Governance CA certificate.
- USER_SENTINEL_CA_CERT: The path to the Sentinel CA certificate.
- USER_COPILOT_CERT: The path to the Copilot server certificate. It must refer to a PKCS12 certificate.
- USER_COPILOT_CERT_PASSWORD: A command that returns the Copilot server certificate password. If the password is stored in a file named copilot_p12.pwd, the USER_COPILOT_CERT_PASSWORD value is 'cat copilot_p12.pwd'.

For example:
```
service:
    cft:
        environment:
            USER_CG_CA_CERT:            "/run/secrets/cg_ca_cert.pem"
            USER_SENTINEL_CA_CERT:      "/run/secrets/sentinel_ca_cert.pem"
            USER_COPILOT_CERT:          "/run/secrets/copilot.p12"
            USER_COPILOT_CERT_PASSWORD: "cat /run/secrets/copilot_p12.pwd"
secrets:
    cg_ca_cert.pem:
        file: ./conf/cg_ca_cert.pem
    sentinel_ca_cert.pem:
        file: ./conf/sentinel_ca_cert.pem
    copilot.p12:
       file: ./conf/copilot.p12
    copilot_p12.pwd:
        file: ./conf/copilot_p12.pwd
```

If one of the specified certificates has changed, when the container starts it is automatically updated so that the container always uses the certificate located in the local directory.

#### Custom scripts

The USER_SCRIPT_INIT and USER_SCRIPT_START variables let you specify, respectively, a script that executes when the container is created, and another that executes each time the container starts.

For example:

```
service:
    cft:
        environment:
            USER_SCRIPT_INIT:   "/opt/app/custom/init.sh"
            USER_SCRIPT_START:  "/opt/app/custom/startup.sh"
```

## Copyright

Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.
