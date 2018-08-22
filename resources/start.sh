#!/bin/sh
#

set -eo pipefail

case $CFT_FQDN in
     *_*)
          echo "hostname MUST NOT have '_'"
          exit 1
     ;;
esac

# create the runtime
if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
    echo "reuse runtime..."
else
    ./runtime_create.sh
fi

# load profile
cd $CFT_CFTDIRRUNTIME
. ./profile

# show info about cft
CFTUTIL /m=2 about

# show customize information
CFTUTIL /m=2 LISTUCONF scope=user

# ensure logs are empty before starting
rm -f run/cft.out run/copsmng.out log/cftlog run/copui.trc

# start:
copstart
echo "copstart returns:"$?

cft start
echo "cft start returns:"$?

# logs on stdout
tail -v -F run/cft.out -F run/copsmng.out -F log/cftlog -F run/copui.trc -F run/coprests.out -F run/copsxpam.out -F run/copstart.out &

# Propagating signals
finish() {
    cft force-stop
    copstop -f
    sleep 2

    kill -9 -1
}
trap finish EXIT

# run loop
echo "waiting copilot..."
while copstatus; do
    sleep ${CFT_STATUS_SLEEP:-10}
done

