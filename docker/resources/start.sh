#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
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

get_cft_version()
{
    vers=$(CFTUTIL /m=14 about type=cft|sed -nr 's/.*version\s*=\s*([0-9.]+).*/\1/p')
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $vers
    return 0
}

get_cft_version_num()
{
    vers=$(get_cft_version)
    if [[ $? -ne 0 || "$vers" = "" ]]; then
        return -1
    fi

    x=$(echo $vers | cut -d '.' -f 1)
    y=$(echo $vers | cut -d '.' -f 2)
    x=$(printf "%03d" $x)
    y=$(printf "%03d" $y)
    echo $x$y
    return 0
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
        host=$(hostname)
        export CFT_FQDN=$host
        echo "CFT_FQDN is $CFT_FQDN"
    fi

    case $CFT_FQDN in
         *_*)
              echo "ERR: CFT_FQDN must not contains a '_'"
              exit 1
         ;;
    esac
}

generate_certificate()
{
    cn=$CFT_INSTANCE_ID
    altname=$CFT_FQDN
    echo "INFO: Generating default certificate with CN=$cn, subjectAltName=$altname"
    if [ $(expr length $cn) -gt 64 ]; then
        echo "ERR: CN is too long, cannot generate certificate."
        exit 1
    fi

    if [ -f "conf/generate_copilot_cert.sh" ]; then
        sh -c conf/generate_copilot_cert.sh
    else
        # CREATE CERTIFICATES FOR REST API
        openssl req \
            -x509 \
            -nodes \
            -newkey rsa:4096 \
            -sha256 \
            -days 365 \
            -subj \/CN\=$cn \
            -addext "keyUsage = digitalSignature, keyEncipherment, dataEncipherment" \
            -addext "subjectAltName = DNS:$altname" \
            -keyout conf/pki/rest_api_key.pem \
            -out conf/pki/rest_api_cert.pem
        openssl pkcs12 \
            -inkey conf/pki/rest_api_key.pem \
            -in conf/pki/rest_api_cert.pem \
            -export \
            -out conf/pki/rest_api_cert.p12 \
            -passout pass:restapi

        CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertFile', value='conf/pki/rest_api_cert.p12'
        CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertPassword', value='restapi'
    fi
}

unset_need_restart()
{
    multi=$(cftuconf cft.multi_node.enable)
    multi=${multi,,}
    
    if [ "$multi" = "yes" ] || [ "$multi" = "1" ] ; then
        nodes_number=$(cftuconf cft.multi_node.nodes)
        for ((i=0;  i<$nodes_number; i++ ))
        do
            CFTUTIL /m=14 uconfunset id=cft.multi_node.nodes.$i.need_restart
        done
    else
        CFTUTIL /m=14 uconfunset id=cft.server.run.need_restart
    fi
}

customize_runtime()
{
    echo "INF: Customizing the runtime..."

    # License key update
    if [ -n "$CFT_KEY" ]; then
        echo $(get_value $CFT_KEY) >$CFTKEY
    fi

    # External Address
    if [ -n "$CFT_COPILOT_CG_PORT_EXPOSED" ]; then
        CFTUTIL /m=14 uconfset id='cg.copilot.exposed_port', value=$CFT_COPILOT_CG_PORT_EXPOSED
    fi

    # FQDN
    if [ -n "$CFT_LOAD_BALANCER_HOST" ]; then
        CFTUTIL /m=14 uconfset id='cft.full_hostname', value=$CFT_LOAD_BALANCER_HOST
        CFTUTIL /m=14 uconfset id='cft.multi_node.load_balancer.host', value=$CFT_LOAD_BALANCER_HOST
    else
        CFTUTIL /m=14 uconfset id='cft.full_hostname', value=$CFT_FQDN
        CFTUTIL /m=14 uconfset id='cft.multi_node.load_balancer.host', value=$CFT_FQDN
    fi
    if [ -n "$CFT_LOAD_BALANCER_PORT" ]; then
        CFTUTIL /m=14 uconfset id='cft.multi_node.load_balancer.port', value=$CFT_LOAD_BALANCER_PORT
    else
        CFTUTIL /m=14 uconfset id='cft.multi_node.load_balancer.port', value=$CFT_COPILOT_CG_PORT
    fi

    # User customization
    customdir="$HOME/custom"
    if [ ! -d $customdir ]; then
        mkdir $customdir
    fi

    if [[ "$CFT_CG_ENABLE" = "YES" ]]; then

        if [ -n "$CFT_CG_SHARED_SECRET" ]; then
            CFTUTIL /m=14 uconfset id='cg.shared_secret', value=$(get_value $CFT_CG_SHARED_SECRET)
        fi

        if [[ -n "$CFT_CG_AGENT_NAME" ]]; then
            echo "INF: Setting the customized Agent Name $CFT_CG_AGENT_NAME..."
            CFTUTIL /m=14 uconfset id='cg.metadata.agent.value', value=$CFT_CG_AGENT_NAME
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
                PKIUTIL /m=14 pkicer id='CG_CA', rootcid='CG_CA', itype='root', iname=$USER_CG_CA_CERT, pkipassw='CFT', mode='replace'
                if [ $? != 0 ]; then
                    echo "ERR: Failed to insert the CG CA certificate $USER_CG_CA_CERT"
                    exit 1
                fi
                CFTUTIL /m=14 uconfset id='cg.ca_cert_id', value='CG_CA'
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
            PKIUTIL /m=14 pkicer id='SENTINEL_CA', rootcid='SENTINEL_CA', itype='root', iname=$USER_SENTINEL_CA_CERT, pkipassw='CFT', mode='replace'
            if [ $? != 0 ]; then
                echo "ERR/ Failed to insert the Sentinel CA certificate $USER_SENTINEL_CA_CERT"
                exit 1
            fi
            CFTUTIL /m=14 uconfset id='sentinel.xfb.ca_cert_id', value='SENTINEL_CA'
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
            CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertFile', value=$USER_COPILOT_CERT
            CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertPassword', value=$(get_value $USER_COPILOT_CERT_PASSWORD)
            file_checksum $USER_COPILOT_CERT >$sha1
            echo "INF: Customized Copilot certificate $USER_COPILOT_CERT set."
        fi
    fi

    # Passport AM persistent cache
    if [ -n "$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL" ]; then
        CFTUTIL /m=14 uconfset id='am.passport.persistency.check_interval', value=$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL
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


    # REST API CONFIGURATION
    if [ -n "$CFT_RESTAPI_PORT" ]; then
        CFTUTIL /m=14 uconfset id='copilot.restapi.serverport', value=$CFT_RESTAPI_PORT
        CFTUTIL /m=14 uconfset id='copilot.restapi.enable', value='YES'

        copilot_cert=$(cftuconf copilot.ssl.SslCertFile)
        copilot_cert_id=$(cftuconf copilot.ssl.cert_id)
        registration_id=$(cftuconf cg.registration_id)
        if [ -z "$copilot_cert" ] && [ -z "$copilot_cert_id" ] && [ "$registration_id" = "-1" ]; then
            # CREATE CERTIFICATES FOR REST API
            generate_certificate

            if [ "$CFT_CG_ENABLE" = "YES" ]; then
                echo "INF: Certificates set as temporary, waiting for registration to be completed"
                set_temporary_rest_api_cert 1
            fi
        fi
    else
        CFTUTIL /m=14 uconfset id='copilot.restapi.enable', value='NO'
    fi

    echo "INF: runtime customized."
}

# Propagating signals
stop()
{
    if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
        # load profile
        cd $CFT_CFTDIRRUNTIME
        . ./profile

        if [[ "$CFT_MULTINODE_ENABLE" = "NO" ]]; then
            cft stop
            cft force-stop
        fi
        copstop -f
        if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
            echo "INF: Remove HOST $HOSTNAME"
            cft remove_host -hostname $HOSTNAME
        fi
    fi
}

_kill()
{
    kill -15 -1
}

finish()
{
    stop
    _kill
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

TEMPORARY_CERT_FNAME="./run/.temporary_cert"
is_temporary_rest_api_cert()
{
    if [ -f "$TEMPORARY_CERT_FNAME" ]; then
        echo "1"
    else
        echo "0"
    fi
}

set_temporary_rest_api_cert()
{
    value=$1

    if [ $value -eq 0 -a -f "$TEMPORARY_CERT_FNAME" ]; then
        rm $TEMPORARY_CERT_FNAME
    elif [ $value -eq 1 ]; then
        touch $TEMPORARY_CERT_FNAME
    fi
}

#switch Copilot certificate from temporary to the ones set by CG/FM
switch_cert()
{
    is_temp=$(is_temporary_rest_api_cert)

    if [[ "$CFT_CG_ENABLE" = "YES" && "$is_temp" = "1" ]]; then
        registration_id=$(cftuconf cg.registration_id)
        vers=$(get_cft_version_num)
        if [ "$registration_id" != "-1" ]; then
            echo "INF: Registration completed, switching to certificate received during registration"

            CFTUTIL /m=14 uconfunset id='copilot.ssl.SslCertFile'
            CFTUTIL /m=14 uconfunset id='copilot.ssl.SslCertPassword'
            if [ $vers -ge 003010 ]; then
                CFTUTIL /m=14 uconfunset id='copilot.ssl.cert_id'
                unset_need_restart
            fi
            CFTUTIL reconfig type=am
            set_temporary_rest_api_cert 0
        fi
    fi
}

delete_file()
{
    fname=$1
    echo "deleting $fname..."
    rm -f ${fname}
    echo "$fname deleted"
}

post_upgrade_success()
{
    # Delete backups
    delete_file $CFT_CFTDIRRUNTIME/profile.bak
    delete_file $CFT_CFTDIRRUNTIME/data/cftuconf.dat.bak

    # Remove bases directory
    rm -rf $CFT_EXPORTDIR/export
}

# Testing EULA
ACCEPT_GENERAL_CONDITIONS=`echo $ACCEPT_GENERAL_CONDITIONS | tr '[a-z]' '[A-Z]'`
if [[ -n "$ACCEPT_GENERAL_CONDITIONS" && "$ACCEPT_GENERAL_CONDITIONS" = "YES" ]]; then
    echo "General Terms and Conditions accepted."
else
    echo "General Terms and Conditions not accepted. EXIT"
    exit 1
fi

# Boolean Variables to MAJ
CFT_MULTINODE_ENABLE=`echo $CFT_MULTINODE_ENABLE | tr '[a-z]' '[A-Z]'`
CFT_CG_ENABLE=`echo $CFT_CG_ENABLE | tr '[a-z]' '[A-Z]'`
CFT_SENTINEL_ENABLE=`echo $CFT_SENTINEL_ENABLE | tr '[a-z]' '[A-Z]'`

check_fqdn

parent_dir="$(dirname -- "$(realpath -- "$CFT_CFTDIRRUNTIME")")"
lockfile=$parent_dir/runtimelock
(
flock 10
echo "INF: $HOSTNAME got lock to create runtime"

if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
    is_upgrade=true
    echo "INF: runtime exists"
    # import databases...
    ./import_bases.sh
else
    is_upgrade=false
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
CFTUTIL /m=14 about

if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    case $(cftuconf cft.multi_node.hostnames) in
    *${HOSTNAME}*) 
        # hostname could be already in the list after an upgrade
        echo "INF: Remove host $HOSTNAME"
        cft remove_host -hostname $HOSTNAME
        ;;
    esac

    if [ -n "$CFT_KUBERNETES_SERVICE" ]; then
        # Orchestrated container
        address=$(hostname -f)
    else
        # Non-orchestrated, use the user's customized value.
        address=$CFT_FQDN
    fi
    echo "INF: Add host hostname=$HOSTNAME, address=$address"
    cft add_host -hostname $HOSTNAME -host $address
fi

# show customize information
CFTUTIL /m=14 LISTUCONF scope=user

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

# Perform post upgrade success only if cft and copilot start
if $is_upgrade ; then
    post_upgrade_success
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
    switch_cert
    healthz
done
