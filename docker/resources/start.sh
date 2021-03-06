#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.
#
set -Eeo pipefail
trap 'rm $lockfile' SIGTERM SIGHUP SIGINT EXIT
trap 'finish' SIGTERM SIGHUP SIGINT EXIT

file_diff()
{
    sha1=$1
    new=$2
    
    c1=""
    if [ -f $sha1 ]; then
        c1=`cat $1`
    fi
    c2=`file_checksum $new`
    if [ "$c1" = "$c2" ]; then
        echo 0;
    else
        echo 1;
    fi
}

file_checksum()
{
    fname=$1
    sha1sum $fname | cut -d ' ' -f 1
}

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

get_service_value()
{
    if [ -n "$CFT_KUBERNETES_SERVICE" ]; then
        service=$(echo $CFT_KUBERNETES_SERVICE | sed 's/-/_/g')
        key=$service''_SERVICE_''$1
        val=$(env | grep $key | cut -d = -f 2)
        echo $val
    else
        echo ""
    fi
}

get_service_host()
{
    get_service_value "HOST"
}

get_service_copilotcg()
{
    get_service_value "COPILOTCG"
}

check_fqdn()
{
    host=$(get_service_host)
    if [ -n "$CFT_FQDN" ]; then
        echo "CFT_FQDN is $CFT_FQDN"
    elif [ -n "$host" ]; then
        export CFT_FQDN=$host
        echo "CFT_FQDN is $CFT_FQDN"
    else
        echo "ERR: CFT_FQDN environment variable is not defined nor SERVICE_HOST."
        exit 1
    fi

    case $CFT_FQDN in
         *_*)
              echo "ERR: CFT_FQDN must not contains a '_'"
              exit 1
         ;;
    esac
}

customize_runtime()
{
    echo "INF: Customizing the runtime..."

    # License key update
    if [ -n "$CFT_KEY" ]; then
        echo $(get_value $CFT_KEY) >$CFTKEY
    fi

    # FQDN
    if [ -n "$CFT_LOAD_BALANCER_HOST" ]; then
        CFTUTIL /m=2 uconfset id='cft.full_hostname', value=$CFT_LOAD_BALANCER_HOST
        CFTUTIL /m=2 uconfset id='cft.multi_node.load_balancer.host', value=$CFT_LOAD_BALANCER_HOST
    else
        CFTUTIL /m=2 uconfset id='cft.full_hostname', value=$CFT_FQDN
        CFTUTIL /m=2 uconfset id='cft.multi_node.load_balancer.host', value=$CFT_FQDN
    fi
    if [ -n "$CFT_LOAD_BALANCER_PORT" ]; then
        CFTUTIL /m=2 uconfset id='cft.multi_node.load_balancer.port', value=$CFT_LOAD_BALANCER_PORT
    else
        CFTUTIL /m=2 uconfset id='cft.multi_node.load_balancer.port', value=$CFT_COPILOT_CG_PORT
    fi

    # User customization
    customdir="$HOME/custom"
    if [ ! -d $customdir ]; then
        mkdir $customdir
    fi

    if [[ "$CFT_CG_ENABLE" = "YES" ]]; then

        if [ -n "$CFT_CG_SHARED_SECRET" ]; then
            CFTUTIL /m=2 uconfset id='cg.shared_secret', value=$(get_value $CFT_CG_SHARED_SECRET)
        fi

        if [[ -n "$CFT_CG_AGENT_NAME" ]]; then
            echo "INF: Setting the customized Agent Name $CFT_CG_AGENT_NAME..."
            CFTUTIL /m=2 uconfset id='cg.metadata.agent.value', value=$CFT_CG_AGENT_NAME
        fi

        # CG CA certificate
        if [[ -n "$USER_CG_CA_CERT"  && ! -e "$USER_CG_CA_CERT"  ]]; then
            echo "ERR: CG CA certificate $USER_CG_CA_CERT not found."
            exit 1
        elif [[ -n "$USER_CG_CA_CERT" ]]; then
            sha1=$customdir"/USER_CG_CA_CERT.sha1"
            rc=`file_diff $sha1 $USER_CG_CA_CERT`
            if [ $rc != 0 ]; then
                echo "INF: Setting the customized CG CA certificate $USER_CG_CA_CERT..."
                PKIUTIL pkicer id='CG_CA', rootcid='CG_CA', itype='root', iname=$USER_CG_CA_CERT, pkipassw='CFT', mode='replace'
                if [ $? != 0 ]; then
                    echo "ERR: Failed to insert the CG CA certificate $USER_CG_CA_CERT"
                    exit 1
                fi
                CFTUTIL /m=2 uconfset id='cg.ca_cert_id', value='CG_CA'
                file_checksum $USER_CG_CA_CERT >$sha1
                echo "INF: Customized CG CA certificate $USER_CG_CA_CERT set."
            fi
        fi
    fi

    # Sentinel CA certificate
    if [[ -n "$USER_SENTINEL_CA_CERT" && ! -e "$USER_SENTINEL_CA_CERT" ]]; then
        echo "ERR: Sentinel CA certificate $USER_SENTINEL_CA_CERT not found."
        exit 1
    elif [[ -n "$USER_SENTINEL_CA_CERT" ]]; then
        sha1=$customdir"/USER_SENTINEL_CA_CERT.sha1"
        rc=`file_diff $sha1 $USER_SENTINEL_CA_CERT`
        if [ $rc != 0 ]; then
            echo "INF: Setting the customized Sentinel CA certificate $USER_SENTINEL_CA_CERT..."
            PKIUTIL pkicer id='SENTINEL_CA', rootcid='SENTINEL_CA', itype='root', iname=$USER_SENTINEL_CA_CERT, pkipassw='CFT', mode='replace'
            if [ $? != 0 ]; then
                echo "ERR/ Failed to insert the Sentinel CA certificate $USER_SENTINEL_CA_CERT"
                exit 1
            fi
            CFTUTIL /m=2 uconfset id='sentinel.xfb.ca_cert_id', value='SENTINEL_CA'
            file_checksum $USER_SENTINEL_CA_CERT >$sha1
            echo "INF: Customized Sentinel CA certificate $USER_SENTINEL_CA_CERT set."
        fi
    fi

    # Copilot server certificate
    if [[ -n "$USER_COPILOT_CERT" && ! -e "$USER_COPILOT_CERT" ]]; then
        echo "ERR: Copilot server certificate $USER_COPILOT_CERT not found."
        exit 1
    elif [[ -n "$USER_COPILOT_CERT" ]]; then
        sha1=$customdir"/USER_COPILOT_CERT.sha1"
        rc=`file_diff $sha1 $USER_COPILOT_CERT`
        if [ $rc != 0 ]; then
            echo "INF: Setting the customized Copilot certificate $USER_COPILOT_CERT..."
            CFTUTIL /m=2 uconfset id='copilot.ssl.SslCertFile', value=$USER_COPILOT_CERT
            CFTUTIL /m=2 uconfset id='copilot.ssl.SslCertPassword', value=$(get_value $USER_COPILOT_CERT_PASSWORD)
            file_checksum $USER_COPILOT_CERT >$sha1
            echo "INF: Customized Copilot certificate $USER_COPILOT_CERT set."
        fi
    fi

    # Passport AM persistent cache
    if [ -n "$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL" ]; then
        CFTUTIL /m=2 uconfset id='am.passport.persistency.check_interval', value=$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL
    fi

    # User custom start-up script
    if [[ -n "$USER_SCRIPT_START" && ! -e "$USER_SCRIPT_START" ]]; then
        echo "ERR: Custom start-up script $USER_SCRIPT_START not found."
        exit 1
    elif [[ -n "$USER_SCRIPT_START" ]]; then
        $USER_SCRIPT_START
        if [[ $? = 0 ]]; then
            echo "INF: Custom start-up script $USER_SCRIPT_START returns 0"
        else
            echo "ERR: Custom start-up script $USER_SCRIPT_START returns $?"
            exit 1
        fi
    fi

    echo "INF: runtime customized."
}

# Propagating signals
stop()
{
    if [[ "$CFT_MULTINODE_ENABLE" = "NO" ]]; then
        cft stop
        cft force-stop
    fi
    copstop -f &
    if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
        echo "INF: Remove HOST $HOSTNAME"
        cft remove_host -hostname $HOSTNAME
    fi
}

kill ()
{
    kill -9 -1
}

finish()
{
    stop
    sleep 2
    kill
}

# Check if server is up
healthz()
{
    cmd="env -i curl -k -s -w %{http_code} https://localhost:$CFT_RESTAPI_PORT/healthz"
    out=$($cmd)
    rc=$?
    if [ "$rc" -ne "0" ]; then
        echo "ERR: curl GET /healthz failed, rc=$rc, output=$out"
        return -1
    elif [ "$out" != "200" ]; then
        echo "ERR: GET /healthz returned $out"
        return -1
    fi
    return 0
}

check_fqdn

parent_dir="$(dirname -- "$(realpath -- "$CFT_CFTDIRRUNTIME")")"
lockfile=$parent_dir/runtimelock
(
flock 10
echo "INF: $HOSTNAME got lock to create runtime"

if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
    echo "INF: runtime exists"
    # import databases...
    ./import_bases.sh
else
    ./runtime_create.sh
    # user custom init script
    if [[ -n "$USER_SCRIPT_INIT" && ! -e "$USER_SCRIPT_INIT" ]]; then
        echo "ERR: Custom initialization script $USER_SCRIPT_INIT not found."
        exit 1
    elif [[ -n "$USER_SCRIPT_INIT" ]]; then
        $USER_SCRIPT_INIT
        if [[ $? = 0 ]]; then
            echo "INF: Custom initialization script $USER_SCRIPT_INIT returns 0"
        else
            echo "ERR: Custom initialization script $USER_SCRIPT_INIT returns $?"
            exit 1
        fi
    fi
fi
) 10<>$lockfile
rm -f $lockfile

# load profile
cd $CFT_CFTDIRRUNTIME
. ./profile

# customize the runtime
lockfile=$parent_dir/customlock
(
if flock -n 11 ; then
    echo "INF: $HOSTNAME got the lock to customize runtime"
    customize_runtime
else
    echo "INF: $HOSTNAME did NOT get the lock to customize runtime"
    echo "INF: Wait for the customization to finish ($HOSTNAME)"
    while [ -f $lockfile ]; do
        sleep 1
    done
fi
) 11<>$lockfile
rm -f $lockfile

# show info about cft
CFTUTIL /m=2 about

if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    echo "INF: Add HOST $HOSTNAME"
    
    if [ -n "$CFT_KUBERNETES_SERVICE" ]; then
        servicename=$(echo $CFT_KUBERNETES_SERVICE | sed 's/\(.*\)/\L\1/')

        cft add_host -hostname $HOSTNAME -host $HOSTNAME.$servicename
    else
        cft add_host -hostname $HOSTNAME -host $CFT_FQDN
    fi
fi

# show customize information
CFTUTIL /m=2 LISTUCONF scope=user

if cft start ; then
    echo "INF: cft start success"
else
    echo "ERR: cft start returns:"$?
    if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
        cat run/cft[0-9][0-9].out
        cat log/cftlog[0-9][0-9]
    else
        cat run/cft.out
        cat log/cftlog
    fi
    exit 1
fi

# start:
if copstart ; then
    echo "INF: copstart success"
else
    echo "ERR: copstart returns:"$?
    if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
        cat run/copsmng.$HOSTNAME.out
        cat run/copui.$HOSTNAME.trc
        cat run/coprests.$HOSTNAME.out
        cat run/copsxpam.$HOSTNAME.out
    else
        cat run/copsmng.out
        cat run/copui.trc
        cat run/coprests.out
        cat run/copsxpam.out
    fi
    exit 1
fi

# logs on stdout
if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    tail -v run/cft[0-9][0-9].out -F run/copsmng.$HOSTNAME.out -F run/copui.$HOSTNAME.trc -F run/copsxpam.$HOSTNAME.out -F log/cftlog[0-9][0-9] &
else
    tail -v run/cft.out -F run/copsmng.out -F run/copui.trc -F run/copsxpam.out -F log/cftlog &
fi

# run loop
echo "INF: waiting copilot..."
healthz
while [ $? -eq 0 ]; do
    sleep ${CFT_STATUS_SLEEP:-10}
    healthz
done
