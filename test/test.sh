#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.
#

check_liveness()
{
    # Test liveness
    service=$1
    url=https://$service:$CFT_RESTAPI_PORT/healthz
    cmd="curl -k -s -w %{http_code} $url"
    out=$($cmd)
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET $url failed, rc=$rc, output=$out"
        rc=1
    elif [ "$out" != "200" ]; then
        echo "ERROR: GET $url returned $out"
        rc=1
    else
        echo "INFO: REST API $service is up"
        rc=0
    fi
}

check_readiness()
{
    # Test readiness
    service=$1
    expected_code=$2

    uri="https://$service:$CFT_RESTAPI_PORT/healthz?component=cft"
    out=`curl -k -s -w %{http_code} $uri`
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET $uri failed, rc=$rc, output=$out"
        rc=1
    elif [ "$out" != "$expected_code" ]; then
        echo "ERROR: GET $uri returned $out, expected $expected_code"
        rc=1
    else
        echo "INFO: Transfer CFT readiness returned $out"
        rc=0
    fi
}

wait_startup()
{
    service=$1
    timeout=$2

    started=0
    i=0
    rc=1
    echo "Waiting for $service startup $i/$timeout..."
    while [ $i -lt $timeout ] && [ $started = 0 ]; do
        check_liveness $service
        if [ "$rc" = "0" ]; then
            started=1
            rc=0
        else
            i=$(($i+1))
            echo "Waiting for $service startup $i/$timeout..."
            sleep 1
        fi
    done
}

export_database()
{
    service=$1

    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/cft/container/export"
    method="PUT"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method $uri`
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri failed, rc=$rc, output=$out"
        rc=1
    elif [ "$out" != "200" ]; then
        echo "ERROR: $method $uri returned $out"
        rc=1
    else
        echo "INFO: databases are successfully exported"
        rc=0
    fi
}

test_run_transfer()
{
    service=$1

    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/transfers/files/outgoings?part=paris&idf=zouzou"
    method="POST"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"wphases\":\"x\"}"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "201" ]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: Transfer successfully executed, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi
}

test_check_transfer()
{
    service=$1

    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/transfers/A0000001"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD "$uri" -H "accept: application/json" -H "Content-Type: application/json"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "200" ]; then
        echo "ERROR: GET $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: Transfer found, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi
}

test_create_data()
{
    service=$1

    # create CFTPART
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftpart"
    method="POST"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"id\":\"sut\",\"type\":\"cftpart\",\"attributes\":{\"prot\":[\"pesit\"]}}"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "201" ]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi

    # create CFTSEND
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftsend/implno"
    method="POST"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"id\":\"sut\",\"type\":\"cftsendno\",\"attributes\":{\"fname\":\"pub/FTEST\"}}"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "201" ]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi
}

test_check_data()
{
    service=$1

    # create CFTPART
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftpart/sut"
    method="GET"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method "$uri" -H "accept: application/json" -H "Content-Type: application/json"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "200" ]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi

    # create CFTSEND
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftsend/implno/sut"
    method="GET"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X $method "$uri" -H "accept: application/json" -H "Content-Type: application/json"`
    rc=$?
    http_code=`echo $out | sed s/{.*}//`
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$out"
        rc=1
    elif [ "$http_code" != "200" ]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$out"
        rc=1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$out"
        rc=0
    fi
}

test_smoke()
{
    service=$1
    echo "Running smoke tests on $service..."

    # Test Copilot port
    nc -z $service $CFT_COPILOT_PORT
    if [ "$?" -ne "0" ]; then
      echo "ERROR: failed to connect to $service:$CFT_COPILOT_PORT"
      exit 1
    fi
    echo "Successful connection to $service:$CFT_COPILOT_PORT"

    # Retrive WSDL
    curl http://$service:$CFT_COPILOT_PORT/wsdl > /dev/null
    if [ "$?" -ne "0" ]; then
      echo "ERROR: failed to access webservice"
      exit 1
    fi
    echo "Successful access to webservice"

    # Test REST API port
    nc -z $service $CFT_RESTAPI_PORT
    if [ "$?" -ne "0" ]; then
      echo "ERROR: failed to connect to $service:$CFT_RESTAPI_PORT"
      exit 1
    fi
    echo "Successful connection to $service:$CFT_RESTAPI_PORT"

    # Retrieve REST API doc
    curl -k https://$service:$CFT_RESTAPI_PORT/cft/api/v1/api-docs/service.json > /dev/null
    if [ "$?" -ne "0" ]; then
      echo "ERROR: failed to access rest api"
      exit 1
    fi
    echo "Successful access to rest api"

    # check version
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/about"
    out=`curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD $uri`
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERROR: curl GET $uri failed, rc=$rc, output=$out"
        exit 1
    else
        echo "INFO: GET $uri returned $out"
    fi

    # Test readiness
    check_readiness $service 200
    if [ $rc -ne 0 ]; then
        echo "ERROR: $service is not ready"
        exit 1
    fi

    echo "Smoke tests on $service OK"
    rc=0
}

usage()
{
    echo >&2 "$0: action service"
    echo >&2 "action:"
    echo >&2 "    wait-startup [timeout]"
    echo >&2 "    check-liveness"
    echo >&2 "    check-readiness [expected HTTP code]"
    echo >&2 "    export-database"
    echo >&2 "    smoke-tests"
    echo >&2 "    test-run-transfer"
    echo >&2 "    test-check-transfer"
    echo >&2 "    test-create-data"
    echo >&2 "    test-check-data"
}

rc=0
service=$1
action=$2
echo ">> running $action on $service..."

case "$action" in
    "smoke-tests")
        test_smoke $service
    ;;
    "wait-startup")
        if [[ -n "$3" && $3 -gt 0 ]]; then
            timeout=$3
        else
            timeout=15
        fi
        wait_startup $service $timeout
    ;;
    "check-readiness")
        if [[ -n "$3" && $3 -ge 0 ]]; then
            expected_code=$3
        else
            expected_code=200
        fi
        check_readiness $service $expected_code
    ;;
    "check-liveness")
        check_liveness $service
    ;;
    "test-run-transfer")
        test_run_transfer $service
    ;;
    "test-check-transfer")
        test_check_transfer $service
    ;;
    "test-create-data")
        test_create_data $service
    ;;
    "test-check-data")
        test_check_data $service
    ;;
    "export-database")
        export_database $service
    ;;
    *)
        echo "Error: invalid action: $action"
        usage
        exit 1
    ;;
    esac

echo "<< run $action on $service: rc=$rc"
exit $rc
