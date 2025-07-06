FROM alpine:3.22.0@sha256:8a1f59ffb675680d47db6337b49d22281a139e9d709335b492be023728e11715 AS base
ARG ELECTRUM_VERSION
ARG ELECTRUM_CHECKSUM_SHA512

RUN apk --no-cache add --update ca-certificates openssl wget && update-ca-certificates

RUN wget https://download.electrum.org/${ELECTRUM_VERSION}/Electrum-${ELECTRUM_VERSION}.tar.gz \
    && [ "${ELECTRUM_CHECKSUM_SHA512}  Electrum-${ELECTRUM_VERSION}.tar.gz" = "$(sha512sum Electrum-${ELECTRUM_VERSION}.tar.gz)" ] \
    && echo -e "**************************\n SHA 512 Checksum OK\n**************************"

FROM python:3.10.18-alpine3.22@sha256:8d21601f9f531162bc0c37ae0ac9e7a070e512a6ae0ffc4090118866902c9caa AS builder

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
  && ELECTRUM_ECC_DONT_COMPILE=1 pip3 install cryptography==44.0.1 /home/electrum/Electrum-${ELECTRUM_VERSION}.tar.gz \
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
