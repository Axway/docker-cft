# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2019 Axway Software SA and its affiliates. All rights reserved.
#
#!/bin/bash
#

set -Eeo pipefail

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

customize_runtime()
{
    echo "INF: Customizing the runtime..."

    # License key update.
    echo "$($CFT_KEY)" >$CFTKEY

    # User customization
    customdir="$HOME/custom"
    if [ ! -d $customdir ]; then
        mkdir $customdir
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
            CFTUTIL /m=2 uconfset id='copilot.ssl.SslCertPassword', value=$($USER_COPILOT_CERT_PASSWORD)
            file_checksum $USER_COPILOT_CERT >$sha1
            echo "INF: Customized Copilot certificate $USER_COPILOT_CERT set."
        fi
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

    # Passport AM persistent cache
    if [ -n "$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL" ]; then
        CFTUTIL /m=2 uconfset id='am.passport.persistency.check_interval', value=$CFT_AM_PASSPORT_PERSISTENCY_CHECK_INTERVAL
    fi

    echo "INF: runtime customized."
}

# Propagating signals
stop()
{
    copstop -f &
    cft force-stop
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

export_data()
{
    stop
    ~/export_bases.sh
    kill
}

case $CFT_FQDN in
     *_*)
          echo "hostname MUST NOT have '_'"
          exit 1
     ;;
esac

# create the runtime
if [ -f $CFT_CFTDIRRUNTIME/profile ]; then
    echo "INF: reuse runtime..."

    # test is update
    if [ -f $CFT_CFTDIRRUNTIME/toUpdate ]; then
        echo "INF: updating bases..."
        ~/import_bases.sh
        rm $CFT_CFTDIRRUNTIME/toUpdate
    fi
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

# load profile
cd $CFT_CFTDIRRUNTIME
. ./profile

# customize the runtime
customize_runtime

# show info about cft
CFTUTIL /m=2 about

# show customize information
CFTUTIL /m=2 LISTUCONF scope=user

# ensure logs are empty before starting
rm -f run/cft.out run/copsmng.out log/cftlog run/copui.trc run/coprests.out run/copsxpam.out

# start:
if copstart ; then
    echo "INF: copstart success"
else
    echo "ERR: copstart returns:"$?
    cat run/copsmng.out
    cat run/copui.trc
    cat run/coprests.out
    cat run/copsxpam.out
    exit 1
fi

if cft start ; then
    echo "INF: cft start success"
else
    echo "ERR: cft start returns:"$?
    cat run/cft.out
    cat log/cftlog
    exit 1
fi

# logs on stdout
tail -v run/cft.out -F run/copsmng.out -F run/copui.trc -F run/copsxpam.out -F log/cftlog &

trap 'finish' SIGTERM SIGHUP SIGINT EXIT
trap 'export_data' SIGUSR1

# run loop
echo "INF: waiting copilot..."
while copstatus; do
    sleep ${CFT_STATUS_SLEEP:-10}
done

