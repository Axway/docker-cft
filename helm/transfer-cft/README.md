# Helm templates for Transfer CFT on Kubernetes or Red Hat OpenShift

## Introduction

The delivered chart bootstraps a Transfer CFT deployment on a [Kubernetes](http://kubernetes.io) or [Red Hat OpenShift](https://www.openshift.com) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

  - Kubernetes 1.14+ or Red Hat Openshift 3+
  - Helm 3+

## Installing the chart

To install the chart with the release name `transfer-cft`:

```console
$ helm install --name transfer-cft ./transfer-cft
```

The command deploys Transfer CFT on the Kubernetes or Red Hat OpenShift cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Upgrading the chart

To upgrade the chart with the release name `transfer-cft`:

```console
$ helm upgrade --install transfer-cft ./transfer-cft
```

The parameter `image.tag` in values.yaml should reflect the target version.

> **Tip**: When the chart is deployed using helm, a pre-upgrade job is created (that uses parameters `cft.apiLogin` and `cft.apiPassword.secretName`). This job is automatically called when using `helm upgrade` and will do all the needed operations before the new version of Transfer CFT is deployed.

## Uninstalling the chart

To uninstall/delete the `transfer-cft` deployment:

```console
$ helm delete transfer-cft
```

The command removes all the Kubernetes or Red Hat OpenShift components associated with the chart and deletes the release.

## Configuration

**If you want to use local files for the certicates or license files, you can put all in the path `transfer-cft/conf`, or use a custom path (e.g. `../../config/certs/myfile.p12`)**

The following table lists the configurable Transfer CFT chart parameters and their default values.

Parameter | Description | Default
--- | --- | ---
`replicaCount` | Number of replicas deployed | `1`
`image.repository` | Image repository for docker image | `docker.repository.axway.com/transfercft-docker-prod/3.10/cft`
`image.tag` | Image tag used for the deployment | `3.10.2206`
`image.pullPolicy` | Pull Policy Action for docker image | `IfNotPresent`
`image.imagePullSecrets` | Secret used for Pulling image | `regcred`
`nameOverride` | New name use for the deployment | `nil`
`fullnameOverride` | Name use for the release | `nil`
`podLabels` | Additional labels | `nil`
`resources` | CPU/memory resource requests/limits | `{"requests":{"cpu":"100m","memory":"280Mi"}}`
`livenessProbe.periodSeconds`     | How often to perform the probe                                                               | 10
`livenessProbe.successThreshold`  | Minimum consecutive successes for the probe to be considered successful after having failed. | 1
`livenessProbe.failureThreshold`  | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3
`readinessProbe.periodSeconds`    | How often to perform the probe                                                               | 10
`readinessProbe.successThreshold` | Minimum consecutive successes for the probe to be considered successful after having failed. | 1
`readinessProbe.failureThreshold` | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3
`serviceAccount.create` | Create custom service account for the deployment | `false`
`serviceAccount.name` | Service Account name used for the deployment | `nil`
`rbac.create` | Create custom role base access control (RBAC) for the deployment | `false`
`pspEnable.create` | Create custom pod security policy for user account | `false`
`podAnnotations` | Annotations for pods (example prometheus scraping) | `{}`
`podSecurityContext` | User used no root inside the container | `{}`
`containerSecurityContext` | Restriction inside the pod | `{}`
`priorityClassName` | Name of the priority class to be used | `nil`
`nodeSelector` | Label used to deploy on specific node | `{}`
`tolerations` | Toleration are applied to pods, and allow (but do not require) the pods to schedule onto nodes with matching taints | `[]`
`affinity` | Affinity rules between each pods | `{}`
`cft.accept_general_conditions` | Set parameter to yes if you accept the applicable General Terms and Conditions, located at https://www.axway.com/en/legal/contract-documents | `no`
`cft.fqdn` | A fully qualified domain name (FQDN) or an  IP address used to connect to your Transfer CFT deployment | `nil`
`cft.instanceId` | Name of the Transfer CFT instance | `docker0_cft`
`cft.instanceGroup` | Transfer CFT instance's group | `dev.docker`
`cft.catalogSize` | Number of records for the Catalog | `1000`
`cft.comSize` | Number of records for the communication file | `1000`
`cft.licenseKey.secretName` | Name of the secret used to store the license key (secretname is mandatory) | `license-key`
`cft.licenseKey.createSecretFile` | Create the license key using a local file | `false`
`cft.licenseKey.localFile` | Relative path to the license key file (you can use conf directory in the helm chart) | `{}` (eg. `conf/cft.key`)
`cft.licenseKey.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.multinode.nodesNumber` | Number of cft nodes to use (if this number is greater than replicaCount, only replicaCount nodes are started) | `1`
`cft.jvm` | Amount of memory that the Secure Relay JVM can use | `1024`
`cft.cg.enabled:` | Connectivity with Flow Manager or Central Governance | `false`
`cft.cg.host` | Host address of the Central Governance server | `fm`
`cft.cg.port` | Listening port of the Central Governance server | `8081`
`cft.cg.policy` | Central Governance configuration policy to apply at Transfer CFT registration | `nil`
`cft.cg.periodicity` | Central Governance interval between notifications | `nil`
`cft.cg.caCert.secretName` | Name of the secret used to store the Central Governance root Certificate Authority (secretname is mandatory) | `cg-ca-cert`
`cft.cg.caCert.createSecretFile` | Create the Central Governance root Certificate Authority secret at installation using a local file | `false`
`cft.cg.caCert.localFile` | Relative path to the Central Governance root Certificate Authority (you can use conf directory in the helm chart) | `{}` (eg. `conf/cg_ca.pem`)
`cft.cg.caCert.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.cg.sharedSecret.secretName` | Name of the secret used to store the Central Governance shared secret (secretname is mandatory) | `cg-shared-secret`
`cft.cg.sharedSecret.createSecretFile` | Create the Central Governance shared secret secret at installation using a local file | `false`
`cft.cg.sharedSecret.localFile` | Relative path to the Central Governance shared secret (you can use conf directory in the helm chart) | `{}` (eg. `conf/shared_secret`)
`cft.cg.sharedSecret.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.cg.agentName` | The Flow Manager Agent's name that the Flow Manager SaaS uses to connect to your Transfer CFT instance. | `nil`
`cft.copilotCert.secretName` | Name of the secret used to store the Copilot certificate (secretname is mandatory) | `copilot-cert`
`cft.copilotCert.createSecretFile` | Create the Copilot certificate secret at installation using a local file | `false`
`cft.copilotCert.localFile` | Relative path to the Copilot certificate (you can use conf directory in the helm chart) | `{}` (eg. `conf/copilot.p12`)
`cft.copilotCert.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.copilotCertPassword.secretName` | Name of the secret used to store the Copilot certificate password (secretname is mandatory) | `copilot-cert-password`
`cft.copilotCertPassword.createSecretFile` | Create the Copilot certificate password secret at installation using a local file | `false`
`cft.copilotCertPassword.localFile` | Relative path to the Copilot certificate password (you can use conf directory in the helm chart) | `{}` (eg. `conf/copilot.p12.pwd`)
`cft.copilotCertPassword.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.sentinel.enabled` | Connectivity to Sentinel. This shouldn't be used if connectivity with Central Governance activated. | `false`
`cft.sentinel.host` | Host address of the Sentinel server. | `sentinel`
`cft.sentinel.port` | Listening port of the Sentinel server. | `1305`
`cft.sentinel.useSsl` | Enables SSL cryptography when connecting to Sentinel | `false`
`cft.sentinel.logFilter` | Sentinel Log Filter: (I)nformation, (W)arning, (E)rror, (F)atal. Authorized characters are only I, W, E, F. Each of them only once. | `EF`
`cft.sentinel.transferFilter` | Sentinel Transfer Filter. Possible values are: ALL, SUMMARY, NO, ERROR. | `ALL`
`cft.sentinel.caCert.secretName` | Name of the secret used to store the Sentinel root Certificate Authority (secretname is mandatory) | `sentinel-ca-cert`
`cft.sentinel.caCert.createSecretFile` | Create the Sentinel root Certificate Authority secret at installation using a local file | `false`
`cft.sentinel.caCert.localFile` | Relative path to the Sentinel root Certificate Authority (you can use conf directory in the helm chart) | `{}` (eg. `conf/sentinel_ca_cert.pem`)
`cft.sentinel.caCert.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.xfbadmLogin` | Login of the xfbadm user to create at container creation. If both xfbadmLogin and xfbadmPassword.secretName are defined, the corresponding user is added to xfbadmusr database. XFBADM base is used when no other identity provider is used. | `admin`
`cft.xfbadmPassword.secretName` | Name of the secret used to store the xfbadm user password (secretname is mandatory) | `xfbadm-password`
`cft.xfbadmPassword.createSecretFile` | Create the xfbadm user password secret at installation using a local file | `false`
`cft.xfbadmPassword.localFile` | Relative path to the xfbadm user password (you can use conf directory in the helm chart) | `{}` (eg. `conf/xfbadm.pwd`)
`cft.xfbadmPassword.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.apiToken.secretName` | Name of the secret used to store the API token (secretname is mandatory) | | `api-token`
`cft.apiToken.createSecretFile` | Create the API token secret at installation using a local file | `false`
`cft.apiToken.localFile` | Relative path to the file API token (you can use conf directory in the helm chart) | `{}` (eg. `conf/token.pwd`)
`cft.apiToken.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.apiLogin` | Login of a REST API user. This login is used to invoke a Transfer CFT REST API during the pre-upgrade step. When using an identity provider, this should be a valid user for the identity provider. | `admin`
`cft.apiPassword.secretName` | Name of the secret used to store the API user password (secretname is mandatory) | `api-password`
`cft.apiPassword.createSecretFile` | Create the API user password secret at installation using a local file | `false`
`cft.apiPassword.localFile` | Relative path to the file API user password (you can use conf directory in the helm chart) | `{}` (eg. `conf/password.pwd`)
`cft.apiPassword.existingSecretFile.keyRef` | Name of the reference key inside an existing secret | `{}`
`cft.initScript.fileName` | Name of a script to be executed at container initialization (filename is mandatory) | `init-sh`
`cft.initScript.createConfigMap` | Create a configmap for the initialization script | `false`
`cft.initScript.localFile` | Relative path to the initialization script (you can use conf directory in the helm chart) | `{}` (eg. `conf/init.sh`)
`cft.initScript.existingConfigMap.keyRef` | Name of the reference key inside an existing configmap | `{}`
`cft.startScript.fileName` | Name of a script to be executed at each container start-up (filename is mandatory) | `startup-sh`
`cft.startScript.createConfigMap` | Create a configmap for the start-up script | `false`
`cft.startScript.localFile` | Relative path to the start-up script (you can use conf directory in the helm chart) | `{}` (eg. `conf/startup.sh`)
`cft.startScript.existingConfigMap.keyRef` | Name of the reference key inside an existing configmap | `{}`
`cft.passportPersistencyCheckInterval` | Interval in seconds between two checks of Passport access management updates | `60`
`persistence.enabled` | Enable config persistence using PVC | `true`
`persistence.keep` | Keep persistent volume after helm delete | `false`
`persistence.cftData.storageClass` | Persistent Volume Claim Storage Class for config volume | `nil`
`persistence.cftData.accessMode` | Persistent Volume Claim Access Mode for config volume. Should be `ReadWriteMany` if `replicaCount` > 1 | `ReadWriteOnce`
`persistence.cftData.size` | Persistent Volume Claim Storage Request for config volume (see information on resources to chose the good value for your application) | `2Gi`
`persistence.cftData.existingClaim` | Manually managed Persistent Volume Claim | `nil`
`persistence.cftData.nfsPath` | Basepath of the mount point to be used | `nil`
`persistence.cftData.nfsServer` | Hostname of the NFS server | `nil` (IP or hostname)
`persistence.cftData.reclaimPolicy` | Retain, recycle or delete. Only NFS support recycling | `retain`
`persistence.cftData.mountOptions` | Mount options for NFS | `nil`
`extraSecretMounts` | Additionnal secret mounts to be added | `[]`
`extraVolumeMounts` | Additionnal volume mounts to be added (volume where transfer files are located) | `[]`
`extraEnv` | Additional environment variables | `[]`
`service.type` | Create dedicated service for the deployment LoadBalancer, ClusterIP or NodePort | `LoadBalancer`
`service.ports` | Ports definitions for CFT services | `[{"name": "restapi","port": 1768},{"name": "pesit","port": 1761},{"name": "pesitssl","port": 1762},{"name": "sftp","port": 1763},{"name": "copilot","port": 1766},{"name": "copilotcg","port": 1767}]`
`service.annotations` | Custom annotations for service | `{}`

These parameters can be passed via Helm's `--set` option
```console
$ helm install --name transfer-cft ./transfer-cft \
  --set image.repository=docker.repository.axway.com/transfercft-docker-prod/3.10/cft \
  --set image.tag=3.10.2206
  --set resources={ "limits":{"cpu":"1000m","memory":"600Mi"},"requests":{"cpu":"200m","memory":"300Mi"}}
```

Alternatively, you can provide a YAML file that specifies the parameter values during the chart installion. For example:

```console
$ helm install --name transfer-cft ./transfer-cft -f my-values.yaml
```

> **Tip**: You can modify and use the default [values.yaml](./values.yaml).

> **ATTENTION**: You require a linux-x86-64 platform key that does not have a specified hostname.

> **ATTENTION**: Transfer CFT is always in active/active cluster mode. The multi-node, multi-host architecture prerequisites apply. (Ex. Supported shared file systems are NFSv4 and AWS EFS)

#### Previously created secrets and configmaps
It is possible to use previously created secrets and configmaps, to do so, the creation of the secrets should be done as:
```console
kubectl create secret generic <secret_name> --from-file=<key_reference>=<path_to_file>
```
or
```console
kubectl create secret generic <secret_name> --from-literal=<key_reference>=<secret_value>
```
and this would give a configuration as
```console
secretName: <secret_name>
createSecretFile: false
existingSecretFile:
  keyRef: <key_reference>
```
in the [`values.yaml`](./values.yaml).
The same for the configmaps that should be created as:
```console
kubectl create configmap <configmap_name> --from-file=<key_reference>=<path_to_file>
```
or
```console
kubectl create configmap <configmap_name> --from-literal=<key_reference>=<secret_value>
```
and this would give a configuration as
```console
fileName: <secret_name>
createConfigMap: false
existingConfigMap:
  keyRef: <key_reference>
```
in the [`values.yaml`](./values.yaml).

## Resources
The resources needed for Transfer CFT to run correctly depends on how Transfer CFT is used.

The resources needed to run Transfer CFT properly are based on the catalog size, the number of parallel transfers and the Transfer CFT's configuration.

For memory use, you should add the value related to the catalog size and the result of the equations about transfers.

#### Catalog size
Catalog Size | Disk space (MB) | Memory (Mi)
--- | --- | ---
 1000 | 512 * cft.multinode.nodesNumber | 250
 10000 | 1000 * cft.multinode.nodesNumber | 500
 100000 | 3000 * cft.multinode.nodesNumber | 2500

#### Transfers
##### Sender's equation
Add the following for each partener:
```console
SCHKW (from protocol) * 1M * CNXOUT (from partner)
```

##### Receiver's equation
Add the following for each partener:
```console
RCHKW (from protocol) * RPACING (from protocol) * CNXIN (from partner)
```

##### Transfers per hour
transfers/h | CPU (m)
--- | --- 
 1000 | 100
 10000 | 250
 100000 | 650

### Example
For a catalog with 10000 records, if I do transfers with only 1 partner having CNXIN = CNXOUT = 8, using protocol with SCHKW = RCHKW = 2, it would give me 500Mi (for the catalog) + 16Mi (sender 2 * 1 * 8) + 512Mi (receiver 2 * 32Mi * 8) = 1028Mi of memory needed.

## Copyright

Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.

## License

All files in this repository are licensed by Axway Software SA and its affiliates under the Apache License, Version 2.0, available at http://www.apache.org/licenses/.

