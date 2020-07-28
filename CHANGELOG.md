# Changelog
All notable changes to this project will be documented in this file.
 
## [3.6 SP1] - 2020-06-30

### Added
- Helm templates for Kubernetes.
- Multinode support to enable Transfer CFT deployment with multiple replicas.
- Health check using /healthz.
- A REST API to export Transfer CFT data prior to upgrading your deployment (PUT /cft/api/v1/cft/container/export).
 
### Changed
- File and folder organization in the repository.
- CFT_KEY, CFT_CG_SHARED_SECRET, USER_COPILOT_CERT_PASSWORD, USER_XFBADM_PASSWORD can be a command, a file, or a string value.
- Stop Transfer CFT using 'cft stop' command instead of 'cft force-stop'.
- Remove COMS from exposed ports.
 
### Fixed
- Locking issue if error occurred while creating the runtime.