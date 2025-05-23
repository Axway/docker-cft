#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#
set -Eeo pipefail

source ./utils.sh

log_info "Creating runtime..."
shopt -s nocasematch

# CREATE RUNTIME DIRECTORY
$CFT_INSTALLDIR/home/bin/cftruntime $CFT_INSTALLDIR/home $CFT_CFTDIRRUNTIME
cd $CFT_CFTDIRRUNTIME
. ./profile

if [ -n "$(cftuconf cft.audit.output)" ]; then
    CFTUTIL /m=14 uconfset id='cft.audit.output', value='STDOUT'
fi

# CFT IDENTITY
if [ -n "$CFT_INSTANCE_ID" ]; then
    CFTUTIL /m=14 uconfset id='cft.instance_id', value=$CFT_INSTANCE_ID
else
    CFTUTIL /m=14 uconfset id='cft.instance_id', value=cft_`hostname`
fi
if [ -n "$CFT_INSTANCE_GROUP" ]; then
    CFTUTIL /m=14 uconfset id='cft.instance_group', value=$CFT_INSTANCE_GROUP
fi
isMulti=0
if [[ "$CFT_MULTINODE_ENABLE" = "YES" ]]; then
    CFTUTIL /m=14 uconfset id='cft.multi_node.enable', value=$CFT_MULTINODE_ENABLE
    CFTUTIL /m=14 uconfset id='cft.multi_node.nodes', value=$CFT_MULTINODE_NUMBER
    CFTUTIL /m=14 uconfset id='cft.multi_node.max_per_host', value=$CFT_MULTINODE_NODE_PER_HOST
    isMulti=1
fi

# ENCRIPTION KEY
pass=`head /dev/urandom | tr -dcs 'A-Za-z0-9!#$*+?@' 'A-Za-z0-9!#$*+?@' | head -c 20  ; echo`
pass="${pass}aB0!"
echo "------------------------"
echo "Encryption: $pass"
echo "------------------------"
cftcrypt --genkey --keyfname $CFTDIRRUNTIME/data/crypto/crypkey --saltfname $CFTDIRRUNTIME/data/crypto/crypsalt --pass \"$pass\"

# BASIC CONFIGURATION
if [ -n "$CFT_CATALOG_SIZE" ]; then
    CFTUTIL /m=14 uconfset id='cft.cftcat.default_size', value=$CFT_CATALOG_SIZE
fi
if [ -n "$CFT_COM_SIZE" ]; then
    CFTUTIL /m=14 uconfset id='cft.cftcom.default_size', value=$CFT_COM_SIZE
fi
activated_protocols=''
if [ -n "$CFT_PESIT_PORT" ]; then
    activated_protocols="PESIT"
    CFTUTIL /m=14 uconfset id='samples.pesitany_sap.value', value=$CFT_PESIT_PORT
else
    CFTUTIL /m=14 uconfset id='samples.pesitany_sap.value', value=1761
fi
if [ -n "$CFT_PESITSSL_PORT" ]; then
    activated_protocols="$activated_protocols,PESITSSL"
    CFTUTIL /m=14 uconfset id='samples.pesitssl_sap.value', value=$CFT_PESITSSL_PORT
else
    CFTUTIL /m=14 uconfset id='samples.pesitssl_sap.value', value=1762
fi
if [ -n "$CFT_SFTP_PORT" ]; then
    activated_protocols="$activated_protocols,SFTP"
    CFTUTIL /m=14 uconfset id=samples.sftp_sap.value, value=$CFT_SFTP_PORT
else
    CFTUTIL /m=14 uconfset id=samples.sftp_sap.value, value=1763
fi
CFTUTIL /m=14 uconfset id=samples.enabled_protocols.value, value="'$activated_protocols'"

if [ -n "$CFT_COMS_PORT" ]; then
    CFTUTIL /m=14 uconfset id='samples.coms_port.value', value=$CFT_COMS_PORT
else
    CFTUTIL /m=14 uconfset id='samples.coms_port.value', value=1765
fi

# CFT UI
if [ -n "$CFT_COPILOT_PORT" ]; then
    CFTUTIL /m=14 uconfset id='copilot.general.serverport', value=$CFT_COPILOT_PORT
fi
if [ -n "$CFT_COPILOT_CG_PORT" ]; then
    CFTUTIL /m=14 uconfset id='copilot.general.ssl_serverport', value=$CFT_COPILOT_CG_PORT
fi

# CG CONFIGURATION
if [ -n "$CFT_CG_ENABLE" ]; then
    CFTUTIL /m=14 uconfset id='cg.enable', value=$CFT_CG_ENABLE
fi
if [[ "$CFT_CG_ENABLE" = "YES" ]]; then
    CFTUTIL /m=14 uconfset id='cg.ca_cert_id' , value='CG_CA'
    CFTUTIL /m=14 uconfset id='am.passport.csd_file', value='$(cft.install.extrasPS_dir)csd_Transfer_CFT_CG.xml'
    isCG=1
else
    CFTUTIL /m=14 uconfunset id='am.passport.csd_file'
    CFTUTIL /m=14 uconfset id='am.type', value='None'
    CFTUTIL /m=14 uconfset id='pki.type', value='cft'
    CFTUTIL /m=14 uconfset id='sentinel.xfb.enable', value='No'
    isCG=0
fi
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

# SENTINEL CONFIGURATION
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

# OTHERS
if [ -n "$CFT_JVM" ]; then
    CFTUTIL /m=14 uconfset id='secure_relay.ma.start_options', value='-Xmx'$CFT_JVM'm'
fi
CFTUTIL /m=14 uconfset id='cft.unix.stop_timeout', value='6'
#JAVA
CFTUTIL /m=14 uconfset id='cft.jre.java_binary_path', value=\'$JAVA_HOME/bin/java\'

# Test if file cft-cg.conf exists
fname=conf/cft-tcp.conf
legacy=0
if [ -f "conf/cft-cg.conf" ]; then
    legacy=1
    # UPDATE CONFIGURATION SAMPLE
    if [ $isCG = 1 ]; then
        fname=conf/cft-cg.conf
    fi
fi
# string replacement
sed -i 's/<CFTKEY>/@$CFTKEY/g'      $fname
sed -i 's/<CFTPART>/_CFTPART/g'     $fname
sed -i 's/<CFTCOM>/_CFTCOM/g'       $fname
sed -i 's/<CFTCATA>/_CFTCATA/g'     $fname
sed -i 's/<CFTLOG>/_CFTLOG/g'       $fname
sed -i 's/<CFTLOGA>/_CFTLOGA/g'     $fname
sed -i 's/<CFTACNT>/_CFTACNT/g'     $fname
sed -i 's/<CFTACNTA>/_CFTACNTA/g'   $fname
sed -i 's/<OPERMSGVALUE>/0/g'       $fname

if [ $legacy = 0 ]; then
    fname=conf/generate_certs.sh
    if [ -f $fname ]; then
        sed -i 's/\[DAYS\]/30/g'                      $fname
        sed -i 's/\[INSTANCE_ID\]/${CFT_INSTANCE_ID}/g' $fname
        sed -i 's/\[FULL_HOSTNAME\]/${CFT_FQDN}/g'      $fname
    fi

    fname=conf/generate_copilot_cert.sh
    if [ -f $fname ]; then
        sed -i 's/\[DAYS\]/365/g'                     $fname
        sed -i 's/\[INSTANCE_ID\]/${CFT_INSTANCE_ID}/g' $fname
        sed -i 's/\[FULL_HOSTNAME\]/${CFT_FQDN}/g'      $fname
    fi
fi
# CREATE BASES
if [ $legacy = 1 ]; then
    if [ $isCG = 1 ]; then
        cftinit conf/cft-cg.conf
        PKIUTIL /m=14 @conf/cft-pki.conf
    else
        cftinit conf/cft-tcp.conf conf/cft-tcp-part.conf
        PKIUTIL /m=14 @conf/cft-pki.conf
    fi
else # New conf files version
    cftinit conf/cft-tcp.conf
    if [ $isCG = 1 ]; then
        PKIUTIL /m=14 pkifile fname='%env:CFTPKU%', mode='CREATE'
        PKIUTIL /m=14 pkikeygen id='srv_priv_key', keylen=2048
    else
        cftupdate conf/cft-tcp-additional.conf
        if [ -f "conf/generate_certs.sh" ]; then
            sh -c ./conf/generate_certs.sh
        fi
        PKIUTIL /m=14 @conf/cft-pki.conf
    fi
fi

# XFBADM
if [ -n "$USER_XFBADM_LOGIN" ] && [ -n "$USER_XFBADM_PASSWORD" ]; then
    log_info "Creating user $USER_XFBADM_LOGIN..."
    xfbadmusr add -l $(get_value $USER_XFBADM_LOGIN) -p $(get_value $USER_XFBADM_PASSWORD) -u AUTO -g AUTO
    log_info "User $USER_XFBADM_LOGIN created."
else
    log_warning "Password required to create an user. No user will be created!"
fi

#Enable nodes
if [ $isMulti = 1 ]; then
    log_info "multinode enabled"
    log_info "Enabling nodes..."
    for ((i=0;  i<$CFT_MULTINODE_NUMBER; i++ ))
    do
        log_info "cft enable_node -n $i"
        cft enable_node -n $i
    done
fi

cd
log_info "runtime created!"

shopt -u nocasematch
