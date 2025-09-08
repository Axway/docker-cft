#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

check_liveness_container()
{
    local service="$1"
    local url="https://$service:$CFT_RESTAPI_PORT/healthz"
    local cmd="curl -k -s -w %{http_code} $url"
    local out
    local rc

    out=$($cmd)
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl GET $url failed, rc=$rc, output=$out"
        return 1
    elif [[ "$out" != "200" ]]; then
        echo "ERROR: GET $url returned $out"
        return 1
    else
        echo "INFO: REST API $service is up"
        return 0
    fi
}

check_readiness_container()
{
    local service="$1"
    local expected_code="$2"
    local debug="${3:-}"
    local uri="https://$service:$CFT_RESTAPI_PORT/healthz?component=cft"
    local out
    local rc
    local http_code
    local json_part

    out=$(curl -k -s -w %{http_code} "$uri")
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl GET $uri failed, rc=$rc, output=$out"
        return 1
    elif [[ "$out" != "$expected_code" ]]; then
        echo "ERROR: GET $uri returned $out, expected $expected_code"
        return 1
    else
        echo "INFO: Transfer CFT readiness returned $out"
    fi

    if [[ "$debug" == "debug" ]]; then
        # Debug section
        echo "DEBUG enabled: calling /cft/state"
        uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/cft/state"
        out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" "$uri")

        http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
        json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
        if [[ "$http_code" != "200" ]]; then
            echo "ERROR: GET $uri returned http_code=$http_code, output=$json_part"
            return 1
        else
            echo "INFO: GET $uri returned http_code=$http_code, output=$json_part"
            return 0
        fi
    fi
}

check_liveness()
{
    local service="$1"

    if [[ "$service" == "nginx" ]]; then
        service="test-cft-1 test-cft-2"
    fi

    for container in $service; do
        echo "INFO: checking liveness of container $container..."
        check_liveness_container "$container"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    done

    return 0
}

check_readiness()
{
    local service="$1"
    local expected_code="$2"
    local debug="${3:-}"

    if [[ "$service" == "nginx" ]]; then
        service="test-cft-1 test-cft-2"
    fi

    for container in $service; do
        echo "INFO: checking readiness of container $container..."
        check_readiness_container "$container" "$expected_code" "$debug"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    done

    return 0
}

wait_startup()
{
    local service="$1"
    local timeout="$2"
    local started=0
    local i=0
    local rc=1

    # wait liveness
    echo "INFO: waiting for $service liveness $i/$timeout..."
    while [[ $i -lt $timeout && $started -eq 0 ]]; do
        if check_liveness "$service"; then
            started=1
            rc=0
        else
            i=$((i+1))
            echo "INFO: waiting for $service liveness $i/$timeout..."
            sleep 1
        fi
    done

    if [[ $started -eq 0 ]]; then
        return 1
    fi

    # wait readiness
    started=0
    i=0
    rc=1
    echo "INFO: waiting for $service readiness $i/$timeout..."
    while [[ $i -lt $timeout && $started -eq 0 ]]; do
        if check_readiness "$service" 200; then
            started=1
            rc=0
        else
            i=$((i+1))
            echo "INFO: waiting for $service readiness $i/$timeout..."
            sleep 1
        fi
    done

    return $rc
}

export_database()
{
    local service="$1"
    local uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/cft/container/export"
    local method="PUT"
    local out
    local rc

    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri")
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri failed, rc=$rc, output=$out"
        return 1
    elif [[ "$out" != "200" ]]; then
        echo "ERROR: $method $uri returned $out"
        return 1
    else
        echo "INFO: databases are successfully exported"
        return 0
    fi
}

test_run_transfer()
{
    local service="$1"
    local ida="sut_$service"
    local uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/transfers/files/outgoings?part=paris&idf=zouzou"
    local method="POST"
    local out
    local rc
    local http_code
    local json_part

    ida=${ida^^} # convert to uppercase
    
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"wphases\":\"x\",\"ida\":\"${ida}\"}")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "201" ]]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: Transfer successfully executed, rc=$rc, http_code=$http_code, output=$json_part"
        return 0
    fi
}

test_check_transfer()
{
    local service="$1"
    local ida="sut_$service"
    local uri
    local out
    local rc
    local http_code
    local json_part
    local res

    ida=${ida^^} # convert to uppercase
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/transfers?part=paris&idf=zouzou&ida=${ida}"
    
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" "$uri" -H "accept: application/json" -H "Content-Type: application/json")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ $rc -ne 0 ]]; then
        echo "ERROR: curl GET $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "200" ]]; then
        echo "ERROR: GET $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: GET $uri returned http_code=$http_code, output=$json_part"
        # check if transfer is found
        res=$(echo "$json_part" | jq -r '.numberOfSelectedRecords')
        if [[ "$res" != "1" ]]; then
            echo "ERROR: GET $uri returned $res transfers, expected 1"
            return 1
        fi

        # check if ida is correct
        res=$(echo "$json_part" | jq -r '.transfers[0].ida')
        if [[ "$ida" != "$res" ]]; then
            echo "ERROR: GET $uri returned transfer with ida=$res, expected $ida"
            return 1
        else
            echo "INFO: Transfer found, rc=$rc, http_code=$http_code, output=$json_part"
            return 0
        fi
    fi
}

test_create_data()
{
    local service="$1"
    local uri
    local method
    local out
    local rc
    local http_code
    local json_part

    # create CFTPART
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftpart"
    method="POST"
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"id\":\"sut\",\"type\":\"cftpart\",\"attributes\":{\"prot\":[\"pesit\"]}}")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "201" ]]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$json_part"
    fi

    # create CFTSEND
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftsend/implno"
    method="POST"
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"id\":\"sut\",\"type\":\"cftsendno\",\"attributes\":{\"fname\":\"pub/FTEST\"}}")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "201" ]]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$json_part"
        return 0
    fi
}

test_check_data()
{
    local service="$1"
    local uri
    local method
    local out
    local rc
    local http_code
    local json_part

    # check CFTPART
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftpart/sut"
    method="GET"
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri" -H "accept: application/json" -H "Content-Type: application/json")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "200" ]]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$json_part"
    fi

    # check CFTSEND
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/objects/cftsend/implno/sut"
    method="GET"
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" -X "$method" "$uri" -H "accept: application/json" -H "Content-Type: application/json")
    rc=$?
    http_code=$(echo "$out" | sed 's/.*\([0-9]\{3\}\)$/\1/')
    json_part=$(echo "$out" | sed 's/\([0-9]\{3\}\)$//')
    
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl $method $uri, rc=$rc, output=$json_part"
        return 1
    elif [[ "$http_code" != "200" ]]; then
        echo "ERROR: $method $uri returned http_code=$http_code, output=$json_part"
        return 1
    else
        echo "INFO: $method $uri, rc=$rc, http_code=$http_code, output=$json_part"
        return 0
    fi
}

test_smoke()
{
    local service="$1"
    local uri
    local out
    local rc
    
    echo "Running smoke tests on $service..."

    # Test Copilot port
    if ! nc -z "$service" "$CFT_COPILOT_PORT"; then
        echo "ERROR: failed to connect to $service:$CFT_COPILOT_PORT"
        return 1
    fi
    echo "Successful connection to $service:$CFT_COPILOT_PORT"

    # Retrieve WSDL
    if ! curl "http://$service:$CFT_COPILOT_PORT/wsdl" > /dev/null; then
        echo "ERROR: failed to access webservice"
        return 1
    fi
    echo "Successful access to webservice"

    # Test REST API port
    if ! nc -z "$service" "$CFT_RESTAPI_PORT"; then
        echo "ERROR: failed to connect to $service:$CFT_RESTAPI_PORT"
        return 1
    fi
    echo "Successful connection to $service:$CFT_RESTAPI_PORT"

    # Retrieve REST API doc
    if ! curl -k "https://$service:$CFT_RESTAPI_PORT/cft/api/v1/api-docs/service.json" > /dev/null; then
        echo "ERROR: failed to access rest api"
        return 1
    fi
    echo "Successful access to rest api"

    # check version
    uri="https://$service:$CFT_RESTAPI_PORT/cft/api/v1/about"
    out=$(curl -k -s -w %{http_code} -u "$USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD" "$uri")
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "ERROR: curl GET $uri failed, rc=$rc, output=$out"
        return 1
    else
        echo "INFO: GET $uri returned $out"
    fi

    # Test readiness
    if ! check_readiness "$service" 200; then
        echo "ERROR: $service is not ready"
        return 1
    fi

    echo "Smoke tests on $service OK"
    return 0
}

usage()
{
    cat >&2 << 'EOF'
Usage: $0 service action [parameters]

Actions:
    wait-startup [timeout]          - Wait for service startup (default timeout: 15s)
    check-liveness                  - Check if service is alive
    check-readiness [expected_code] [debug] - Check service readiness (default: 200)
    export-database                 - Export database
    smoke-tests                     - Run smoke tests
    test-run-transfer              - Run a test transfer
    test-check-transfer            - Check test transfer
    test-create-data               - Create test data
    test-check-data                - Check test data
EOF
}

main()
{
    local service="${1:-}"
    local action="${2:-}"
    local rc=0

    if [[ -z "$service" || -z "$action" ]]; then
        echo "Error: service and action are required"
        usage
        return 1
    fi

    echo ">> running $action on $service..."

    case "$action" in
        "smoke-tests")
            test_smoke "$service"
            rc=$?
        ;;
        "wait-startup")
            local timeout="${3:-15}"
            if [[ ! "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -le 0 ]]; then
                echo "Error: timeout must be a positive integer"
                return 1
            fi
            wait_startup "$service" "$timeout"
            rc=$?
        ;;
        "check-readiness")
            local expected_code="${3:-200}"
            local debug="${4:-nodebug}"
            if [[ ! "$expected_code" =~ ^[0-9]+$ ]]; then
                echo "Error: expected_code must be a number"
                return 1
            fi
            check_readiness "$service" "$expected_code" "$debug"
            rc=$?
        ;;
        "check-liveness")
            check_liveness "$service"
            rc=$?
        ;;
        "test-run-transfer")
            test_run_transfer "$service"
            rc=$?
        ;;
        "test-check-transfer")
            test_check_transfer "$service"
            rc=$?
        ;;
        "test-create-data")
            test_create_data "$service"
            rc=$?
        ;;
        "test-check-data")
            test_check_data "$service"
            rc=$?
        ;;
        "export-database")
            export_database "$service"
            rc=$?
        ;;
        *)
            echo "Error: invalid action: $action"
            usage
            return 1
        ;;
    esac

    echo "<< run $action on $service: rc=$rc"
    return $rc
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
