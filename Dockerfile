FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS base
ARG ELECTRUM_VERSION
ARG ELECTRUM_CHECKSUM_SHA512

RUN apk --no-cache add --update ca-certificates openssl wget && update-ca-certificates

RUN wget https://download.electrum.org/${ELECTRUM_VERSION}/Electrum-${ELECTRUM_VERSION}.tar.gz \
    && [ "${ELECTRUM_CHECKSUM_SHA512}  Electrum-${ELECTRUM_VERSION}.tar.gz" = "$(sha512sum Electrum-${ELECTRUM_VERSION}.tar.gz)" ] \
    && echo -e "**************************\n SHA 512 Checksum OK\n**************************"

FROM python:3.9.21-alpine AS builder

ARG BUILD_DATE
ARG VCS_REF
ARG ELECTRUM_VERSION
LABEL maintainer="osintsev@gmail.com" \
	org.label-schema.vendor="Boroda Group" \
	org.label-schema.build-date=$BUILD_DATE \
	org.label-schema.name="Electrum wallet (RPC enabled)" \
	org.label-schema.description="Electrum wallet with JSON-RPC enabled (daemon mode)" \
	org.label-schema.version=$ELECTRUM_VERSION \
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

RUN adduser -D $ELECTRUM_USER

COPY --from=base Electrum-${ELECTRUM_VERSION}.tar.gz ${ELECTRUM_HOME}

RUN apk --no-cache add --virtual runtime-dependencies libsecp256k1 libsecp256k1-dev \
  && apk --no-cache add --virtual build-dependencies gcc musl-dev python3-dev libffi-dev libressl-dev cargo pkgconfig \
  && chown -R ${ELECTRUM_USER}:${ELECTRUM_USER} ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && pip3 install cryptography==44.0.1 ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && rm -f ${ELECTRUM_HOME}/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && apk del build-dependencies

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
