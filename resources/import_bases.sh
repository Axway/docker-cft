# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2019 Axway Software SA and its affiliates. All rights reserved.
#
#!/bin/bash
#
cd ~
cd $CFT_CFTDIRRUNTIME
. ./profile
echo "Start to import data"

fail=0

# Import bases
## Parm/Part
cftinit bkpBases/cft-cnf.cfg
if [ "$?" -ne "0" ]; then
    echo "FAIL to recreate bases"
    fail=1
else
    echo "Bases created"
fi
## Catalog
CFTMI /m=2 MIGR type=CAT, direct=TOCAT, ofname=_CFTCATA, ifname=bkpBases/cft-cat.xml
if [ "$?" -ne "0" ]; then
    echo "FAIL to import Catalog"
    fail=1
else
    echo "Catalog imported"
fi
## Com file
CFTMI /m=2 MIGR type=COM, direct=TOCOM, ofname=_CFTCOM, ifname=bkpBases/cft-com.xml
if [ "$?" -ne "0" ]; then
    echo "FAIL to import COM"
    fail=1
else
    echo "COM imported"
fi
## PKI
#### Erase PKI database
PKIUTIL PKIFILE fname = '%env:CFTPKU%', mode = 'DELETE'
#### Create new PKI
PKIUTIL PKIFILE fname = '%env:CFTPKU%', mode = 'CREATE'
#### Import PKI
PKIUTIL /m=2 @bkpBases/cft-pki.cfg
if [ "$?" -ne "0" ]; then
    echo "FAIL to import PKI"
    fail=1
else
    echo "PKI imported"
fi

if [ "$fail" -ne "0" ]; then
    echo "FAIL to import data"
else
# Remove bases directory
    echo "SUCCESS"
    rm -rf bkpBases
fi

echo "Finish import data script"
