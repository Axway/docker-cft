# Changelog
All notable changes to this project will be documented in this file.

## [3.10.2412] - 2024-12

### Added
- Tests for pre-upgrade job

### Fixed
- Better protection of critical operations during startup for clusters.
- Avoid increasing number of hosts in configuration.
- Removed obsolete version parameter from compose.
- Version comparison during upgrade.

### Changed
- Copilot Certificate can now be in X509 format and not only PKCS12. Parameters for setting a Key with a optional password added.

## [3.10.2409] - 2024-09-18

### Added
- Support FIPS
- Parameter cg.copilot.export_port/CFT_COPILOT_CG_PORT_EXPOSED added

### Changed
- Dockerfile: Replace ubuntu 22.04 by 24.04

## [3.10.2406] - 2024-06-07

### Added
- Documentation about upgrade for helm.

## [3.10.2403] - 2024-03-27

### Fixed
- Make the multinode works using the compose-multinode.yml with scale option.

## [3.10.2309] - 2023-09-30

### Changed
- Replaced the cft utilities option /m=2 by /m=14 to display error messages in case of a problem.

## [3.10.2306] - 2023-06-30

### Added
- It is now possible to configure the upgrade job for helm using an API token instead of a user/password

### Fixed
- After the registration to Flow Manager, if no custom certificate is specified, the REST API server uses the certificate generated during registration.
- Docker compose templates are compatible with "docker compose" functionality.

## [3.10.2303] - 2023-03-31

### Changed
- Podman templates support secrets.
- Configuration templates have changed. Protocols Pesit, SFTP and Pesit using SSL are always activated; when not using FM/CG, partners and all needed certificates are created. 

### Fixed
- Add registration_id condition before generate new certificate.
- Incomplete cft_support: "file" utility added to the image.

## [3.10.2206] - 2022-07-12

### Added
- Podman templates.

### Changed
- Verification of required parameters before deployment in helm.
- Improved protection of undefined parameters in helm.
 
## [3.10] - 2022-04-15

### Added
- Audit logs added to upgrade.

### Changed
- Copilot certificate generated uses CFT_INSTANCE_ID as CN.

### Fixed
- The usage of existingSecretFile or existingConfigMap was not correct.

## [3.9] - 2021-10-21

### Added
- Added support for OpenShift. Any user can run the Transfer CFT container.

### Changed
- You must accept the general conditions prior to creating a container (ACCEPT_GENERAL_CONDITIONS=YES in docker-compose, cft.accept_general_conditions=true for Helm).
- To upgrade your Transfer CFT deployment to v3.9, you require Transfer CFT v3.6 SP4 or higher.
- When Flow Manager or Central Governance is enabled and if no custom certificate is specified, the REST API server uses the certificate generated during registration.
- Helm: Added the cft.cg.agentName parameter to values.yaml which allows you to register your Transfer CFT instance to Flow Manager SaaS.

## [3.6 SP2] - 2021-05-31

### Changed
- Helm README updated on resources calculation.
- Helm README updated disks prerequisites.

## [3.7] - 2020-09-30

### Added
- Sentinel parameters support.

### Changed
- Host information calculation for add_host command.
 
### Fixed
- A single node Transfer CFT instance running inside a podman container did not stop properly.
- Missing imagePullSecrets in pre-upgrade would cause upgrade to fail when a imagePullSecret was needed.

## [3.6 SP1] - 2020-06-30

### Added
- Helm templates for Kubernetes.
- Multinode support to enable Transfer CFT deployment with multiple replicas.
- Health check using /healthz.
- A REST API to export Transfer CFT data prior to upgrading your deployment (PUT /cft/api/v1/cft/container/export).
 
### Changed
- File and folder organization in the repository.
- CFT_KEY, CFT_CG_SHARED_SECRET, USER_COPILOT_CERT_PASSWORD, USER_XFBADM_PASSWORD can be a command, a file, or a string value.
- Parameter USER_XFBADM_PASSWORD is mandatory to create the user defined by USER_XFBADM_LOGIN.
- Stop Transfer CFT using 'cft stop' command instead of 'cft force-stop'.
- Remove COMS from exposed ports.
 
### Fixed
- Locking issue if error occurred while creating the runtime.
