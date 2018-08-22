## CFT 3.3.2 docker image with OS preparation inside
#
# Building with:
# docker build -t  axway/cft:3.3.2 .

#####
# OS PREPARATION

FROM centos:centos7

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LC_LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

RUN yum install -y \
        binutils \
        curl \
        net-tools \
        procps \
        unzip \
        openssl \
        && \
    adduser cft # Create cft user

# Change workdir
WORKDIR /home/cft

#####
ENV VERSION_BASE "3.3.2"
ENV RELEASE_BASE "BN11707001"
ENV STATIC_BASE "Transfer_CFT_${VERSION_BASE}_Install_linux-x86-64_${RELEASE_BASE}.zip"

ENV VERSION_UP "3.3.2"
#ENV RELEASE_UP ""
#ENV STATIC_UP "Transfer_CFT_${VERSION_UP}_linux-x86-64_${RELEASE_UP}.zip"

ENV URL_BASE "https://delivery.axway.int/download_true_name.php?static="

#####
# LABELS
LABEL vendor=Axway
LABEL com.axway.cft.os="centos"
LABEL com.axway.cft.version="${VERSION_BASE}"
LABEL com.axway.cft.fullversion="${VERSION_UP}"
LABEL com.axway.cft.release-date="2017-10-04"
LABEL com.axway.centos.version=7
LABEL maintainer="support@axway.com"

LABEL version="0.1"
LABEL description="Docker env for CFT ${VERSION_UP}."

#####
# START POINT

CMD [ "./start.sh" ]

#####
# COPYING USEFUL SCRIPTS

COPY resources/start.sh ./start.sh
COPY resources/runtime_create.sh ./runtime_create.sh

#####
# DOWNLOAD AND INSTALL PRODUCTS

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LC_LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

COPY resources/Install_Axway_Installer.properties .
COPY resources/Install_Transfer_CFT.properties    .
RUN chmod +rw * &&\
    chown cft:cft *

USER cft
RUN curl -k $URL_BASE$STATIC_BASE >cft-distrib.zip && \
    unzip cft-distrib.zip -d setup && \
    cd setup && \
    ./setup.sh -s ../Install_Axway_Installer.properties && \
    cd && \
    rm -rf setup cft-distrib.zip *.properties runtime && \
    mkdir data

#####
# PRODUCTS CONFIGURATION

# - DEFAULT USED PORTS FOR CFT
# PESIT + PESITSSL
EXPOSE 1761-1762
# COMS (Needed for multinode/Multihost)
EXPOSE 1765
# CFT UI
EXPOSE 1766
# Only expose if CG not in the same network
EXPOSE 1767
# Used for REST API
EXPOSE 1768

# - ENV VARIABLES
ENV CFT_FQDN             127.0.0.1
ENV CFT_INSTANCE_ID      cft_docker
ENV CFT_INSTANCE_GROUP   dev.docker
ENV CFT_CATALOG_SIZE     1000
ENV CFT_COM_SIZE         1000
ENV CFT_PESIT_PORT       1761
ENV CFT_PESITSSL_PORT    1762
ENV CFT_COMS_PORT        1765
ENV CFT_COPILOT_PORT     1766
ENV CFT_COPILOT_CG_PORT  1767
ENV CFT_RESTAPI_PORT     1768
ENV CFT_CG_ENABLE        "YES"
ENV CFT_CG_HOST          127.0.0.1
ENV CFT_CG_PORT          12553
ENV CFT_CG_SHARED_SECRET Secret01
ENV CFT_JVM              1024
ENV CFT_KEY              "cat /run/secrets/cft.key"
ENV CFT_CFTDIRRUNTIME    /home/cft/data/runtime


HEALTHCHECK --interval=1m \
            --timeout=5s \
            --start-period=5m \
            --retries=3 \
            CMD . $CFT_CFTDIRRUNTIME/profile && copstatus
