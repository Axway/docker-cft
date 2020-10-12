#!/bin/bash
#

HELM_NAME="transfer-cft"

set -uoe pipefail

COL_MSG="\033[92m"
COL_CLEAR="\033[0m"

DEBUG() {
    echo
    echo -e "$COL_MSG> $@$COL_CLEAR"
    $@
}

if [ -f "./.env" ]; then
    . ./.env
fi

case "${1:-}" in
    "create")
        DEBUG kubectl get secrets
        DEBUG helm upgrade --install "$HELM_NAME" ./transfer-cft --set image.repository=cft/cft,image.tag=3.7
    ;;

    "delete")
        DEBUG helm delete $HELM_NAME
    ;;

    "wait-started")
        DEBUG kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=transfer-cft --timeout=10s
    ;;

    "wait-delete")
        DEBUG kubectl wait --for=delete pod -l app.kubernetes.io/name=transfer-cft --timeout=10s
    ;;

    "replace")
        DEBUG helm upgrade --install "$HELM_NAME" ./transfer-cft --set image.repository=cft/cft,image.tag=3.7
    ;;

    "status")
        DEBUG kubectl get statefulset/transfer-cft
    ;;

    "inspect")
        DEBUG kubectl describe statefulset/transfer-cft
        DEBUG kubectl describe service/transfer-cft
    ;;

    "logs")
        DEBUG kubectl logs statefulset/transfer-cft
    ;;

    *)
        if [ ! -z "${1:-}" ]; then
            echo "unsupported command $1"
        fi
        echo "$0 create | delete | replace | status | inspect | logs | wait-ready"
    ;;
esac
