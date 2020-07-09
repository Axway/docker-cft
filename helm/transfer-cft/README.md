# Transfer CFT's helm templates for Kubernetes

## Introduction

This chart bootstraps a Transfer CFT deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

  - Kubernetes 1.14+
  - Helm 2.16+
  - Helm 3+ 

## Installing the Chart

To install the chart with the release name `transfer-cft`:

```console
$ helm install --name transfer-cft ./transfer-cft
```

The command deploys Transfer CFT on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `transfer-cft` deployment:

```console
$ helm delete transfer-cft
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

**For the cert files or license file, when you desire to use local files you can put all in the path transfer-cft/conf or using a custom path to do it (e.g. ../../config/certs/myfile.p12)**

The following table lists the configurable parameters of the Transfer CFT chart and their default values.

Parameter | Description | Default
--- | --- | ---
`replicaCount` | number of replicas deployed | `1`
`image.repository` | image repository for docker image | `cft/cft`
`image.tag` | image tag used for the deployment | `3.6-SP1`
`image.pullPolicy` | Pull Policy Action for docker image | `IfNotPresent`
`image.imagePullSecrets` | secret used for Pulling image | `regcred`
`nameOverride` | new name use for the deployment | `nil`
`fullnameOverride` | name use for the release | `nil`
`podLabels` | additional labels | `nil`
`resources` | CPU/memory resource requests/limits | `{"requests":{"cpu":"100m","memory":"280Mi"}}`
`livenessProbe.periodSeconds`        | How often to perform the probe                                                               | 10
`livenessProbe.successThreshold`     | Minimum consecutive successes for the probe to be considered successful after having failed. | 1 
`livenessProbe.failureThreshold`     | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3 
`readinessProbe.periodSeconds`       | How often to perform the probe                                                               | 10
`readinessProbe.successThreshold`    | Minimum consecutive successes for the probe to be considered successful after having failed. | 1 
`readinessProbe.failureThreshold`    | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3 
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
`cft.fqdn` | A fully qualified domain name (FQDN) or an  IP address used to connect to your Transfer CFT deployment | `nil`
`cft.instanceId` | Name of the Transfer CFT instance | `docker0_cft`
`cft.instanceGroup` | Transfer CFT instance's group | `dev.docker`
`cft.catalogSize` | Number of records for the Catalog | `1000`
`cft.comSize` | Number of records for the communication file | `1000`
`cft.licenseKey.secretName` | Name of the secret used to store the license key (secretname is mandatory) | `license-key`
`cft.licenseKey.createSecretFile` | Create the license key using a local file | `false`
`cft.licenseKey.localFile` | Relative path to the license key file (you can use conf directory in the helm chart) | `{} (eg. conf/cft.key)`
`cft.licenseKey.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.multinode.nodesNumber` | Number of cft nodes to use (if this number is greater than replicaCount, only replicaCount nodes are started) | `1`
`cft.jvm` | Amount of memory that the Secure Relay JVM can use | `1024`
`cft.cg.enabled:` | Connectivity with Central Governance | `false`
`cft.cg.host` | Host address of the Central Governance server | `cg`
`cft.cg.port` | Listening port of the Central Governance server | `12553`
`cft.cg.policy` | Central Governance configuration policy to apply at Transfer CFT registration | `nil`
`cft.cg.periodicity` | Central Governance interval between notifications | `nil`
`cft.cg.caCert.secretName` | Name of the secret used to store the Central Governance root Certificate Authority (secretname is mandatory) | `cg-ca-cert`
`cft.cg.caCert.createSecretFile` | Create the Central Governance root Certificate Authority secret at installation using a local file | `false`
`cft.cg.caCert.localFile` | Relative path to the Central Governance root Certificate Authority (you can use conf directory in the helm chart) | `{} (eg. conf/cg_ca.pem)`
`cft.cg.caCert.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.cg.sharedSecret.secretName` | Name of the secret used to store the Central Governance shared secret (secretname is mandatory) | `cg-shared-secret`
`cft.cg.sharedSecret.createSecretFile` | Create the Central Governance shared secret secret at installation using a local file | `false`
`cft.cg.sharedSecret.localFile` | Relative path to the Central Governance shared secret (you can use conf directory in the helm chart) | `{} (eg. conf/shared_secret)`
`cft.cg.sharedSecret.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.copilotCert.secretName` | Name of the secret used to store the Copilot certificate (secretname is mandatory) | `copilot-cert`
`cft.copilotCert.createSecretFile` | Create the Copilot certificate secret at installation using a local file | `false`
`cft.copilotCert.localFile` | Relative path to the Copilot certificate (you can use conf directory in the helm chart) | `{} (eg. conf/copilot.p12)`
`cft.copilotCert.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.copilotCertPassword.secretName` | Name of the secret used to store the Copilot certificate password (secretname is mandatory) | `copilot-cert-password`
`cft.copilotCertPassword.createSecretFile` | Create the Copilot certificate password secret at installation using a local file | `false`
`cft.copilotCertPassword.localFile` | Relative path to the Copilot certificate password (you can use conf directory in the helm chart) | `{} (eg. conf/copilot.p12.pwd)`
`cft.copilotCertPassword.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.sentinelCACert.secretName` | Name of the secret used to store the Sentinel root Certificate Authority (secretname is mandatory) | `sentinel-ca-cert`
`cft.sentinelCACert.createSecretFile` | Create the Sentinel root Certificate Authority secret at installation using a local file | `false`
`cft.sentinelCACert.localFile` | Relative path to the Sentinel root Certificate Authority (you can use conf directory in the helm chart) | `{} (eg. conf/sentinel_ca_cert.pem)`
`cft.sentinelCACert.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.xfbadmLogin` | Login of the xfbadm user to create at container creation. If both xfbadmLogin and xfbadmPassword.secretName are defined, the corresponding user is added to xfbadmusr database. | `admin`
`cft.xfbadmPassword.secretName` | Name of the secret used to store the xfbadm user password (secretname is mandatory) | `xfbadm-password`
`cft.xfbadmPassword.createSecretFile` | Create the xfbadm user password secret at installation using a local file | `false`
`cft.xfbadmPassword.localFile` | Relative path to the xfbadm user password (you can use conf directory in the helm chart) | `{} (eg. conf/xfbadm.pwd)`
`cft.xfbadmPassword.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.apiLogin` | Login of a REST API user. This login is used to invoke a Transfer CFT REST API during the pre-upgrade step. | `admin`
`cft.apiPassword.secretName` | Name of the secret used to store the API user password (secretname is mandatory) | `api-password`
`cft.apiPassword.createSecretFile` | Create the API user password secret at installation using a local file | `false`
`cft.apiPassword.localFile` | Relative path to the file API user password (you can use conf directory in the helm chart) | `{} (eg. conf/xfbadm.pwd)`
`cft.apiPassword.existingSecretFile` | Name of an existing secret to use | `{}`
`cft.initScript.fileName` | name of a script to be executed at container initialization (filename is mandatory) | `init-sh`
`cft.initScript.createConfigMap` | create a configmap for the initialization script | `false`
`cft.initScript.localFile` | relative path to the initialization script (you can use conf directory in the helm chart) | `{} (eg. conf/init.sh`
`cft.initScript.existingConfigMap` | name of an existing configmap to use | `{}`
`cft.startScript.fileName` | name of a script to be executed at each container start-up (filename is mandatory) | `startup-sh`
`cft.startScript.createConfigMap` | create a configmap for the start-up script | `false`
`cft.startScript.localFile` | relative path to the start-up script (you can use conf directory in the helm chart) | `{} (eg. conf/startup.sh)`
`cft.startScript.existingConfigMap` | name of an existing configmap to use | `{}`
`cft.passportPersistencyCheckInterval` | interval in seconds between two checks of Passport access management updates | `60`
`persistence.enabled` | enable config persistence using PVC | `true`
`persistence.keep` | keep persistent volume after helm delete | `false`
`persistence.cftData.storageClass` | Persistent Volume Claim Storage Class for config volume | `nil`
`persistence.cftData.accessMode` | Persistent Volume Claim Access Mode for config volume | `ReadWriteOnce`
`persistence.cftData.size` | Persistent Volume Claim Storage Request for config volume (see information on resources to chose the good value for your application) | `2Gi`
`persistence.cftData.existingClaim` | manually managed Persistent Volume Claim | `nil`
`persistence.cftData.nfsPath` | basepath of the mount point to be used | `nil`
`persistence.cftData.nfsServer` | hostname of the NFS server | `nil (ip or hostname)`
`persistence.cftData.reclaimPolicy` | retain, recycle or delete. Only NFS support recycling | `retain`
`persistence.cftData.mountOptions` | mount options for NFS | `nil`
`extraSecretMounts` | Additionnal secret mounts to be added | `[]`
`extraVolumeMounts` | Additionnal volume mounts to be added (volume where transfer files are located) | `[]`
`extraEnv` | Additional environment variables | `[]`
`service.type` | Create dedicated service for the deployment LoadBalancer, ClusterIP or NodePort | `LoadBalancer`
`service.ports` | Ports definitions for CFT services | `[{"name": "restapi","port": 1768},{"name": "pesit","port": 1761},{"name": "pesitssl","port": 1762},{"name": "sftp","port": 1763},{"name": "copilot","port": 1766},{"name": "copilotcg","port": 1767}]`
`service.annotations` | Custom annotations for service | `{}`

These parameters can be passed via Helm's `--set` option
```console
$ helm install --name transfer-cft ./transfer-cft \
  --set image.repository=cft/cft \
  --set image.tag=3.6
  --set resources={ "limits":{"cpu":"1000m","memory":"600Mi"},"requests":{"cpu":"200m","memory":"300Mi"}}
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
$ helm install --name transfer-cft ./transfer-cft -f my-values.yaml
```

> **Tip**: You can modify and use the default [values.yaml](values.yaml)

## Resources
The resources needed for Transfer CFT to run correctly depends on how Transfer CFT is used.

The resources needed to run Transfer CFT properly are based on the Catalog size and in the number of transfers per hour.

For memory use, you should add the value related with the Catalog size and the one from the transfers per hour.

> **Example** for a Catalog with 10000 records and 1000 transfers/h, you should have 550Mi of memory = 500Mi (for Catalog) + 50Mi (for Transfers' load)

#### Catalog size
Catalog Size | Disk space (MB) | Memory (Mi)
--- | --- | ---
 1000 | 512 | 250
 10000 | 1000 | 500
 100000 | 3000 | 2500

#### Transfers per hour
transfers/h | CPU (m) | Memory (Mi)
--- | --- | ---
 1000 | 100 | 50
 10000 | 250 | 50
 100000 | 650 | 200

