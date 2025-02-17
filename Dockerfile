FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS base
ARG ELECTRUM_VERSION
ARG ELECTRUM_CHECKSUM_SHA512

RUN apk --no-cache add --update ca-certificates openssl wget && update-ca-certificates

RUN wget https://download.electrum.org/${ELECTRUM_VERSION}/Electrum-${ELECTRUM_VERSION}.tar.gz \
    && [ "${ELECTRUM_CHECKSUM_SHA512}  Electrum-${ELECTRUM_VERSION}.tar.gz" = "$(sha512sum Electrum-${ELECTRUM_VERSION}.tar.gz)" ] \
    && echo -e "**************************\n SHA 512 Checksum OK\n**************************"

FROM python:3.9.21-alpine3.21@sha256:3cc37465a79297e472943a78c94eb094e808293b084716c80bc27d4eb3a5e3fd AS builder

ARG BUILD_DATE
ARG VCS_REF
ARG ELECTRUM_VERSION
LABEL maintainer="theborakompanioni+github@gmail.com" \
	org.label-schema.vendor="theborakompanioni" \
	org.label-schema.build-date="${BUILD_DATE}" \
	org.label-schema.name="Electrum wallet (RPC enabled)" \
	org.label-schema.description="Electrum wallet with JSON-RPC enabled (daemon mode)" \
	org.label-schema.version="${ELECTRUM_VERSION}" \
	org.label-schema.vcs-ref="${VCS_REF}" \
	org.label-schema.vcs-url="https://github.com/theborakompanioni/docker-electrum-daemon" \
	org.label-schema.usage="https://github.com/theborakompanioni/docker-electrum-daemon#getting-started" \
	org.label-schema.license="MIT" \
	org.label-schema.url="https://electrum.org" \
	org.label-schema.docker.cmd='docker run --name electrum-daemon --publish 127.0.0.1:7000:7000 --volume ./.data:/home/electrum/.electrum theborakompanioni/electrum-daemon' \
	org.label-schema.schema-version="1.0"

ENV ELECTRUM_RPCUSER=electrum
ENV ELECTRUM_RPCPASSWORD=electrumz
ENV ELECTRUM_RPCPORT=7000
ENV ELECTRUM_NETWORK=mainnet
ENV DRY_RUN=false

# "`-D` Don't assign a password"
RUN addgroup --gid 1000 -S electrum && \
    adduser --uid 1000 -D -S electrum -G electrum

COPY --from=base Electrum-${ELECTRUM_VERSION}.tar.gz /home/electrum

RUN apk --no-cache add --virtual runtime-dependencies libsecp256k1 libsecp256k1-dev \
  && apk --no-cache add --virtual build-dependencies gcc musl-dev python3-dev libffi-dev libressl-dev cargo pkgconfig \
  && chown electrum:electrum /home/electrum/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && pip3 install cryptography==44.0.1 /home/electrum/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && rm -f /home/electrum/Electrum-${ELECTRUM_VERSION}.tar.gz \
  && apk del build-dependencies

RUN mkdir -p /home/electrum/.electrum/wallets/ \
    /home/electrum/.electrum/testnet/wallets/ \
    /home/electrum/.electrum/testnet4/wallets/ \
    /home/electrum/.electrum/regtest/wallets/ \
    /home/electrum/.electrum/simnet/wallets/ \
    /home/electrum/.electrum/signet/wallets/ \
  && chown -R electrum:electrum /home/electrum

USER electrum
WORKDIR /home/electrum
#VOLUME /home/electrum/.electrum
EXPOSE 7000

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["electrum"]
