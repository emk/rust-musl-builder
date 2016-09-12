# Use Debian 16.04 as the base for our Rust musl toolchain, because of
# https://github.com/rust-lang/rust/issues/34978 (as of Rust 1.11).
FROM ubuntu:16.04

# Make sure we have basic dev tools for building C libraries.  Our goal
# here is to support the musl-libc builds and Cargo builds needed for a
# large selection of the most popular crates.
#
# We also set up a `rust` user by default, in whose account we'll install
# the Rust toolchain.  This user has sudo privileges if you need to install
# any more software.
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        curl \
        file \
        git \
        sudo \
        xutils-dev \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd rust --user-group --create-home --shell /bin/bash --groups sudo

# Allow sudo without a password.
ADD sudoers /etc/sudoers.d/nopasswd

# Run all further code as user `rust`, and create our working directories
# as the appropriate user.
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src

# Set up our path with all our binary directories, including those for the
# musl-gcc toolchain and for our Rust toolchain.
ENV PATH=/home/rust/.cargo/bin:/usr/local/musl/bin:/usr/local/bin:/usr/bin:/bin

# Install our Rust toolchain and the `musl` target.  We patch the
# command-line we pass to the installer so that it won't attempt to
# interact with the user or fool around with TTYs.  We also set the default
# `--target` to musl so that our users don't need to keep overriding it
# manually.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    rustup default stable && \
    rustup target add x86_64-unknown-linux-musl
ADD cargo-config.toml /home/rust/.cargo/config

# We'll build our libraries in subdirectories of /home/rust/libs.  Please
# clean up when you're done.
WORKDIR /home/rust/libs

# Build the musl-libc toolchain, which installs itself in /usr/local/musl.
RUN sudo chown rust:rust /home/rust/libs && \
    git clone git://git.musl-libc.org/musl && cd musl && \
    ./configure && make && sudo make install && \
    cd .. && rm -rf musl

# Build a static library version of OpenSSL using musl-libc.  This is
# needed by the popular Rust `hyper` crate.
RUN VERS=1.0.2g && \
    curl -O https://www.openssl.org/source/openssl-$VERS.tar.gz && \
    tar xvzf openssl-$VERS.tar.gz && cd openssl-$VERS && \
    env CC=musl-gcc ./config --prefix=/usr/local/musl && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make depend && \
    make && sudo make install && \
    cd .. && rm -rf openssl-$VERS.tar.gz openssl-$VERS
ENV OPENSSL_INCLUDE_DIR=/usr/local/musl/include/ \
    DEP_OPENSSL_INCLUDE=/usr/local/musl/include/ \
    OPENSSL_LIB_DIR=/usr/local/musl/lib/ \
    OPENSSL_STATIC=1

# (Please feel free to submit pull requests for musl-libc builds of other C
# libraries needed by the most popular and common Rust crates, to avoid
# everybody needing to build them manually.)

# Expect our source code to live in /home/rust/src.  We'll run the build as
# user `rust`, which will be uid 1000, gid 1000 outside the container.
WORKDIR /home/rust/src
