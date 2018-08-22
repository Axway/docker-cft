#!/bin/sh
#
echo "creating runtime..."

# CREATE RUNTIME DIRECTORY
$HOME/Axway/Transfer_CFT/home/bin/cftruntime $HOME/Axway/Transfer_CFT/home $CFT_CFTDIRRUNTIME
cd $CFT_CFTDIRRUNTIME
. ./profile

# INSTALLER PARAMETER
CFTUTIL /m=2 uconfset id='cft.synchrony_dir', value='/home/cft/Axway'

# CFT IDENTITY
if [ -n "$CFT_FQDN" ]; then
    CFTUTIL /m=2 uconfset id='cft.full_hostname', value=$CFT_FQDN
fi
if [ -n "$CFT_INSTANCE_ID" ]; then
    CFTUTIL /m=2 uconfset id='cft.instance_id', value=$CFT_INSTANCE_ID
else
    CFTUTIL /m=2 uconfset id='cft.instance_id', value=cft_`hostname`
fi
if [ -n "$CFT_INSTANCE_GROUP" ]; then
    CFTUTIL /m=2 uconfset id='cft.instance_group', value=$CFT_INSTANCE_GROUP
fi

# ENCRYPTION KEY
pass=`head /dev/urandom | tr -dc 'A-Za-z0-9!#$*+?@' | head -c 20  ; echo`
cftcrypt --genkey --keyfname data/crypto/crypkey --saltfname data/crypto/crypsalt --pass \"$pass\"
CFTUTIL /m=2 uconfset id='crypto.key_fname', value="data/crypto/crypkey"
CFTUTIL /m=2 uconfset id='crypto.salt_fname', value="data/crypto/crypsalt"

# BASIC CONFIGURATION
if [ -n "$CFT_CATALOG_SIZE" ]; then
    CFTUTIL /m=2 uconfset id='cft.cftcat.default_size', value=$CFT_CATALOG_SIZE
fi
if [ -n "$CFT_COM_SIZE" ]; then
    CFTUTIL /m=2 uconfset id='cft.cftcom.default_size', value=$CFT_COM_SIZE
fi
CFTUTIL /m=2 uconfset id='samples.enabled_protocols.value', value='PESIT'
if [ -n "$CFT_PESIT_PORT" ]; then
    CFTUTIL /m=2 uconfset id='samples.pesitany_sap.value', value=$CFT_PESIT_PORT
fi
if [ -n "$CFT_PESITSSL_PORT" ]; then
    CFTUTIL /m=2 uconfset id='samples.pesitssl_sap.value', value=$CFT_PESITSSL_PORT
fi
if [ -n "$CFT_COMS_PORT" ]; then
    CFTUTIL /m=2 uconfset id='samples.coms_port.value', value=$CFT_COMS_PORT
fi

# CFT UI
if [ -n "$CFT_COPILOT_PORT" ]; then
    CFTUTIL /m=2 uconfset id='copilot.general.serverport', value=$CFT_COPILOT_PORT
fi
if [ -n "$CFT_COPILOT_CG_PORT" ]; then
    CFTUTIL /m=2 uconfset id='copilot.general.ssl_serverport', value=$CFT_COPILOT_CG_PORT
fi

# MULTINODE
CFTUTIL /m=2 uconfset id='cft.multi_node.enable,', value='No'

# CG CONFIGURATION
if [ -n "$CFT_CG_ENABLE" ]; then
    CFTUTIL /m=2 uconfset id='cg.enable', value=$CFT_CG_ENABLE
fi
if [ "$CFT_CG_ENABLE" = "YES" ]; then
    CFTUTIL /m=2 uconfset id='cg.ca_cert_id' , value='CG_CA'
    CFTUTIL uconfset id='am.passport.csd_file', value='$(cft.install.extrasPS_dir)csd_Transfer_CFT_CG.xml'
    isCG=1
else
    CFTUTIL uconfunset id='am.passport.csd_file'
    CFTUTIL uconfset id='am.type', value='None'
    CFTUTIL uconfset id='pki.type', value='cft'
    CFTUTIL uconfset id='sentinel.xfb.enable', value='No'
    isCG=0
fi
if [ -n "$CFT_CG_HOST" ]; then
    CFTUTIL /m=2 uconfset id='cg.host', value=$CFT_CG_HOST
fi
if [ -n "$CFT_CG_PORT" ]; then
    CFTUTIL /m=2 uconfset id='cg.port', value=$CFT_CG_PORT
fi
if [ -n "$CFT_CG_SHARED_SECRET" ]; then
    CFTUTIL /m=2 uconfset id='cg.shared_secret', value=$CFT_CG_SHARED_SECRET
fi
if [ -n "$CFT_POLICY" ]; then
    CFTUTIL /m=2 uconfset id='cg.configuration_policy', value=$CFT_POLICY
fi
if [ -n "$CFT_PERIODICITY" ]; then
    CFTUTIL /m=2 uconfset id='cg.periodicity', value=$CFT_PERIODICITY
fi
CFTUTIL /m=2 uconfset id='sentinel.trkmsgencoding', value='UTF-8'

# REST API CONFIGURATION
if [ -n "$CFT_RESTAPI_PORT" ]; then
    CFTUTIL /m=2 uconfset id='copilot.restapi.serverport', value=$CFT_RESTAPI_PORT
    CFTUTIL /m=2 uconfset id='copilot.restapi.enable', value='YES'
    # CREATE CERTIFICATES FOR REST API
    openssl req -newkey rsa:2048 -nodes -keyout conf/pki/rest_api_key.pem -x509 -days 365 -out conf/pki/rest_api_cert.pem -subj '/CN=$CFT_FQDN'
    openssl pkcs12 -inkey conf/pki/rest_api_key.pem -in conf/pki/rest_api_cert.pem -export -out conf/pki/rest_api_cert.p12 -passout pass:restapi
    # SET UCONF VALUE FOR CERTIFICATES
    CFTUTIL /m=2 uconfset id='copilot.ssl.SslCertFile', value='conf/pki/rest_api_cert.p12'
    CFTUTIL /m=2 uconfset id='copilot.ssl.SslCertPassword', value='restapi'
fi

# OTHERS
if [ -n "$CFT_JVM" ]; then
    CFTUTIL /m=2 uconfset id='secure_relay.ma.start_options', value='-Xmx'$CFT_JVM'm'
fi
CFTUTIL uconfset id='cft.seed.enable_internal', value='Yes'
#   JAVA
java=`ls $HOME/Axway/Java/linux-x86/*/bin/java`
CFTUTIL uconfset id='cft.jre.java_binary_path', value=\'$java\'

# UPDATE CONFIGURATION SAMPLE 
if [ $isCG = 1 ]; then
    fname=conf/cft-cg.conf
    sed -i 's#<CFT_CG_CUSTOM_CA>#conf/pki/passportCA.pem#g'       conf/cft-cg-pki.conf
else
    fname=conf/cft-tcp.conf
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

# CREATE BASES
if [ $isCG = 1 ]; then
    cftinit conf/cft-cg.conf
    PKIUTIL @conf/cft-cg-pki.conf
else
    cftinit conf/cft-tcp.conf conf/cft-tcp-part.conf
    PKIUTIL @conf/cft-pki.conf
fi

# XFBADM ?

# SET KEY
echo "$($CFT_KEY)" >$CFTKEY

cd
echo "runtime created!"
