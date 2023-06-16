# Containerized Transfer CFT 

## Contents
The folders in this repository contain templates for the various ways to deploy Transfer CFT in a containerized world. These templates are only compatible with Transfer CFT 3.6 SP1 version and higher.
- [**Docker**](./docker):  Contains the Dockerfile template and all other resources needed to create a Docker image for Transfer CFT.
- [**Compose**](./compose): Contains compose file templates needed to deploy Transfer CFT using Docker Compose.
- [**Helm**](./helm):    Contains the Helm template files used to deploy Transfer CFT on Kubernetes or Red Hat OpenShift.
- [**Podman**](./podman):  Contains podman templates needed to deploy Transfer CFT using podman.

Please refer to the README located in each folder for more information about the deployment method.

## Support arbitrary user IDs
Transfer CFT image is OpenShift compatible, which means that you can start it with a random user ID (UID) and the group ID (GID) of root user (GID=0). If you want to run the image with a user other than the default one, axway (UID=1000), you MUST set the GID of the user to 0. If you try to use a different group, the container exits with errors.

OpenShift randomly assigns a UID when it starts the container, but you can use this flexible UID also when running the image manually. This might be useful, for example, in case you want to mount folders from the host system on Linux, in which case the UID should be set the same ID as your host user.

You can dynamically set the user in the docker run command, by adding `--user` flag in one of the following formats (See [Docker Run reference](https://docs.docker.com/engine/reference/run/) for details):

` [ user | user:group | uid | uid:gid | user:gid | uid:group ] `

In a Docker Compose environment, it can be changed via `user:` entry in the `compose.yaml` (See [Docker Compose reference](https://docs.docker.com/compose/) for details).

In a Kubernetes environment, it can be changed via `runAsUser` and `runAsGroup` entries in `value.yml`.

If the GID is set to 0, the user can be any UID. If the UID is not 1000 (axway), the user will be automatically created when entering the container.

## Copyright

Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.
