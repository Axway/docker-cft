#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

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
