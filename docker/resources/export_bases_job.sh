#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

echo "INFO: server: $CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT"
echo "INFO: credentials: $CFT_API_LOGIN:$CFT_API_PASSWORD"

# is server up
cmd="curl -k -s -w %{http_code} https://$CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT/healthz"
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

pass=$(cat $CFT_API_PASSWORD)
if [[ -n $CFT_CHECKVERSION && "$CFT_CHECKVERSION" = "false" ]]; then
    echo "INFO: new and remote versions comparison skipped."
else
    # compare local and remote versions
    new_version=$(cat /opt/axway/cft/.transfer_cft.properties | grep -e CFT_Version | cut -d '=' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve version from /opt/axway/cft/.transfer_cft.properties"
        exit 1
    fi

    cmd="curl -k -s -w %{http_code} -u $CFT_API_LOGIN:$pass https://$CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT/cft/api/v1/about"
    out=$($cmd)
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET /about failed, rc=$rc, output=$out"
        exit 1
    else
        code=$(echo $out | cut -d '}' -f 2)
        if [ "$code" -ne "200" ]; then
            echo "ERROR: GET /about returned $code"
            exit 1
        fi
    fi
    remote_version=$(echo $out | jq '.version' | cut -d '"' -f 2)
    if [ "$?" -ne "0" ]; then
        echo "ERROR: failed to retrieve version from $out"
        exit 1
    fi

    if [ "$new_version" = "$remote_version" ]; then
        echo "INFO: new version $new_version equals to $remote_version, skip export."
        exit 0
    else
        echo "INFO: new version $new_version differs from $remote_version, proceed to export."
    fi
fi

# export databases
cmd="curl -k -s -w %{http_code} -u $CFT_API_LOGIN:$pass -X PUT https://$CFT_RESTAPI_HOST:$CFT_RESTAPI_PORT/cft/api/v1/cft/container/export"
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
