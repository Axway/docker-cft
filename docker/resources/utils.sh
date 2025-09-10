#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

UPGRADEDIR="${CFT_CFTDIRRUNTIME}/.upgrade"

log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date +"%Y-%m-%dT%H:%M:%S.%N%:z")
    
    if [ "$level" == "ERROR" ] || [ "$level" == "FATAL" ]; then
        echo -e "${timestamp}\t${level}\t${message}" >&2
    else
        echo -e "${timestamp}\t${level}\t${message}"
    fi
}

log_fatal()
{
    log_message "FATAL" $*
}

log_warning()
{
    log_message "WARNING" $*
}

log_error()
{
    log_message "ERROR" $*
}

log_info()
{
    log_message "INFO" $*
}

get_value()
{
    in=$*

    if [ -f "$in" ]; then
        out=$(cat $in)
    else
        which $(echo $in | cut -d ' ' -f 1) >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            out=$($in)
        else
            out=$in
        fi
    fi
    echo $out
}

get_cft_version()
{
    ret=$(CFTUTIL about type=cft|sed -nr 's/.*version\s*=\s*([0-9]+.[0-9]+)/\1/p')
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_update()
{
    ret=$(CFTUTIL about type=cft|sed -nr 's/.*update\s*=\s*([0-9]+)/\1/p')
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_version_from_install()
{
    ret=$(cat ${CFT_INSTALLDIR}/.transfer_cft.properties | grep -e CFT_Version | cut -d '=' -f 2)
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_update_from_install()
{
    ret=$(cat ${CFT_INSTALLDIR}/.transfer_cft.properties | grep -e CFT_Update | cut -d '=' -f 2)
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_version_num()
{
    source="$1"

    if [[ "$source" = "INSTALLATION" ]]; then
        vers=$(get_cft_version_from_install)
        update=$(get_cft_update_from_install)
    else
        vers=$(get_cft_version)
        update=$(get_cft_update)
    fi
    if [[ $? -ne 0 || "$vers" = "" ]]; then
        return -1
    fi
    if [[ $? -ne 0 || "$update" = "" ]]; then
        return -1
    fi

    x=$(echo $vers | cut -d '.' -f 1)
    y=$(echo $vers | cut -d '.' -f 2)
    x=$(printf "%03d" $x)
    y=$(printf "%03d" $y)
    echo $x$y$update
    return 0
}

cft_version_str_to_num()
{
    vers=$1
    x=$(echo $vers | cut -d '.' -f 1)
    y=$(echo $vers | cut -d '.' -f 2)
    z=$(echo $vers | cut -d '.' -f 3)
    x=$(printf "%03d" $x)
    y=$(printf "%03d" $y)
    echo $x$y$z
    return 0
}

get_runtime_version_num()
{
    vers=$(cat ${CFT_CFTDIRRUNTIME}/.version 2>/dev/null)
    echo $vers
    return 0
}

set_runtime_version_num()
{
    vers=$1
    if [[ -z "$vers" ]]; then
        log_fatal "Version number is empty"
        return -1
    fi

    echo $vers > ${CFT_CFTDIRRUNTIME}/.version
    if [[ $? -ne 0 ]]; then
        log_fatal "Failed to set runtime version number"
        return -1
    fi

    log_info "Runtime version set to $vers"
    return 0
}

is_kubernetes() {
    if [[ -n "$KUBERNETES_SERVICE_HOST" ]] || [[ -d "/var/run/secrets/kubernetes.io" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

