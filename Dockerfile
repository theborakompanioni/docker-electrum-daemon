# python:3.9.21-bullseye@sha256:ccb1360e4eddf52a74bbbabb0c5a1c8640f09440e2b76228c6a69dd4b683f726

FROM python:3.9.21-bullseye AS base
ARG ELECTRUM_VERSION
ARG ELECTRUM_CHECKSUM_SHA512

RUN wget https://download.electrum.org/${ELECTRUM_VERSION}/Electrum-${ELECTRUM_VERSION}.tar.gz \
    && [ "${ELECTRUM_CHECKSUM_SHA512}  Electrum-${ELECTRUM_VERSION}.tar.gz" = "$(sha512sum Electrum-${ELECTRUM_VERSION}.tar.gz)" ] \
    && echo -e "**************************\n SHA 512 Checksum OK\n**************************"

FROM python:3.9.21-slim-bullseye AS builder

ARG BUILD_DATE
ARG VCS_REF
ARG ELECTRUM_VERSION
LABEL maintainer="osintsev@gmail.com" \
	org.label-schema.vendor="Boroda Group" \
	org.label-schema.build-date=$BUILD_DATE \
	org.label-schema.name="Electrum wallet (RPC enabled)" \
	org.label-schema.description="Electrum wallet with JSON-RPC enabled (daemon mode)" \
	org.label-schema.version=$VERSION \
	org.label-schema.vcs-ref=$VCS_REF \
	org.label-schema.vcs-url="https://github.com/osminogin/docker-electrum-daemon" \
	org.label-schema.usage="https://github.com/osminogin/docker-electrum-daemon#getting-started" \
	org.label-schema.license="MIT" \
	org.label-schema.url="https://electrum.org" \
	org.label-schema.docker.cmd='docker run -d --name electrum-daemon --publish 127.0.0.1:7000:7000 --volume /srv/electrum:/data osminogin/electrum-daemon' \
	org.label-schema.schema-version="1.0"

ENV ELECTRUM_USER=electrum
ENV ELECTRUM_PASSWORD=electrumz
ENV ELECTRUM_HOME=/home/$ELECTRUM_USER
ENV ELECTRUM_NETWORK=mainnet

RUN addgroup --system ${ELECTRUM_USER} \
	&& adduser --system --disabled-login --ingroup ${ELECTRUM_USER} --gecos 'electrum user' ${ELECTRUM_USER}

RUN apt-get update \
	&& apt-get install -qq --no-install-recommends --no-install-suggests -y gcc musl-dev libsecp256k1-dev \
	&& pip3 install cryptography==2.6.1

COPY --from=base Electrum-${ELECTRUM_VERSION}.tar.gz ${ELECTRUM_HOME}
RUN chown -R ${ELECTRUM_USER}:${ELECTRUM_USER} ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz \
&& tar -xf ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz --directory ${ELECTRUM_HOME} \
&& rm -f ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz \
&& chown -R ${ELECTRUM_USER}:${ELECTRUM_USER} ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION} \
&& ln -sf ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}/run_electrum /usr/local/bin/electrum


RUN apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/*

RUN mkdir -p /data \
	    ${ELECTRUM_HOME}/.electrum/wallets/ \
	    ${ELECTRUM_HOME}/.electrum/testnet/wallets/ \
	    ${ELECTRUM_HOME}/.electrum/regtest/wallets/ \
	    ${ELECTRUM_HOME}/.electrum/simnet/wallets/ \
	&& chown -R ${ELECTRUM_USER}:${ELECTRUM_USER} ${ELECTRUM_HOME}/.electrum /data \
	&& ln -sf /data ${ELECTRUM_HOME}/.electrum

USER $ELECTRUM_USER
WORKDIR $ELECTRUM_HOME
VOLUME /data
EXPOSE 7000

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["electrum"]
