#!/bin/bash
#
set -euo pipefail

sleep 4
nc -z cft 1768
if [ "$?" -ne "0" ]; then
  echo "Fail to connect to cft"
  exit 1
fi
echo "Successful connection to cft"

curl http://$CFT_FQDN:1766/wsdl > /dev/null
if [ "$?" -ne "0" ]; then
  echo "Fail to access webservice"
  exit 1
fi
echo "Successful access to webservice"

curl -k https://$CFT_FQDN:1768/cft/api/v1/api-docs/service.json > /dev/null
if [ "$?" -ne "0" ]; then
  echo "Fail to access rest api"
  exit 1
fi
echo "Successful access to rest api"
