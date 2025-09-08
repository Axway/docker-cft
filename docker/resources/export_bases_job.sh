#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

source ./utils.sh

log_info "server: $CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT"

if [[ -z "${CFT_API_PASSWORD}" ]]; then
    # TOKEN mode
    log_info "credentials (token)"
    token=$(get_value $CFT_API_TOKEN)
    echo Authorization: Bearer $token > /tmp/auth.txt
    auth='-H @/tmp/auth.txt'
else
    # LOGIN/PASSWORD mode
    log_info "credentials (login/password)"
    pass=$(get_value $CFT_API_PASSWORD)
    auth="-u $CFT_API_LOGIN:$pass"
fi

curl_opt="-k -s -w %{http_code}"
base_url="https://$CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT"

# is server up
cmd="curl $curl_opt $base_url/healthz"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    log_error "curl GET /healthz failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    log_error "GET /healthz returned $out"
    exit 1
else
    log_info "server is up"
fi

if [[ -n $CFT_CHECKVERSION && "$CFT_CHECKVERSION" = "false" ]]; then
    log_info "new and remote versions comparison skipped."
else
    # compare local and remote versions
    new_version=$(cat /opt/axway/cft/.transfer_cft.properties | grep -e CFT_Version | cut -d '=' -f 2)
    if [ "$?" -ne "0" ]; then
        log_error "failed to retrieve CFT_Version from /opt/axway/cft/.transfer_cft.properties"
        exit 1
    fi

    new_update=$(cat /opt/axway/cft/.transfer_cft.properties | grep -e CFT_Update | cut -d '=' -f 2)
    if [ "$?" -ne "0" ]; then
        log_error "failed to retrieve CFT_Update from /opt/axway/cft/.transfer_cft.properties"
        exit 1
    fi

    new_version=$new_version"."$new_update
    log_info "The new version is $new_version. Let's retrieve the current deployment version..."

    cmd="curl $curl_opt $auth -X GET $base_url/cft/api/v1/about"
    out=$($cmd)
    rc=$?
    if [ "$rc" -ne "0" ]; then
        log_error "curl GET /about failed, rc=$rc, output=$out"
        exit 1
    else
        code=$(echo $out | sed s/{.*}//)
        if [ "$code" -ne "200" ]; then
            log_error "GET /about returned $code"
            exit 1
        fi
    fi

    json=$(echo $out | grep -o '{.*}')
    remote_version=$(echo $json | jq '.version' | cut -d '"' -f 2)
    if [ "$?" -ne "0" ]; then
        log_error "failed to retrieve version from $json"
        exit 1
    fi

    remote_update=$(echo $json | jq '.level' | cut -d '"' -f 2)
    if [ "$?" -ne "0" ]; then
        log_error "failed to retrieve level from $json"
        exit 1
    fi

    remote_version="$remote_version"."$remote_update"
    remote_version_num=$(cft_version_str_to_num $remote_version)
    if [ "$?" -ne "0" ]; then
        log_error "failed to convert remote version $remote_version to number"
        exit 1
    fi

    new_version_num=$(cft_version_str_to_num $new_version)
    if [ "$?" -ne "0" ]; then
        log_error "failed to convert new version $new_version to number"
        exit 1
    fi

    if [ "$new_version_num" = "$remote_version_num" ]; then
        log_info "new version $new_version equals to deployment version $remote_version, skip export."
        exit 0
    elif [ "$remote_version_num" -ge "0030102509" ]; then
        # Remote export no longer required
        log_info "remote version $remote_version greater than or equals to 3.10.2509, skip export."
    else
        log_info "new version $new_version differs from deployment version $remote_version, proceed to export."
    fi
fi

# export databases
cmd="curl $curl_opt $auth -X PUT $base_url/cft/api/v1/cft/container/export"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    log_error "curl PUT /cft/container/export failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    log_error "PUT /cft/container/export returned $out"
    exit 1
else
    log_info "databases are successfully exported"
fi

exit 0
