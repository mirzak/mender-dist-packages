FROM debian:stretch

RUN apt-get update && apt-get install -y \
    build-essential \
    git wget gcc-aarch64-linux-gnu \
    debhelper devscripts


ENV CROSS_COMPILE "aarch64-linux-gnu"
ENV CC "$CROSS_COMPILE-gcc"

# Golang environment, for cross-compiling the Mender client
ARG GOLANG_VERSION=1.11.5
RUN wget -q https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOPATH "/root/go"
ENV PATH "$PATH:/usr/local/go/bin"

# Build liblzma from source
RUN wget -q https://tukaani.org/xz/xz-5.2.4.tar.gz \
    && tar -C /root -xzf xz-5.2.4.tar.gz \
    && cd /root/xz-5.2.4 \
    && ./configure --host=$CROSS_COMPILE --prefix=/root/xz-5.2.4/install \
    && make \
    && make install
ENV LIBLZMA_INSTALL_PATH "/root/xz-5.2.4/install"

# Prepare the mender client source
ARG MENDER_VERSION=2.0.1
RUN go get -d github.com/mendersoftware/mender
WORKDIR $GOPATH/src/github.com/mendersoftware/mender
RUN git checkout $MENDER_VERSION

# Prepare the deb-package script
ENV mender_version $MENDER_VERSION
COPY mender-deb-package /usr/local/bin/
ENTRYPOINT bash /usr/local/bin/mender-deb-package $mender_version
