#!/bin/bash
#

HELM_NAME="cft"

CFT_IMAGE_REPOSITORY="docker.repository.axway.com/transfercft-docker-prod/3.10/cft"
CFT_IMAGE_TAG="3.10.2206"

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
        DEBUG helm upgrade --install "$HELM_NAME" ./transfer-cft --set image.repository=${CFT_IMAGE_REPOSITORY},image.tag=${CFT_IMAGE_TAG}
    ;;

    "delete")
        DEBUG helm delete $HELM_NAME
    ;;

    "wait-ready")
        DEBUG kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=transfer-cft --timeout=10s
    ;;

    "wait-delete")
        DEBUG kubectl wait --for=delete pod -l app.kubernetes.io/name=transfer-cft --timeout=10s
    ;;

    "replace")
        DEBUG helm upgrade --install "$HELM_NAME" ./transfer-cft --set image.repository=${CFT_IMAGE_REPOSITORY},image.tag=${CFT_IMAGE_TAG}
    ;;

    "status")
        DEBUG kubectl get statefulset/"$HELM_NAME"-transfer-cft
    ;;

    "inspect")
        DEBUG kubectl describe statefulset/"$HELM_NAME"-transfer-cft
        DEBUG kubectl describe service/"$HELM_NAME"-transfer-cft
    ;;

    "logs")
        DEBUG kubectl logs statefulset/"$HELM_NAME"-transfer-cft
    ;;

    *)
        if [ ! -z "${1:-}" ]; then
            echo "unsupported command $1"
        fi
        echo "$0 create | delete | replace | status | inspect | logs | wait-ready | wait-delete"
    ;;
esac
