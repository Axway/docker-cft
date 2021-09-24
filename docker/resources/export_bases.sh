#!/usr/bin/env bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2021 Axway Software SA and its affiliates. All rights reserved.
#

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
    vers=$(CFTUTIL about type=cft|sed -nr 's/.*version\s*=\s*([0-9]+.[0-9]+)/\1/p')
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

copy_file()
{
    src=$1
    dst=$2
    cp $src $dst
    if [ $? -ne 0 ]; then
        echo "ERROR: faield to copy $src to $dst"
    else
        echo "$src copied to $dst"
    fi
}

if [ "$CFTDIRRUNTIME" = "" ]; then
    echo "FATAL: CFTDIRRUNTIME not defined. Please load the Tranfer CFT profile and retry."
    exit 1
fi

if [ "$CFT_EXPORTDIR" = "" ]; then
    echo "FATAL: CFT_EXPORTDIR not defined. Please specify the environment variable CFT_EXPORTDIR."
    exit 1
fi

cd $CFTDIRRUNTIME
echo "Working directory: $PWD"
exportdir=$CFT_EXPORTDIR/export
echo "Export directory: $exportdir"

# Create bases directory
if [ -d $exportdir ]; then
    echo "Removing directory $exportdir..."
    rm -rf $exportdir
    echo "Directory $exportdir removed."
fi
mkdir -p $exportdir
if [ $? -ne 0 ]; then
    echo "FATAL: failed to create directory $exportdir"
    exit 1
fi
echo "Directory $exportdir created."

# Save version
backupdir=""
vers=$(get_cft_version_num)
if [[ $? -ne 0 || "$vers" = "" ]]; then
    echo "WARNING: failed to retrieve CFT version"
else
    echo $vers >$exportdir/version
    echo "Version saved: $vers"

    # Create backupdir
    backupdir=$CFT_EXPORTDIR/$vers
    echo "Backup directory: $backupdir"
    if [ -d $backupdir ]; then
        rm -rf $backupdir
        echo "Directory $exportdir removed."
    fi
    mkdir -p $backupdir
    if [ $? -ne 0 ]; then
        echo "WARNING: failed to create directory $backupdir"
    fi
fi

# Export bases
fail=0
init_multinode
echo "Exporting data..."

## Catalog
if [ $MULTINODE = 1 ]; then
    cat_name=$(cftuconf cft.cftcat.fname)
    for ((i=0;  i<$MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=2 MIGR type=CAT, direct=FROMCAT, ifname=$cat_name$j, ofname=$exportdir/cft-cat$j.xml
        if [ $? -ne 0 ]; then
            echo "ERROR: failed to export Catalog $j"
            fail=1
        else
            echo "Catalog $j exported"
        fi
    done
else
    CFTMI /m=2 MIGR type=CAT, direct=FROMCAT, ifname=_CFTCATA, ofname=$exportdir/cft-cat.xml
    if [ $? -ne 0 ]; then
        echo "ERROR: failed to export Catalog"
        fail=1
    else
        echo "Catalog exported"
    fi
fi

## Com file
CFTMI /m=2 MIGR type=COM, direct=FROMCOM, ifname=_CFTCOM, ofname=$exportdir/cft-com.xml
if [ $? -ne 0 ]; then
    echo "ERROR: failed to export COM"
    fail=1
else
    echo "COM exported"
fi
if [ $MULTINODE = 1 ]; then
    com_name=$(cftuconf cft.cftcom.fname)
    for ((i=0;  i<$MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=2 MIGR type=COM, direct=FROMCOM, ifname=$com_name$j, ofname=$exportdir/cft-com$j.xml
        if [ $? -ne 0 ]; then
            echo "ERROR: failed to export COM $j"
            fail=1
        else
            echo "COM $j exported"
        fi
    done
fi

## Uconf
CFTUTIL /m=2 CFTEXT type=uconf, fout=$exportdir/cft-uconf.cfg
if [ $? -ne 0 ]; then
    echo "ERROR: failed to export UCONF"
    fail=1
else
    echo "UCONF exported"
    if [ -d "$backupdir" ]; then
        copy_file $exportdir/cft-uconf.cfg $backupdir/cft-uconf.cfg
    fi
fi

## Parm/Part
saved=$(cftuconf cft.uconf.cftext)
CFTUTIL /m=2 UCONFSET ID=cft.uconf.cftext, value=No
CFTUTIL /m=2 CFTEXT fout=$exportdir/cft-cnf.cfg
if [ $? -ne 0 ]; then
    echo "ERROR: failed to export PARM/PART"
    fail=1
else
    echo "PARM/PART exported"
    if [ -d "$backupdir" ]; then
        copy_file $exportdir/cft-cnf.cfg $backupdir/cft-cnf.cfg
    fi
fi
CFTUTIL /m=2 UCONFSET ID=cft.uconf.cftext, value=$saved

## PKI
mkdir $exportdir/pki
if [ $? -ne 0 ]; then
    echo "ERROR: failed to create directory $exportdir/pki"
    exit 1
fi
touch $exportdir/cft-pki.cfg
PKIUTIL PKIEXT fout=$exportdir/cft-pki.cfg, pkipref=$exportdir/pki/, password=upgrade
if [ $? -ne 0 ]; then
    echo "ERROR: failed to export PKI"
    fail=1
else
    echo "PKI exported"
fi

if [ $fail -ne 0 ]; then
    echo "ERROR: failed to export all data. $exportdir deleted."
# Remove bases directory
    rm -rf $exportdir
    exit 1
fi

echo "Data successfully exported."
exit 0
