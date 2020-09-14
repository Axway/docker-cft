# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2019 Axway Software SA and its affiliates. All rights reserved.
#
## AMPLIFY Transfer CFT 3.6 Docker image
#
# Building with:
# docker build -f Dockerfile -t axway/cft:3.6 .

#####
# OS PREPARATION

FROM ubuntu:bionic

RUN apt-get update && apt-get install -y \
        libncurses5 \
        curl \
        jq \
        unzip \
        openssl \
        vim && \
        rm -rf /var/lib/apt/lists && \
        mkdir -p /opt/axway && \
        addgroup axway && \
        adduser --disabled-password --gecos '' --home /opt/axway --no-create-home --ingroup axway axway && \
        chown -R axway:axway /opt/axway

USER axway
WORKDIR /opt/axway
ENV LANG=C.UTF-8

#####
ARG VERSION_BASE="3.6"
ARG VERSION_UP="SP1"
ARG RELEASE_BASE="BN12987000"
ARG PACKAGE="Transfer_CFT_${VERSION_BASE}_${VERSION_UP}_linux-x86-64_${RELEASE_BASE}.zip"
ARG URL_BASE="https://delivery.server.com/"
ARG INSTALL_KIT="${URL_BASE}${PACKAGE}"

ADD --chown=axway:axway $INSTALL_KIT installkit.zip

#####
# LABELS
LABEL vendor=Axway
LABEL com.axway.cft.os="ubuntu"
LABEL com.axway.cft.version="${VERSION_BASE}-${VERSION_UP}"
LABEL com.axway.cft.release-date="2020-03-31"
LABEL com.axway.ubuntu.version=bionic
LABEL maintainer="support@axway.com"

LABEL version="1.0"
LABEL description="Transfer CFT ${VERSION_BASE}-${VERSION_UP} Docker image"

#####
# DOWNLOAD AND INSTALL PRODUCTS

ENV CFT_INSTALLDIR /opt/axway/cft
RUN unzip installkit.zip -d setup && \
    cd setup && \
    chmod +x *.run && \
    ./Transfer_CFT_${VERSION_BASE}*_linux-x86-64_*.run  --mode unattended --installdir ${CFT_INSTALLDIR} && \
    cd && \
    rm -rf setup installkit.zip *.properties && \
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
ENV CFT_FQDN             ""
ENV CFT_INSTANCE_ID      docker0_cft
ENV CFT_INSTANCE_GROUP   dev.docker
ENV CFT_CATALOG_SIZE     1000
ENV CFT_COM_SIZE         1000
ENV CFT_PESIT_PORT       1761
ENV CFT_PESITSSL_PORT    1762
ENV CFT_SFTP_PORT        1763
ENV CFT_COMS_PORT        1765
ENV CFT_COPILOT_PORT     1766
ENV CFT_COPILOT_CG_PORT  1767
ENV CFT_RESTAPI_PORT     1768
ENV CFT_CG_ENABLE        "YES"
ENV CFT_CG_HOST          127.0.0.1
ENV CFT_CG_PORT          12553
ENV CFT_CG_SHARED_SECRET ""
ENV CFT_CG_POLICY        ""
ENV CFT_CG_PERIODICITY   ""
ENV CFT_CG_AGENT_NAME    ""
ENV CFT_JVM              1024
ENV CFT_KEY              "cat /run/secrets/cft.key"
ENV CFT_CFTDIRRUNTIME    "/opt/axway/data/runtime"
ENV CFT_EXPORTDIR        ".export"
ENV CFT_EXPORTCMD        "/opt/axway/export_bases.sh"
ENV CFT_MULTINODE_ENABLE "NO"

#####
# COPYING USEFUL SCRIPTS

COPY --chown=axway:axway resources/*.sh ./

#####
# START POINT

CMD [ "./start.sh" ]

HEALTHCHECK --interval=1m \
            --timeout=5s \
            --start-period=5m \
            --retries=3 \
            CMD . $CFT_CFTDIRRUNTIME/profile && copstatus

