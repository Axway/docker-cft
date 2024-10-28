#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

get_value()
{
    in=$*

    if [ -f "$in" ]; then
        out=$(cat $in)
    else
        out=$($in) >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            out=$in
        fi
    fi
    echo $out
}
echo "INFO: server: $CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT"

if [[ -z "${CFT_API_PASSWORD}" ]]; then
    # TOKEN mode
    echo "INFO: credentials (token)"
    token=$(get_value $CFT_API_TOKEN)
    echo Authorization: Bearer $token > /tmp/auth.txt
    auth='-H @/tmp/auth.txt'
else
    # LOGIN/PASSWORD mode
    echo "INFO: credentials (login/password)"
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
    echo "ERROR: curl GET /healthz failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    echo "ERROR: GET /healthz returned $out"
    exit 1
else
    echo "INFO: server is up"
fi

if [[ -n $CFT_CHECKVERSION && "$CFT_CHECKVERSION" = "false" ]]; then
    echo "INFO: new and remote versions comparison skipped."
else
    # compare local and remote versions
    new_version=$(cat /opt/axway/cft/.transfer_cft.properties | grep -e CFT_Version | cut -d '=' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve CFT_Version from /opt/axway/cft/.transfer_cft.properties"
        exit 1
    fi

    new_update=$(cat /opt/axway/cft/.transfer_cft.properties | grep -e CFT_Update | cut -d '=' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve CFT_Update from /opt/axway/cft/.transfer_cft.properties"
        exit 1
    fi

    new_version=$new_version"."$new_update
    echo "The new version is $new_version. Let's retrieve the current deployment version..."

    cmd="curl $curl_opt $auth -X GET $base_url/cft/api/v1/about"
    out=$($cmd)
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET /about failed, rc=$rc, output=$out"
        exit 1
    else
        code=$(echo $out | sed s/{.*}//)
        if [ "$code" -ne "200" ]; then
            echo "ERROR: GET /about returned $code"
            exit 1
        fi
    fi

    json=$(echo $out | grep -o '{.*}')
    remote_version=$(echo $json | jq '.version' | cut -d '"' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve version from $json"
        exit 1
    fi

    remote_update=$(echo $json | jq '.level' | cut -d '"' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve level from $json"
        exit 1
    fi

    remote_version=$remote_version"."$remote_update
    if [ "$new_version" = "$remote_version" ]; then
        echo "INFO: new version $new_version equals to deployment version $remote_version, skip export."
        exit 0
    else
        echo "INFO: new version $new_version differs from deployment version $remote_version, proceed to export."
    fi
fi

# export databases
cmd="curl $curl_opt $auth -X PUT $base_url/cft/api/v1/cft/container/export"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "ERROR: curl PUT /cft/container/export failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    echo "ERROR: PUT /cft/container/export returned $out"
    exit 1
else
    echo "INFO: databases are successfully exported"
fi

exit 0
