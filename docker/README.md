# Transfer CFT Docker

Transfer CFT 3.10 Docker image

## Before you begin

This document assumes a basic understanding of core Docker concepts such as containers, container images, and basic Docker commands.
If needed, see [Get started with Docker](https://docs.docker.com/get-started/) for a primer on container basics.

### Prerequisites

- Docker version 17.11 or higher

## How to use the Transfer CFT Dockerfile

The Dockerfile contains all commands required to assemble a Transfer CFT image.

### Dockerfile parameters

The following parameters can be set in the [`Dockerfile`](./Dockerfile). Use these parameters to customize the Transfer CFT image and service. All values are transmitted to Transfer CFT using environment variables.

 **Parameter**             |  **Values**  |  **Description**
 ------------------------- | :----------: | ---------------
CFT_FQDN                   |  \<string>   |  Host address of the local server.
CFT_INSTANCE_ID            |  \<string>   |  Name of the Transfer CFT instance.
CFT_INSTANCE_GROUP         |  \<string>   |  The Transfer CFT instance's group.
CFT_CATALOG_SIZE           |  \<number>   |  Catalog size.
CFT_COM_SIZE               |  \<number>   |  Communication file size.
CFT_PESIT_PORT             |  \<number>   |  Port number of the PeSIT protocol called PESITANY.
CFT_PESITSSL_PORT          |  \<number>   |  Port number of the PeSIT protocol called PESITSSL.
CFT_SFTP_PORT              |  \<number>   |  Port number of the SFTP protocol.
CFT_COMS_PORT              |  \<number>   |  Port number of the synchronous communication media called COMS.
CFT_COPILOT_PORT           |  \<number>   |  The Transfer CFT UI server port that listens for incoming SOAP web-service connections.
CFT_COPILOT_CG_PORT        |  \<number>   |  The Transfer CFT UI server port that listens for incoming Central Governance connections.
CFT_COPILOT_CG_PORT_EXPOSED|  \<number>   |  The Transfer CFT UI server port that listens for incoming Central Governance connections from outside the container. Set this parameter if the exposed port differs from CFT_COPILOT_CG_PORT.
CFT_RESTAPI_PORT           |  \<number>   |  The Transfer CFT UI REST API server port.
CFT_CG_ENABLE              |  "YES"/"NO"  |  Connectivity with Central Governance.
CFT_CG_HOST                |  \<string>   |  Host address of the Central Governance server.
CFT_CG_PORT                |  \<number>   |  Listening port of the Central Governance server.
CFT_CG_SHARED_SECRET       |  \<string>   |  Shared secret needed to register with the Central Governance server.
CFT_CG_POLICY              |  \<string>   |  Central Governance configuration policy to apply at Transfer CFT registration.
CFT_CG_PERIODICITY         |  \<number>   |  Central Governance interval between notifications.
CFT_CG_AGENT_NAME          |  \<string>   |  Central Governance agent name.
CFT_JVM                    |  \<number>   |  Amount of memory that the Secure Relay JVM can use.
CFT_KEY                    |  \<string>   |  A command that returns the Transfer CFT license key.
CFT_CFTDIRRUNTIME          |  \<string>   |  Location of the Transfer CFT runtime.

## How to build the Docker image

### 1. Build the Docker image from your Dockerfile

#### 1.1. Build using a local Transfer CFT package

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/).

The Dockerfile is compatible with Transfer CFT 3.6 SP1 version and higher.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64.

2) Build the Docker image from your Dockerfile.

From the folder where the Dockerfile is located, using the downloaded package as `INSTALL_KIT` build argument, run the command:
```console
docker build --build-arg INSTALL_KIT=Transfer_CFT_3.10.2206_Update_d2269df442_linux-x86-64.zip -t axway/cft:3.10.2206 .
```

#### 1.2. Build using a Transfer CFT package stored on your own HTTP server

1) Download the Transfer CFT product package from [Axway Support](https://support.axway.com/).

The Dockerfile is compatible with Transfer CFT 3.6 SP1 version and higher.

From the [Axway Support](https://support.axway.com/), download the latest package for linux-x86-64 and make it available in your network.

2) Build the Docker image from your Dockerfile.

From the folder where the Dockerfile is located, run the command:

```console
docker build --build-arg URL_BASE=https://network.package.location/ -t axway/cft:3.10.2206 .
```

### 2. Check that the Docker image is successfully created

Run the command:

```console
docker images --filter reference=axway/cft
```

You should get an output like:
```console

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
axway/cft             3.10.2206           26fe6e1aa1fb        4 days ago          381MB
```

## Copyright

Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.

