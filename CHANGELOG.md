# Changelog
All notable changes to this project will be documented in this file.
 
## [3.6 SP1] - 2020-06-30

### Added
- Helm templates for Kubernetes.
- Multinode support allowing to deploy Transfer CFT with multiple replicas.
- Added /healthz for healthcheck.
- Added a REST API to export Transfer CFT data prior to upgrade your deployment (PUT /cft/api/v1/cft/container/export).
- .
 
### Changed
- Files and Folders organization inside the repository.
- CFT_KEY, CFT_CG_SHARED_SECRET, USER_COPILOT_CERT_PASSWORD, USER_XFBADM_PASSWORD can be a command, a file or a string value.
- Stop Transfer CFT using 'cft stop' command instead of 'cft force-stop'.
- Remove COMS from exposed ports.
- .
 
### Fixed
- Locking issue when error was faced while creating the runtime.
- .
