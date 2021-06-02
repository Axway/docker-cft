#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.
#

# wait startup
started=0
timeout=15
i=0
echo "Waiting for cft startup $i/$timeout..."
while [ $i -lt $timeout ] && [ $started = 0 ]; do
  nc -z cft $CFT_COPILOT_PORT
  cop_rc=$?
  nc -z cft $CFT_RESTAPI_PORT
  rest_rc=$?
  if [ "$cop_rc" = "0" ] && [ "$rest_rc" = "0" ]; then
    started=1
  else
    i=$(($i+1))
    echo "Waiting for cft startup $i/$timeout..."
    sleep 1
  fi
done

echo "Start testing..."

# Test Copilot port
nc -z cft $CFT_COPILOT_PORT
if [ "$?" -ne "0" ]; then
  echo "ERROR: failed to connect to cft:$CFT_COPILOT_PORT"
  exit 1
fi
echo "Successful connection to cft:$CFT_COPILOT_PORT"

# Retrive WSDL
curl http://$CFT_FQDN:$CFT_COPILOT_PORT/wsdl > /dev/null
if [ "$?" -ne "0" ]; then
  echo "ERROR: failed to access webservice"
  exit 1
fi
echo "Successful access to webservice"

# Test REST API port
nc -z cft $CFT_RESTAPI_PORT
if [ "$?" -ne "0" ]; then
  echo "ERROR: failed to connect to cft:$CFT_RESTAPI_PORT"
  exit 1
fi
echo "Successful connection to cft:$CFT_RESTAPI_PORT"

# Retrieve REST API doc
curl -k https://$CFT_FQDN:$CFT_RESTAPI_PORT/cft/api/v1/api-docs/service.json > /dev/null
if [ "$?" -ne "0" ]; then
  echo "ERROR: failed to access rest api"
  exit 1
fi
echo "Successful access to rest api"

# Test liveness
cmd="curl -k -s -w %{http_code} https://$CFT_FQDN:$CFT_RESTAPI_PORT/healthz"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "ERROR: curl GET /healthz failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    echo "ERROR: GET /healthz returned $out"
    exit 1
else
    echo "INFO: REST API server is up"
fi

# Test readiness
cmd="curl -k -s -w %{http_code} https://$CFT_FQDN:$CFT_RESTAPI_PORT/healthz?component=cft"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "ERROR: curl GET /healthz?component=cft failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    echo "ERROR: GET /healthz?component=cft returned $out"
    exit 1
else
    echo "INFO: Transfer CFT server is up"
fi

# export databases
cmd="curl -k -s -w %{http_code} -u $USER_XFBADM_LOGIN:$USER_XFBADM_PASSWORD -X PUT https://$CFT_FQDN:$CFT_RESTAPI_PORT/cft/api/v1/cft/container/export"
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

# Test readiness, expect 503
cmd="curl -k -s -w %{http_code} https://$CFT_FQDN:$CFT_RESTAPI_PORT/healthz?component=cft"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "ERROR: curl GET /healthz?component=cft failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "503" ]; then
    echo "ERROR: GET /healthz?component=cft returned $out, 503 expected"
    exit 1
else
    echo "INFO: Transfer CFT server is down"
fi

# Test liveness
cmd="curl -k -s -w %{http_code} https://$CFT_FQDN:$CFT_RESTAPI_PORT/healthz"
out=$($cmd)
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "ERROR: curl GET /healthz failed, rc=$rc, output=$out"
    exit 1
elif [ "$out" != "200" ]; then
    echo "ERROR: GET /healthz returned $out"
    exit 1
else
    echo "INFO: REST API server is up"
fi

exit 0
