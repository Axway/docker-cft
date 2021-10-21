# Changelog
All notable changes to this project will be documented in this file.
 
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
