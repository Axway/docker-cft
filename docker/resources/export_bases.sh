#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}"/utils.sh

init_multinode()
{
    val=$(cftuconf cft.multi_node.enable)
    if [ "$val" = "YES" ] || [ "$val" = "Yes" ] || [ "$val" = "yes" ] || [ "$val" = "1" ] ; then
        MULTINODE=1
        MULTINODE_NUMBER=$(cftuconf cft.multi_node.nodes)
    else
        MULTINODE=0
    fi
}

get_cft_version()
{
    ret=$(CFTUTIL about type=cft|sed -nr 's/.*version\s*=\s*([0-9]+.[0-9]+)/\1/p')
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_update()
{
    ret=$(CFTUTIL about type=cft|sed -nr 's/.*update\s*=\s*([0-9]+)/\1/p')
    if [ $? -ne 0 ]; then
        return -1
    fi
    echo $ret
    return 0
}

get_cft_version_num()
{
    vers=$(get_cft_version)
    if [[ $? -ne 0 || "$vers" = "" ]]; then
        return -1
    fi

    update=$(get_cft_update)
    if [[ $? -ne 0 || "$update" = "" ]]; then
        return -1
    fi

    x=$(echo $vers | cut -d '.' -f 1)
    y=$(echo $vers | cut -d '.' -f 2)
    x=$(printf "%03d" $x)
    y=$(printf "%03d" $y)
    echo $x$y$update
    return 0
}

copy_file()
{
    src=$1
    dst=$2
    cp $src $dst
    if [ $? -ne 0 ]; then
        log_error "failed to copy $src to $dst"
    else
        log_info "$src copied to $dst"
    fi
}

if [ "$CFTDIRRUNTIME" = "" ]; then
    log_fatal "CFTDIRRUNTIME not defined. Please load the Tranfer CFT profile and retry."
    exit 1
fi

if [ "$CFT_EXPORTDIR" = "" ]; then
    log_fatal "CFT_EXPORTDIR not defined. Please specify the environment variable CFT_EXPORTDIR."
    exit 1
fi

cd $CFTDIRRUNTIME
log_info "Working directory: $PWD"
exportdir=$CFT_EXPORTDIR/export
log_info "Export directory: $exportdir"

# Create bases directory
if [ -d $exportdir ]; then
    log_info "Removing directory $exportdir..."
    rm -rf $exportdir
    log_info "Directory $exportdir removed."
fi
mkdir -p $exportdir
if [ $? -ne 0 ]; then
    log_fatal "failed to create directory $exportdir"
    exit 1
fi
log_info "Directory $exportdir created."

# Save version
backupdir=""
vers=$(get_cft_version_num)
if [[ $? -ne 0 || "$vers" = "" ]]; then
    log_warning "failed to retrieve CFT version"
else
    echo $vers >$exportdir/version
    log_info "Version saved: $vers"

    # Create backupdir
    backupdir=$CFT_EXPORTDIR/$vers
    log_info "Backup directory: $backupdir"
    if [ -d $backupdir ]; then
        rm -rf $backupdir
        log_info "Directory $exportdir removed."
    fi
    mkdir -p $backupdir
    if [ $? -ne 0 ]; then
        log_warning "failed to create directory $backupdir"
    fi
fi

# Export bases
fail=0
init_multinode
log_info "Exporting data..."

## Catalog
if [ $MULTINODE = 1 ]; then
    cat_name=$(cftuconf cft.cftcat.fname)
    for ((i=0;  i<$MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=14 MIGR type=CAT, direct=FROMCAT, ifname=$cat_name$j, ofname=$exportdir/cft-cat$j.xml
        if [ $? -ne 0 ]; then
            log_error "failed to export Catalog $j"
            fail=1
        else
            log_info "Catalog $j exported"
        fi
    done
else
    CFTMI /m=14 MIGR type=CAT, direct=FROMCAT, ifname=_CFTCATA, ofname=$exportdir/cft-cat.xml
    if [ $? -ne 0 ]; then
        log_error "failed to export Catalog"
        fail=1
    else
        log_info "Catalog exported"
    fi
fi

## Com file
CFTMI /m=14 MIGR type=COM, direct=FROMCOM, ifname=_CFTCOM, ofname=$exportdir/cft-com.xml
if [ $? -ne 0 ]; then
    log_error "failed to export COM"
    fail=1
else
    log_info "COM exported"
fi
if [ $MULTINODE = 1 ]; then
    com_name=$(cftuconf cft.cftcom.fname)
    for ((i=0;  i<$MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=14 MIGR type=COM, direct=FROMCOM, ifname=$com_name$j, ofname=$exportdir/cft-com$j.xml
        if [ $? -ne 0 ]; then
            log_error "failed to export COM $j"
            fail=1
        else
            log_info "COM $j exported"
        fi
    done
fi

## Uconf
CFTUTIL /m=14 CFTEXT type=uconf, fout=$exportdir/cft-uconf.cfg
if [ $? -ne 0 ]; then
    log_error "failed to export UCONF"
    fail=1
else
    log_info "UCONF exported"
    if [ -d "$backupdir" ]; then
        copy_file $exportdir/cft-uconf.cfg $backupdir/cft-uconf.cfg
    fi
fi

## Parm/Part
saved=$(cftuconf cft.uconf.cftext)
CFTUTIL /m=14 UCONFSET ID=cft.uconf.cftext, value=No
CFTUTIL /m=14 CFTEXT fout=$exportdir/cft-cnf.cfg
if [ $? -ne 0 ]; then
    log_error "failed to export PARM/PART"
    fail=1
else
    log_info "PARM/PART exported"
    if [ -d "$backupdir" ]; then
        copy_file $exportdir/cft-cnf.cfg $backupdir/cft-cnf.cfg
    fi
fi
CFTUTIL /m=14 UCONFSET ID=cft.uconf.cftext, value=$saved

## PKI
mkdir $exportdir/pki
if [ $? -ne 0 ]; then
    log_error "failed to create directory $exportdir/pki"
    exit 1
fi
touch $exportdir/cft-pki.cfg
PKIUTIL /m=14 PKIEXT fout=$exportdir/cft-pki.cfg, pkipref=$exportdir/pki/, password=upgrade
if [ $? -ne 0 ]; then
    log_error "failed to export PKI"
    fail=1
else
    log_info "PKI exported"
fi

if [ $fail -ne 0 ]; then
    log_error "failed to export all data. $exportdir deleted."
# Remove bases directory
    rm -rf $exportdir
    exit 1
fi

log_info "Data successfully exported."
exit 0
