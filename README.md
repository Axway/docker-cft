# Containerized AMPLIFY Transfer CFT 

## Contents
The folders in this repository contain templates for the various ways to deploy Transfer CFT in a containerized world. These templates are only compatible with Transfer CFT 3.6 SP1 and higher.
- Docker:  Contains the Dockerfile template and all other resources needed to create a Docker image for Transfer CFT.
- Compose: Contains docker-compose file templates needed to deploy Transfer CFT using Docker Compose.
- Helm:    Contains the Helm template files used to deploy Transfer CFT on Kubernetes.

Please refer to the README located in each folder for more information about the deployment method.

## Support arbitrary user ids
Transfer CFT image is Open-Shift compatible, which means that you can start it with random user ID and the group id 0 (root). If you want to run the image with user different than default one, axway (UID=1000), you MUST set GID of the user to 0. In case you try to use different group, the container exits with errors.

OpenShift randomly assigns UID when it starts the container, but you can utilise this flexible UID also in case of running the image manually. This might be useful for example in case you want to mount folders from host system on Linux, in which case the UID should be set the same ID as your host user.

This can be achieved in various ways - you can dynamically pass the user to docker run command, by adding --user flag in one of those formats (See Docker Run reference for details):

` [ user | user:group | uid | uid:gid | user:gid | uid:group ] `

In case of Docker Compose environment it can be changed via user: entry in the docker-compose.yaml. See Docker compose reference for details.

In case of Kubernetes environment it can be changed via runAsUser, runAsGroup entries in value.yml.

In case GID is set to 0, the user can be any UID. If the UID is different axway (UID=1000), the user will be automatically created when entering the container.

## Copyright

Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.
