ARG TOOLCHAIN
FROM $TOOLCHAIN
VOLUME ["/src"]
WORKDIR /src
RUN /usr/bin/swift --version
ENTRYPOINT ["/usr/bin/swift"]
