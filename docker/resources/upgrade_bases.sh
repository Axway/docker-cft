#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

source ./utils.sh

update_env_path()
{
    local version="$1"
    export BACKUP_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    export BACKUP_PATH="$PATH"

    if [[ -d "${UPGRADEDIR}/${version}" ]]; then
        export PATH="${UPGRADEDIR}/${version}/bin:${PATH}"
        export LD_LIBRARY_PATH="${UPGRADEDIR}/${version}/lib:${LD_LIBRARY_PATH}"
    else
        log_warning "Backup library path not found, using default LD_LIBRARY_PATH"
    fi
}

restore_env_path()
{
    export LD_LIBRARY_PATH="$BACKUP_LD_LIBRARY_PATH"

    if [[ -n "${BACKUP_PATH:-}" ]]; then
        export PATH="$BACKUP_PATH"
    else
        log_warning "Backup BACKUP_PATH not found, using default PATH"
    fi
}

check_prerequisites()
{
    local err=0
    local version="$1"
    local backup_version

    if [[ ! -d "${UPGRADEDIR}/${version}/lib" ]]; then
        log_fatal "Backup directory ${UPGRADEDIR}/${version}/lib does not exist"
        return 1
    fi

    if [[ ! -d "${UPGRADEDIR}/${version}/bin" ]]; then
        log_fatal "Backup directory ${UPGRADEDIR}/${version}/bin does not exist"
        return 1
    fi

    update_env_path "$version"

    backup_version=$(get_cft_version_num)
    if [[ $? -ne 0 || -z "$backup_version" ]]; then
        log_fatal "Failed to retrieve backup version"
        err=1
    fi

    if [[ $err -eq 0 && "$backup_version" != "$version" ]]; then
        log_fatal "Backup version $backup_version does not match expected version $version"
        err=1
    fi

    restore_env_path

    if [[ $err -eq 0 ]]; then
        log_info "Prerequisite checks passed"
        return 0
    else
        log_fatal "Prerequisite checks failed"
        return 1
    fi
}

stop_workers()
{
    if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
        local ping_status
        local max_retries=30
        local count=0
        
        cftping
        ping_status=$?
        if [[ $ping_status -ne 0 ]]; then
            log_warning "Some worker nodes are running, stopping them before upgrade..."
            cft stop
            while [[ $ping_status -ne 0 && $count -le $max_retries ]]; do
                count=$((count + 1))
                log_warning "Waiting for worker nodes to stop... ($count/$max_retries)"
                sleep 1
                cftping
                ping_status=$?
            done
            cftping
            ping_status=$?
            log_info "cftping: returned $ping_status"
        fi
        if [[ $ping_status -ne 0 ]]; then
            log_fatal "Failed to stop all worker nodes within 30 seconds"
            return 1
        else
            log_info "All worker nodes are stopped"
        fi
    fi
    return 0
}

install_version=$(get_cft_version_num "INSTALLATION")
if [[ $? -ne 0 || -z "$install_version" ]]; then
    log_fatal "Failed to retrieve installed version"
    exit 1
fi
log_info "Transfer CFT version is $install_version"

runtime_version=$(get_runtime_version_num)
if [[ -z "$runtime_version" ]]; then
    log_warning "Failed to retrieve runtime version, skipping upgrade"
    exit 0
fi
log_info "Runtime data version is $runtime_version"

if [[ "$install_version" = "$runtime_version" ]]; then
    log_info "Runtime version is already up-to-date: $runtime_version"
    exit 0
elif [[ "$install_version" > "$runtime_version" ]]; then
    log_info "Upgrading runtime version from $runtime_version to $install_version..."

    # Check prerequisites before proceeding
    check_prerequisites "$runtime_version"
    if [[ $? -ne 0 ]]; then
        log_fatal "Prerequisite checks failed, cannot proceed with upgrade"
        exit 1
    fi
else
    log_info "Downgrading runtime version from $runtime_version to $install_version..."

    # Check prerequisites before proceeding
    check_prerequisites "$runtime_version"
    if [[ $? -ne 0 ]]; then
        log_fatal "Prerequisite checks failed, cannot proceed with downgrade"
        exit 1
    fi
fi

# Load profile
. "$CFT_CFTDIRRUNTIME/profile"
if [[ $? -ne 0 ]]; then
    log_fatal "Failed to load profile"
    exit 1
fi

is_kubernetes
if [[ $? -eq 1 ]] && [[ "$CFT_MULTINODE_ENABLE" = "YES" ]] && [[ $CFT_MULTINODE_NUMBER -gt 1 ]]; then
    # In Kubernetes multinode context, we need to:
    # - stop other worker nodes
    # - set REST API servers in unavailable mode
    # - export the databases.
    # All those actions are done by calling the /export REST API.
    log_info "multinode enabled with $CFT_MULTINODE_NUMBER nodes, exporting using REST API..."

    ./export_bases_job.sh
    if [[ $? -ne 0 ]]; then
        log_fatal "Failed to export databases"
        exit 1
    fi
else
    # Export bases with old binaries
    log_info "multinode enabled with $CFT_MULTINODE_NUMBER node, exporting using old binaries..."

    # Update environment PATH and LD_LIBRARY_PATH
    update_env_path "$runtime_version"

    if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
        # Ensure CFT workers are stopped before upgrade
        stop_workers
        if [[ $? -ne 0 ]]; then
        log_fatal "Failed to stop worker nodes"
        restore_env_path
        exit 1
        fi
    fi

    ./export_bases.sh
    if [[ $? -ne 0 ]]; then
        log_fatal "Failed to export databases"
        restore_env_path
        exit 1
    fi

    restore_env_path
fi

# Import bases with new binaries
./import_bases.sh
if [[ $? -ne 0 ]]; then
    log_fatal "Failed to import databases"
    exit 1
fi

exit 0
