#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#
set -Eeo pipefail
trap 'rm $lockfile' SIGTERM SIGHUP SIGINT EXIT
trap 'finish' SIGTERM SIGHUP SIGINT EXIT

source ./utils.sh

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
        log_info "CFT_FQDN is $CFT_FQDN"
    elif [ -n "$host" ]; then
        export CFT_FQDN=$host
        log_info "CFT_FQDN is $CFT_FQDN"
    else
        host=$(hostname)
        export CFT_FQDN=$host
        log_info "CFT_FQDN is $CFT_FQDN"
    fi

    case $CFT_FQDN in
         *_*)
              log_error "CFT_FQDN must not contains a '_'"
              exit 1
         ;;
    esac
}

generate_certificate()
{
    cn=$CFT_INSTANCE_ID
    altname=$CFT_FQDN
    log_info "Generating default certificate with CN=$cn, subjectAltName=$altname"
    if [ $(expr length $cn) -gt 64 ]; then
        log_error "CN is too long, cannot generate certificate."
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

create_update_xfbadm_user()
{
    if [ -n "$USER_XFBADM_LOGIN" ] && [ -n "$USER_XFBADM_PASSWORD" ]; then
        userval=$(get_value $USER_XFBADM_LOGIN)
        out=$(xfbadmusr print -l ${userval})

        if [ -z "$out" ]; then
            log_info "Creating user ${userval}..."
        else
            log_info "Updating user ${userval}..."
        fi

        xfbadmusr delete -l ${userval} >/dev/null 2>&1 || true
        xfbadmgrp delete -G ${userval} >/dev/null 2>&1 || true
        xfbadmusr add -l ${userval} -p $(get_value $USER_XFBADM_PASSWORD) -u AUTO -g AUTO

        if [ -z "$out" ]; then
            log_info "User ${userval} created."
        else
            log_info "User ${userval} updated."
        fi
    else
        log_warning "Password required to create a user. No user will be created!"
    fi
}

customize_runtime()
{
    log_info "Customizing the runtime..."

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
        # CG configuration
        if [ -n "$CFT_CG_HOST" ]; then
            CFTUTIL /m=14 uconfset id='cg.host', value=$CFT_CG_HOST
        fi
        if [ -n "$CFT_CG_PORT" ]; then
            CFTUTIL /m=14 uconfset id='cg.port', value=$CFT_CG_PORT
            CFTUTIL /m=14 uconfset id='cg.restapi_port', value=$CFT_CG_PORT
        fi
        if [ -n "$CFT_CG_POLICY" ]; then
            CFTUTIL /m=14 uconfset id='cg.configuration_policy', value=$CFT_CG_POLICY
        fi
        if [ -n "$CFT_CG_PERIODICITY" ]; then
            CFTUTIL /m=14 uconfset id='cg.periodicity', value=$CFT_CG_PERIODICITY
        fi
        if [ -n "$CFT_CG_SHARED_SECRET" ]; then
            CFTUTIL /m=14 uconfset id='cg.shared_secret', value=$(get_value $CFT_CG_SHARED_SECRET)
        fi
        if [[ -n "$CFT_CG_AGENT_NAME" ]]; then
            log_info "Setting the customized Agent Name $CFT_CG_AGENT_NAME..."
            CFTUTIL /m=14 uconfset id='cg.metadata.agent.value', value=$CFT_CG_AGENT_NAME
        fi

        # CG CA certificate
        if [[ -n "$USER_CG_CA_CERT"  && ! -e "$USER_CG_CA_CERT"  ]]; then
            log_error "CG CA certificate $USER_CG_CA_CERT not found."
            exit 1
        elif [[ -n "$USER_CG_CA_CERT" ]]; then
            sha1=$customdir"/USER_CG_CA_CERT.sha1"
            rc=`file_diff $sha1 $USER_CG_CA_CERT`
            if [ $rc != 0 ]; then
                log_info "Setting the customized CG CA certificate $USER_CG_CA_CERT..."
                PKIUTIL /m=14 pkicer id='CG_CA', rootcid='CG_CA', itype='root', iname=$USER_CG_CA_CERT, pkipassw='CFT', mode='replace'
                if [ $? != 0 ]; then
                    log_error "Failed to insert the CG CA certificate $USER_CG_CA_CERT"
                    exit 1
                fi
                CFTUTIL /m=14 uconfset id='cg.ca_cert_id', value='CG_CA'
                file_checksum $USER_CG_CA_CERT >$sha1
                log_info "Customized CG CA certificate $USER_CG_CA_CERT set."
            fi
        fi
    else
        # Sentinel Configuration
        if [ -n "$CFT_SENTINEL_ENABLE" ]; then
            CFTUTIL /m=14 uconfset id='sentinel.xfb.enable', value=$CFT_SENTINEL_ENABLE
        fi
        if [ -n "$CFT_SENTINEL_HOST" ]; then
            CFTUTIL /m=14 uconfset id='sentinel.trkipaddr', value=$CFT_SENTINEL_HOST
        fi
        if [ -n "$CFT_SENTINEL_PORT" ]; then
            CFTUTIL /m=14 uconfset id='sentinel.trkipport', value=$CFT_SENTINEL_PORT
        fi
        if [ -n "$CFT_SENTINEL_SSL" ]; then
            CFTUTIL /m=14 uconfset id='sentinel.xfb.use_ssl', value=$CFT_SENTINEL_SSL
        fi
        CFTUTIL /m=14 uconfset id='sentinel.xfb.log', value=$CFT_SENTINEL_LOG_FILTER
        if [ -n "$CFT_SENTINEL_TRANSFER_FILTER" ]; then
            CFTUTIL /m=14 uconfset id='sentinel.xfb.transfer', value=$CFT_SENTINEL_TRANSFER_FILTER
        fi
        CFTUTIL /m=14 uconfset id='sentinel.trkmsgencoding', value='UTF-8'

        # Sentinel CA certificate
        if [[ -n "$USER_SENTINEL_CA_CERT" && ! -e "$USER_SENTINEL_CA_CERT" ]]; then
            log_error "Sentinel CA certificate $USER_SENTINEL_CA_CERT not found."
            exit 1
        elif [[ -n "$USER_SENTINEL_CA_CERT" ]]; then
            sha1=$customdir"/USER_SENTINEL_CA_CERT.sha1"
            rc=`file_diff $sha1 $USER_SENTINEL_CA_CERT`
            if [ $rc != 0 ]; then
                log_info "Setting the customized Sentinel CA certificate $USER_SENTINEL_CA_CERT..."
                PKIUTIL /m=14 pkicer id='SENTINEL_CA', rootcid='SENTINEL_CA', itype='root', iname=$USER_SENTINEL_CA_CERT, pkipassw='CFT', mode='replace'
                if [ $? != 0 ]; then
                    log_error "Failed to insert the Sentinel CA certificate $USER_SENTINEL_CA_CERT"
                    exit 1
                fi
                CFTUTIL /m=14 uconfset id='sentinel.xfb.ca_cert_id', value='SENTINEL_CA'
                file_checksum $USER_SENTINEL_CA_CERT >$sha1
                log_info "Customized Sentinel CA certificate $USER_SENTINEL_CA_CERT set."
            fi
        fi
    fi

    # Copilot server certificate
    if [[ -n "$USER_COPILOT_CERT" && ! -e "$USER_COPILOT_CERT" ]]; then
        log_error "Copilot server certificate $USER_COPILOT_CERT not found."
        exit 1
    elif [[ -n "$USER_COPILOT_CERT" ]]; then
        sha1=$customdir"/USER_COPILOT_CERT.sha1"
        rc=`file_diff $sha1 $USER_COPILOT_CERT`
        if [ $rc != 0 ]; then
            log_info "Setting the customized Copilot certificate $USER_COPILOT_CERT..."
            CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertFile', value=$USER_COPILOT_CERT
            if [[ -n "$USER_COPILOT_CERT_PASSWORD" ]]; then
                CFTUTIL /m=14 uconfset id='copilot.ssl.SslCertPassword', value=$(get_value $USER_COPILOT_CERT_PASSWORD)
            fi
            file_checksum $USER_COPILOT_CERT >$sha1
            log_info "Customized Copilot certificate $USER_COPILOT_CERT set."
        fi

        # Checking for Copilot server key
        if [[ -n "$USER_COPILOT_KEY" ]]; then
            sha1=$customdir"/USER_COPILOT_KEY.sha1"
            rc=`file_diff $sha1 $USER_COPILOT_KEY`
            if [ $rc != 0 ]; then
                echo "INF: Setting the customized Copilot Key $USER_COPILOT_KEY..."
                CFTUTIL /m=14 uconfset id='copilot.ssl.SslKeyFile', value=$USER_COPILOT_KEY
                if [[ -n "$USER_COPILOT_KEY_PASSWORD" ]]; then
                    CFTUTIL /m=14 uconfset id='copilot.ssl.SslKeyPassword', value=$(get_value $USER_COPILOT_KEY_PASSWORD)
                fi
                file_checksum $USER_COPILOT_KEY >$sha1
                echo "INF: Customized Copilot certificate $USER_COPILOT_KEY set."
            fi
        fi
    fi

    # Passport AM persistent cache
    if [ -n "$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL" ]; then
        CFTUTIL /m=14 uconfset id='am.passport.persistency.check_interval', value=$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL
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
                log_info "Certificates set as temporary, waiting for registration to be completed"
                set_temporary_rest_api_cert 1
            fi
        fi
    else
        CFTUTIL /m=14 uconfset id='copilot.restapi.enable', value='NO'
    fi

    # MISC
    if [ -n "$CFT_INSTANCE_GROUP" ]; then
        CFTUTIL /m=14 uconfset id='cft.instance_group', value=$CFT_INSTANCE_GROUP
    fi
    if [ -n "$CFT_JVM" ]; then
        CFTUTIL /m=14 uconfset id='secure_relay.ma.start_options', value='-Xmx'$CFT_JVM'm'
    fi
    CFTUTIL /m=14 uconfset id='cft.jre.java_binary_path', value=\'$JAVA_HOME/bin/java\'

    # XFBADM user management
    create_update_xfbadm_user

    # User custom start-up script
    if [[ -n "$USER_SCRIPT_START" && ! -e "$USER_SCRIPT_START" ]]; then
        log_error "Custom start-up script $USER_SCRIPT_START not found."
        exit 1
    elif [[ -n "$USER_SCRIPT_START" ]]; then
        $USER_SCRIPT_START
        if [[ $? = 0 ]]; then
            log_info "Custom start-up script $USER_SCRIPT_START returned 0"
        else
            log_error "Custom start-up script $USER_SCRIPT_START returned $?"
            exit 1
        fi
    fi

    log_info "runtime customized."
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
            log_info "Remove HOST $HOSTNAME"
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
        log_error "curl GET /healthz failed, rc=$rc, output=$out"
        return -1
    elif [ "$out" != "200" ]; then
        log_error "GET /healthz returned $out"
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
            log_info "Registration completed, switching to certificate received during registration"

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
    log_info "deleting $fname..."
    rm -f ${fname}
    log_info "$fname deleted"
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
    log_info "General Terms and Conditions accepted."
else
    log_fatal "General Terms and Conditions not accepted. EXIT"
    exit 1
fi

# Boolean Variables to MAJ
CFT_MULTINODE_ENABLE=`echo $CFT_MULTINODE_ENABLE | tr '[a-z]' '[A-Z]'`
CFT_CG_ENABLE=`echo $CFT_CG_ENABLE | tr '[a-z]' '[A-Z]'`
CFT_SENTINEL_ENABLE=`echo $CFT_SENTINEL_ENABLE | tr '[a-z]' '[A-Z]'`

check_fqdn

parent_dir="$(dirname -- "$(realpath -- "$CFT_CFTDIRRUNTIME")")"
lockfile=$parent_dir/runtimelock
exec 7>$lockfile
flock 7

log_info "$HOSTNAME got lock"

if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
    is_upgrade=true
    log_info "runtime exists"
    # import databases...
    ./import_bases.sh
else
    log_info "Creating the runtime"
    is_upgrade=false
    ./runtime_create.sh
    # user custom init script
    if [[ -n "$USER_SCRIPT_INIT" && ! -e "$USER_SCRIPT_INIT" ]]; then
        log_error "Custom initialization script $USER_SCRIPT_INIT not found."
        exit 1
    elif [[ -n "$USER_SCRIPT_INIT" ]]; then
        $USER_SCRIPT_INIT
        if [[ $? = 0 ]]; then
            log_info "Custom initialization script $USER_SCRIPT_INIT returns 0"
        else
            log_error "Custom initialization script $USER_SCRIPT_INIT returns $?"
            exit 1
        fi
    fi
fi

# load profile
cd $CFT_CFTDIRRUNTIME
. ./profile

if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    if [ "$(cft status | grep -wc running)" = 0 ]; then
        log_info "customize runtime"
        customize_runtime
    fi
else
    log_info "customize runtime"
    customize_runtime
fi

# show info about cft
CFTUTIL /m=14 about

if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    case $(cftuconf cft.multi_node.hostnames) in
    *${HOSTNAME}*) 
        # hostname could be already in the list after an upgrade
        log_info "Remove host $HOSTNAME"
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
    log_info "Add host hostname=$HOSTNAME, address=$address"
    cft add_host -hostname $HOSTNAME -host $address
fi

# show customize information
CFTUTIL /m=14 LISTUCONF scope=user

if cft start ; then
    log_info "cft start success"
else
    log_error "cft start returns:"$?
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
    log_info "copstart success"
else
    log_error "copstart returns:"$?
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

log_info "$HOSTNAME released lock"
flock -u 7 # explicitly unlock

# logs on stdout
if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    tail -v run/cft[0-9][0-9].out -F run/copsmng.$HOSTNAME.out -F run/copui.$HOSTNAME.trc -F run/copsxpam.$HOSTNAME.out -F log/cftlog[0-9][0-9] &
else
    tail -v run/cft.out -F run/copsmng.out -F run/copui.trc -F run/copsxpam.out -F log/cftlog &
fi

# run loop
log_info "waiting copilot..."
healthz
while [ $? -eq 0 ]; do
    sleep ${CFT_STATUS_SLEEP:-10}
    switch_cert
    healthz
done
