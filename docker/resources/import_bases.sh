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

delete_db()
{
    fname=$1
    if [ -f "$fname" ]; then
        echo "deleting $fname..."
        rm $fname
        rm ${fname}*
        echo "$fname deleted"
    fi
}

if [ "$CFT_EXPORTDIR" = "" ]; then
    echo "FATAL: CFT_EXPORTDIR not defined. Please specify the environment variable CFT_EXPORTDIR."
    exit 1
fi

cd ~
cd $CFT_CFTDIRRUNTIME

echo "Working directory: $PWD"
exportdir=$CFT_EXPORTDIR/export
if [ -d $exportdir ]; then
    echo "$exportdir exists: importing data..."
else
    echo "$exportdir does not exist: import skipped."
    exit 0
fi

# Delete previous databases
delete_db $CFT_CFTDIRRUNTIME/data/cftparm
delete_db $CFT_CFTDIRRUNTIME/data/cftpart
delete_db $CFT_CFTDIRRUNTIME/data/CFTPKU

# Init new databases
$CFT_INSTALLDIR/home/bin/cftruntime --profile $CFT_INSTALLDIR/home $CFT_CFTDIRRUNTIME
$CFT_INSTALLDIR/home/bin/cftruntime --uconf $CFT_INSTALLDIR/home $CFT_CFTDIRRUNTIME --mac=no

. ./profile

# Version comparison
downgrade=0
backupdir=""
vers=$(get_cft_version_num)
oldvers=$(cat $exportdir/version)
if [[ $? -ne 0 || "$vers" = "" ]]; then
    echo "WARNING: failed to retrieve CFT version"
else
    echo "New version is $vers <> old version is $oldvers"
    if [ $vers -ge $oldvers ]; then
        echo "Upgrade policy"
    else
        echo "Downgrade policy"

        backupdir=$CFT_EXPORTDIR/$vers
        echo "Backup directory: $backupdir"
        if [ -d $backupdir ]; then
            downgrade=1
        else
            echo "ERROR: backup directory ($backupdir) does not exists"
        fi
    fi
fi

# Import bases
init_multinode
fail=0

## Uconf
if [ $downgrade = 1 ]; then
    echo "Restoring uconf of $(date -r $backupdir/cft-uconf.cfg)..." 
    CFTUTIL @$backupdir/cft-uconf.cfg
else
    CFTUTIL @$exportdir/cft-uconf.cfg
fi
if [ $? -ne 0 ]; then
    echo "ERROR: failed to import UCONF"
    fail=1
else
    echo "UCONF imported"
fi

## Reload the profile as environment variables may have been impacted by the UCONF import.
. ./profile

## Parm/Part
if [ $downgrade = 1 ]; then
    echo "Restoring configuration of $(date -r $backupdir/cft-cnf.cfg)..." 
    cftinit $backupdir/cft-cnf.cfg
else
    cftinit $exportdir/cft-cnf.cfg
fi
if [ $? -ne 0 ]; then
    echo "ERROR: failed to initialize databases"
    fail=1
else
    echo "Databases initialized"
fi

## Catalog
if [ $MULTINODE = 1 ]; then
     cat_name=$(cftuconf cft.cftcat.fname)
    for ((i=0;  i<$CFT_MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=2 MIGR type=CAT, direct=TOCAT, ofname=$cat_name$j, ifname=$exportdir/cft-cat$j.xml
        if [ $? -ne 0 ]; then
            echo "ERROR: failed to import Catalog $j"
            fail=1
        else
            echo "Catalog $j imported"
        fi
    done
else
    CFTMI /m=2 MIGR type=CAT, direct=TOCAT, ofname=_CFTCATA, ifname=$exportdir/cft-cat.xml
    if [ $? -ne 0 ]; then
        echo "ERROR: failed to import Catalog"
        fail=1
    else
        echo "Catalog imported"
    fi
fi

## Com file
CFTMI /m=2 MIGR type=COM, direct=TOCOM, ofname=_CFTCOM, ifname=$exportdir/cft-com.xml
if [ $? -ne 0 ]; then
    echo "ERROR: failed to import COM"
    fail=1
else
    echo "COM imported"
fi
if [ $MULTINODE = 1 ]; then
    com_name=$(cftuconf cft.cftcom.fname)
    for ((i=0;  i<$CFT_MULTINODE_NUMBER; i++ ))
    do
        j=$(printf "%02d" $i)
        CFTMI /m=2 MIGR type=COM, direct=TOCOM, ofname=$com_name$j, ifname=$exportdir/cft-com$j.xml
        if [ $? -ne 0 ]; then
            echo "ERROR: failed to import COM $j"
            fail=1
        else
            echo "COM $j imported"
        fi
    done
fi

## PKI
#### Erase PKI database
PKIUTIL PKIFILE fname = '%env:CFTPKU%', mode = 'DELETE'
#### Create new PKI
PKIUTIL PKIFILE fname = '%env:CFTPKU%', mode = 'CREATE'
#### Import PKI
PKIUTIL @$exportdir/cft-pki.cfg
if [ $? -ne 0 ]; then
    echo "ERROR: failed to import PKI"
    fail=1
else
    echo "PKI imported"
fi

if [ $fail -ne 0 ]; then
    exit 1
    echo "ERROR: failed to import data"
else
# Remove bases directory
    rm -rf $exportdir
fi

echo "Data successfully imported"
exit 0
