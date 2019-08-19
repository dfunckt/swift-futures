FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV PATH=/toolchain/usr/bin:"${PATH}"
VOLUME ["/src"]

WORKDIR /toolchain

RUN apt-get update && apt-get install -yq --no-install-recommends \
    build-essential \
    clang \
    curl \
    gpg-agent \
    libcurl4 \
    libicu-dev \
    libpython2.7 \
    libxml2 \
    libz-dev \
    pkg-config \
    software-properties-common \
  && rm -rf /var/lib/apt/lists/*

ARG TOOLCHAIN_URL

COPY ./Scripts/install-toolchain.sh .
RUN ./install-toolchain.sh "${TOOLCHAIN_URL}"

WORKDIR /src

ENTRYPOINT ["/toolchain/usr/bin/swift"]
