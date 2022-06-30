# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#
# Axway Transfer CFT Docker image
#
# Building with:
# docker build -f Dockerfile -t axway/cft:3.8 .

#
# Stage 1 : build
#

FROM ubuntu:20.04 AS builder

RUN apt-get -y update && apt-get install -y \
        curl \
        unzip \
        binutils && \
        rm -rf /var/lib/apt/lists && \
        mkdir -p /opt/axway && \
        adduser --disabled-password --gecos '' --home /opt/axway --no-create-home --uid 1000 --gid 0 axway && \
        chown -R axway:0 /opt/axway

USER 1000
WORKDIR /opt/axway
ENV LANG=C.UTF-8

# Download and install Transfer CFT package

ARG PACKAGE="Transfer_CFT_3.10.2203_Install_b9dcb51484_linux-x86-64.zip"
ARG URL_BASE="https://delivery.server.int/"
ARG INSTALL_KIT="${URL_BASE}${PACKAGE}"

ADD --chown=axway:0 $INSTALL_KIT installkit.zip

RUN unzip installkit.zip -d setup && \
    cd setup && \
    chmod +x *.run && \
    ./Transfer_CFT_*_linux-x86-64*.run  --mode unattended --installdir /opt/axway/cft --accept_general_conditions yes && \
    strip -d /opt/axway/cft/home/lib/* && \
    cd && \
    rm -rf setup installkit.zip *.properties && \
    chown -R axway:0 /opt/axway && \
    chmod -R u+x /opt/axway && \
    chmod -R g=u /opt/axway

# Copying useful scripts

COPY --chown=axway:0 resources/*.sh resources/uid_entrypoint ./

#
# Stage 2 : create final image
#

FROM ubuntu:20.04

RUN apt-get -y update && apt-get upgrade -y && apt-get install -y \
        curl \
        jq \
        openssl \
        vim && \
        rm -rf /var/lib/apt/lists && \
        adduser --disabled-password --gecos '' --home /opt/axway --no-create-home --uid 1000 --gid 0 axway && \
        mkdir -p /opt/axway/data && \
        chown -R axway:0 /opt/axway && \
        chmod -R u+x /opt/axway && \
        chmod -R g=u /opt/axway /etc/passwd

COPY --chown=axway:0 --from=builder /opt/axway /opt/axway

USER 1000
WORKDIR /opt/axway
ENV HOME=/opt/axway
ENV LANG=C.UTF-8

ARG BUILD_DATE
ARG BUILD_VERSION="3.10.2203"
ARG BUILD_REVISION="b9dcb51484"

LABEL created="${BUILD_DATE}"
LABEL url="https://www.axway.com"
LABEL vendor="Axway"
LABEL maintainer="support@axway.com"
LABEL title="Transfer CFT"
LABEL version="${BUILD_VERSION}"
LABEL revision="${BUILD_REVISION}"

# Exposed ports

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

# Environment variables

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
ENV CFT_INSTALLDIR       "/opt/axway/cft"
ENV CFT_CFTDIRRUNTIME    "/opt/axway/data/runtime"
ENV CFT_EXPORTDIR        ".export"
ENV CFT_EXPORTCMD        "/opt/axway/export_bases.sh"
ENV CFT_MULTINODE_ENABLE "NO"

# Entry point

ENTRYPOINT [ "/opt/axway/uid_entrypoint" ]
CMD [ "./start.sh" ]

HEALTHCHECK --interval=1m \
            --timeout=5s \
            --start-period=5m \
            --retries=3 \
            CMD . $CFT_CFTDIRRUNTIME/profile && copstatus
