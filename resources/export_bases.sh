#!/bin/sh
#
cd ~
cd $CFT_CFTDIRRUNTIME
. ./profile
echo "Start to export data"

fail=0

# Create bases directory
mkdir bkpBases

# Export bases
## Catalog
CFTMI /m=2 MIGR type=CAT, direct=FROMCAT, ifname=_CFTCATA, ofname=bkpBases/cft-cat.xml
if [ "$?" -ne "0" ]; then
    echo "FAIL to export Catalog"
    fail=1
else
    echo "Catalog exported"
fi
## Com file
CFTMI /m=2 MIGR type=COM, direct=FROMCOM, ifname=_CFTCOM, ofname=bkpBases/cft-com.xml
if [ "$?" -ne "0" ]; then
    echo "FAIL to export COM"
    fail=1
else
    echo "COM exported"
fi
## Parm/Part
CFTUTIL /m=2 UCONFSET ID=cft.uconf.cftext ,value= NO
CFTUTIL /m=2 CFTEXT fout=bkpBases/cft-cnf.cfg
if [ "$?" -ne "0" ]; then
    echo "FAIL to export bases"
    fail=1
else
    echo "Bases exported"
fi
## PKI
mkdir bkpBases/pki
touch bkpBases/cft-pki.cfg
PKIUTIL PKIEXT fout=bkpBases/cft-pki.cfg, pkipref=bkpBases/pki/
if [ "$?" -ne "0" ]; then
    echo "FAIL to export PKI"
    fail=1
else
    echo "PKI exported"
fi

if [ "$fail" -ne "0" ]; then
    echo "FAIL to export all data"
# Remove bases directory
    rm -rf bkpBases
else
# Create file that says we should import
    touch toUpdate
fi

echo "Finish to export data"
