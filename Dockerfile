FROM debian:bookworm-slim as builder

ARG TOOLCHAIN=nightly-2022-05-03
ARG TARGETS="x86_64-unknown-linux-musl x86_64-unknown-linux-gnu x86_64-unknown-none wasm32-wasi"
ARG OPENSSL_VERSION=1.1.1o

USER root

RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -yq \
        build-essential \
        cmake \
        ca-certificates \
        curl \
        file \
        git \
        musl-dev \
        musl-tools \
        libssl-dev \
        linux-libc-dev \
        pkgconf \
        xutils-dev \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ln -s "/usr/bin/g++" "/usr/bin/musl-g++"
RUN echo "Building OpenSSL" && \
    ls /usr/include/linux && \
    mkdir -p /usr/local/musl/include && \
    ln -s /usr/include/linux /usr/local/musl/include/linux && \
    ln -s /usr/include/x86_64-linux-gnu/asm /usr/local/musl/include/asm && \
    ln -s /usr/include/asm-generic /usr/local/musl/include/asm-generic && \
    cd /tmp && \
    short_version="$(echo "$OPENSSL_VERSION" | sed s'/[a-z]$//' )" && \
    curl -fLO "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" || \
        curl -fLO "https://www.openssl.org/source/old/${short_version}/openssl-${OPENSSL_VERSION}.tar.gz" && \
    tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" && cd "openssl-${OPENSSL_VERSION}" && \
    env CC=musl-gcc ./Configure no-shared no-zlib -fPIC --prefix=/usr/local/musl -DOPENSSL_NO_SECURE_MEMORY linux-x86_64 && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make depend && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make && \
    make install_sw && \
    rm /usr/local/musl/include/linux /usr/local/musl/include/asm /usr/local/musl/include/asm-generic && \
    rm -r /tmp/*

RUN mkdir -p /root/libs /root/src /root/.cargo && \
    ln -s /opt/rust/cargo/config /root/.cargo/config
ENV RUSTUP_HOME=/opt/rust/rustup \
    PATH=/root/.cargo/bin:/opt/rust/cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/musl/ \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
    TARGET=musl

RUN curl https://sh.rustup.rs -sSf | \
        sh -s -- -y --default-toolchain $TOOLCHAIN --profile minimal && \
        rustup component add rustfmt && \
        rustup component add clippy && \
        rustup component add miri && \
        rustup component add rust-src && \
        rustup target add ${TARGETS}
ADD cargo-config.toml /opt/rust/cargo/config
WORKDIR /root/src
