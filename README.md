# AMPLIFY Transfer CFT Docker

AMPLIFY Transfer CFT 3.5 Docker image

## Content
- Dockerfile: Transfer CFT 3.5 Generate the Docker image with Ubuntu

## Before you begin

This document assumes a basic understanding of core Docker concepts such as containers, container images, and basic Docker commands.
If needed, see [Get started with Docker](https://docs.docker.com/get-started/) for a primer on container basics.

### Prerequisites

- Docker version 17.11 or higher
- Docker-Compose version 1.17.0 or higher

## How to use the Transfer CFT Dockerfile and docker-compose.yml files

The Dockerfile contains all commands required to assemble a Transfer CFT image. The docker-compose.yml describes the Transfer CFT service. This file allows management of the Transfer CFT service.

### Dockerfile and docker-compose.yml parameters

The following parameters are available in the Dockerfile and docker-compose.yml files. Use these parameters to customize the Transfer CFT image and service. The values can be a string, number, or null.
  
 **Parameter**             |  **Values**  |  **Description**
 ------------------------- | :----------: | --------------- 
CFT_FQDN                   |  \<string>   |  Host address of the local server.
CFT_INSTANCE_ID            |  \<string>   |  Name of the Transfer CFT instance.
CFT_INSTANCE_GROUP         |  \<string>   |  The Transfer CFT instance's group.
CFT_CATALOG_SIZE           |  \<number>   |  Catalog size.
CFT_COM_SIZE               |  \<number>   |  Communication file size.
CFT_PESIT_PORT             |  \<number>   |  Port number of the PeSIT protocol called PESITANY.
CFT_PESITSSL_PORT          |  \<number>   |  Port number of the PeSIT protocol called PESITSSL.
CFT_COMS_PORT              |  \<number>   |  Port number of the synchronous communication media called COMS.
CFT_COPILOT_PORT           |  \<number>   |  Port number for the Transfer CFT UI server that listens for incoming unsecured and secured (SSL) connections.
CFT_COPILOT_CG_PORT        |  \<number>   |  Port number for the Transfer CFT UI server used to connect to Central Governance.
CFT_RESTAPI_PORT           |  \<number>   |  Port number used to connect to the REST API server.
CFT_CG_ENABLE              |  "YES"/"NO"  |  Connectivity with Central Governance.
CFT_CG_HOST                |  \<string>   |  Host address of the Central Governance server.
CFT_CG_PORT                |  \<number>   |  Central Governance port on which the connector connects.
CFT_CG_SHARED_SECRET       |  \<string>   |  Shared secret needed to register with the Central Governance server.
CFT_CG_POLICY              |  \<string>   |  Central Governance policy, which is a set of defined parameters.
CFT_CG_PERIODICITY         |  \<number>   |  Central Governance interval between notifications.
CFT_JVM                    |  \<number>   |  Amount of memory that the Secure Relay JVM can use.
CFT_KEY                    |  \<string>   |  A command that returns the Transfer CFT license key.
CFT_CFTDIRRUNTIME          |  \<string>   |  Location of the Transfer CFT runtime.
USER_SCRIPT_INIT           |  \<string>   |  Path to a script executed when you create the container.
USER_SCRIPT_START          |  \<string>   |  Path to a script that executes each time you start the container.
USER_CG_CA_CERT            |  \<string>   |  Central Governance CA certificate.
USER_SENTINEL_CA_CERT      |  \<string>   |  Sentinel CA certificate.
USER_COPILOT_CERT          |  \<string>   |  Copilot server certificate. It must refer to a PKCS12 certificate.
USER_COPILOT_CERT_PASSWORD |  \<string>   |  A command that returns the Copilot server certificate password.
USER_XFBADM_LOGIN          |  \<string>   |  The XFBADM user login, which is created when you create the container.
USER_XFBADM_PASSWORD       |  \<string>   |  A command that returns the XFBADM user's password.

### How to build the Docker image

#### 1. Build the Docker image from your Dockerfile

##### 1.1. Offline Build

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/)

The Dockerfile is compatible with Transfer CFT 3.5 base version and its updates.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64.

2) Build the Docker image from your Dockerfile

From the folder where the Dockerfile is located, using the downloaded package as a build argument, run the command:
```console
docker build --build-arg INSTALL_KIT=Transfer_CFT_3.5_Install_linux-x86-64_BN12603000.zip -t cft/cft:3.5 .
```

##### 1.2. Online Build

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/)

The Dockerfile is compatible with Transfer CFT 3.5 base version and its updates.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64 and make it available in your network.

2) Build the Docker image from your Dockerfile

From the folder where the Dockerfile is located, run the command:

```console
docker build --build-arg URL_BASE=https://network.package.location/ -t cft/cft:3.5 .
```
*Note* You can customize the VERSION_BASE, RELEASE_BASE arguments from the Dockerfile to build a Docker image based on a different Transfer CFT version/level.

#### 2. Check that the Docker image is successfully created

Run the command:

```console
docker images --filter reference=cft/cft
```

You should get an output like:
```console

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
cft/cft           3.5                 6049bb6d4d17        3 days ago          622MB
```


### How to manage the Transfer CFT service from your docker-compose.yml file

You can use docker-compose to automate building container images, as well as application deployment and customization.

#### 1. Customization

Before you start, customize the parameters in the docker-compose.yml.

If you want your Transfer CFT to be fully functional, you should change the CFT_FQDN variable to reflect the actual host machine’s address.  
**ATTENTION:** You cannot connect to an interface if this parameter is not correct.

If you want to register Transfer CFT with Central Governance, set CFT_CG_ENABLE to "YES", and configure the CFT_CG_HOST, CFT_CG_PORT, and CFT_CG_SHARED_SECRET parameters.

Customizing other parameters is optional.

#### 2. Enter your Transfer CFT license key in the config/cft.key file.

You need a license for the linux-x86-64 platform. The hostname defined for the key must match the hostname value set in the docker-compose.yml file.

#### 3. Data persistence

The Transfer CFT docker-compose.yml file defines a volume as a mechanism for persisting data generated by and used by Transfer CFT.  
The Transfer CFT runtime is placed in this volume so it can be reused when creating and starting a new Transfer CFT container. (See the Upgrade section.)

You can change the volume configuration to use a previously created volume. See [Volumes configuration reference](https://docs.docker.com/compose/compose-file/#volume-configuration-reference) and [Create and manage volumes](https://docs.docker.com/storage/volumes/#create-and-manage-volumes).

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

Run the docker `ps` command to see the running containers.

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

#### 7. Stop Transfer CFT service

From the folder where the docker-compose.yml file is located, you can stop the containers using the command:

```console
docker-compose stop
```

#### 8. Upgrade Transfer CFT

   It is possible to change the image used for Transfer CFT without losing Transfer CFT's data (i.e. keep the runtime) using the upgrade option. This could be useful, for example, if you want to work with a newly released SP2 instead of the current SP1, or you want to add some security options to the Linux kernel. 
   
   The upgrade procedure is as follows:
   
##### 1. Build a new Transfer CFT Docker image

From the Dockerfile, set the VERSION_BASE, RELEASE_BASE arguments according to your upgrade needs. For example:
```
ARG VERSION_BASE "3.5_SPX"
ARG RELEASE_BASE "BNdddddddd"
```

###### 1.1. Offline Build

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/)

The Dockerfile is compatible with Transfer CFT 3.5 base version and its updates.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64.

2) Build the Docker image from your Dockerfile

From the folder where the Dockerfile is located, using the downloaded package as a build argument, run the command:
```console
docker build --build-arg INSTALL_KIT=Transfer_CFT_3.5_SP1_linux-x86-64_BN12603000.zip -t cft/cft:3.5 .
```
*Note* Notice that we use the same tag for the new image.

###### 1.2. Online Build

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/)

The Dockerfile is compatible with Transfer CFT 3.5 base version and its updates.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64 and make it available in your network.

2) Build the Docker image from your Dockerfile

From the folder where the Dockerfile is located, run the command:

```console
docker build --build-arg URL_BASE=https://network.package.location/ -t cft/cft:3.5 .
```
*Note* Notice that we use the same tag for the new image.

##### 2. Export the Transfer data and stop the container using the following commands, replacing CONTAINER with your Transfer CFT container name.
 
```console
docker exec CONTAINER ./export_bases.sh
docker-compose down
```

##### 3. Recreate and start the Transfer CFT service

From the folder where the docker-compose.yml is located, run the command:

```console
docker-compose up
```

This command recreates and starts a Transfer CFT container based on the new image. When the container starts, it detects the exported data and imports it during startup.

**ATTENTION**: The new image must have the same tag as the one previously used.

### Connecting to interfaces

When you start the Transfer CFT container for the first time, a user/password pair is created, which you can find in the container logs.

The information displays as:

```
    ------------------------
        UI user created 
    username: admin 
    pass: PASS
    ------------------------
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

### Customization

This section explains how to customize the default XFBADM user, the Central Governance SSL CA certificate, the Sentinel SSL CA certificate, the Copilot server SSL certificate, and scripts invoked when creating or starting a container.
To enable customization, you must define a mapped volume that refers to a local directory containing the SSL certificates and/or the user's password files.
In this example, the directory '/opt/app/custom' in the container maps the local directory './custom'. The mapped directory '/opt/app/custom' is in read-only mode.

```
volumes:
  - ./custom:/opt/app/custom:ro
```

#### Default XFBADM user

To specify the login and password for an XFBADM user to create during the container creation, set variables USER_XFBADM_LOGIN and USER_XFBADM_PASSWORD as follow:
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
            USER_CG_CA_CERT:            "/opt/app/custom/cg_ca_cert.pem"
            USER_SENTINEL_CA_CERT:      "/opt/app/custom/sentinel_ca_cert.pem"
            USER_COPILOT_CERT:          "/opt/app/custom/copilot.p12"
            USER_COPILOT_CERT_PASSWORD: "cat /run/secrets/copilot_p12.pwd"
secrets:
    copilot_p12.pwd:
        file: ./custom/copilot_p12.pwd
```

If one of the specified certificates has changed when the container starts, it is automatically updated so that the container always uses the certificate located in the local directory.

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

Copyright (c) 2019 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.
