#!/bin/bash
#

POD_NAME="cft-pod"
CONTAINER_NAME="cft"
VOLUME_NAME="cft_data"
SECRET_NAME="cft_secrets"

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
        DEBUG podman play kube ./secrets.yml
        DEBUG podman play kube ./podman.yml
        echo "Pod '$POD_NAME' created"
    ;;

    "delete")
        DEBUG podman pod stop $POD_NAME
        DEBUG podman pod rm -f $POD_NAME
        echo "Pod '$POD_NAME' was deleted (the volume $VOLUME_NAME remain)"
    ;;

    "purge")
        DEBUG podman pod stop $POD_NAME
        DEBUG podman pod rm -f $POD_NAME
        DEBUG podman volume rm "$VOLUME_NAME"
        DEBUG podman secret rm "$SECRET_NAME"
        echo "Pod '$POD_NAME' and respective volume ($VOLUME_NAME) were deleted"
    ;;

    "update")
        DEBUG podman pod stop $POD_NAME
        DEBUG podman pod rm -f $POD_NAME
        DEBUG podman play kube ./podman.yml
        echo "Pod '$POD_NAME' was updated"
    ;;

    "status")
        DEBUG podman pod ps -f name=$POD_NAME
    ;;

    "stop")
        DEBUG podman pod stop $POD_NAME
    ;;

    "start")
        DEBUG podman pod start $POD_NAME
    ;;

    "restart")
        DEBUG podman pod restart $POD_NAME
    ;;

    "top")
        DEBUG podman container top $POD_NAME-$CONTAINER_NAME
    ;;

    "inspect")
        DEBUG podman inspect $POD_NAME
        DEBUG podman inspect $POD_NAME-$CONTAINER_NAME
        DEBUG podman inspect "$VOLUME_NAME"
        DEBUG podman secret inspect "$SECRET_NAME"
    ;;

    "logs")
        DEBUG podman logs $POD_NAME-$CONTAINER_NAME
    ;;

    "help")
        echo "--------"
        echo " HELP"
        echo "--------"
        echo "Usage: ./podman_helper.sh [option]"
        echo "  options:"
        echo "    create  : Create volume $VOLUME_NAME if needed and create pod $POD_NAME using podman.yml"
        echo "    delete  : Stop and remove pod $POD_NAME"
        echo "    purge   : Stop and remove pod $POD_NAME and delete volume $VOLUME_NAME"
        echo "    update  : Stop and remove pod $POD_NAME and create a new pod $POD_NAME using podman.yml"
        echo "    status  : Give current state of pod $POD_NAME"
        echo "    stop    : Stop pod $POD_NAME"
        echo "    start   : Start pod $POD_NAME"
        echo "    restart : Restart pod $POD_NAME"
        echo "    top     : Display the running processes of container $POD_NAME-$CONTAINER_NAME"
        echo "    inspect : Inspect pod $POD_NAME, container $POD_NAME-$CONTAINER_NAME and volume $VOLUME_NAME"
        echo "    logs    : Fetch the logs of container $POD_NAME-$CONTAINER_NAME"
        echo "    help    : Show the usage of the script file"
        echo ""
    ;;

    *)
        if [ ! -z "${1:-}" ]; then
            echo "unsupported command $1"
        fi
        echo "$0 create | delete | purge | update | status | stop | start | restart | top | inspect | logs | help"
    ;;
esac
