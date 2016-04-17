# Use Debian 8.0 "Jessie" as the base for our Rust musl toolchain.
FROM debian:jessie

# Make sure we have basic dev tools for building C libraries, and any
# shared library dev packages we'll need, and create a `rust` user in
# whose home directory we'll install the Rust compilers.
#
# Our goal here is to support the musl-libc builds and Cargo builds needed
# for a large selection of the most popular crates.
#
# We also set up a `rust` user by default, in whose account we'll install
# the Rust toolchain.  This user has sudo privileges if you need to install
# any more software.
RUN apt-get update && \
    apt-get install -y build-essential sudo git curl file xutils-dev cmake && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd rust --user-group --create-home --shell /bin/bash --groups sudo && \
    echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up our path with all the binary directories we're going to create,
# including those for the musl-gcc toolchain and for our Rust toolchain.
ENV PATH=/home/rust/.cargo/bin:/usr/local/musl/bin:/usr/local/bin:/usr/bin:/bin

# Build the musl-libc toolchain, which installs itself in /usr/local/musl.
WORKDIR /musl
RUN git clone git://git.musl-libc.org/musl && cd musl && \
    ./configure && make install

# Build a static library version of OpenSSL using musl-libc.  This is
# needed by the popular Rust `hyper` crate.
RUN VERS=1.0.2g && \
    curl -O https://www.openssl.org/source/openssl-$VERS.tar.gz && \
    tar xvzf openssl-$VERS.tar.gz && cd openssl-$VERS && \
    env CC=musl-gcc ./config --prefix=/usr/local/musl && \
    make depend && make && make install
ENV OPENSSL_INCLUDE_DIR=/usr/local/musl/include/ \
    OPENSSL_LIB_DIR=/usr/local/musl/lib/ \
    OPENSSL_STATIC=1

# (Please feel free to submit pull requests for musl-libc builds of other C
# libraries needed by the most popular and common Rust crates, to avoid
# everybody needing to build them manually.)

# Delete our musl-libc build directory.
RUN rm -rf /musl

# Mount the source code we want to build on /home/rust/src.  We do this as
# user `rust`, which will be uid 1000, gid 1000 outside the container.
USER rust
WORKDIR /home/rust/src

# Install our Rust toolchain and the `musl` target.  We patch the
# command-line we pass to the installer so that it won't attempt to
# interact with the user or fool around with TTYs.  We also set the default
# `--target` to musl so that our users don't need to keep overriding it
# manually.
RUN curl https://sh.rustup.rs -sSf | sed 's,run "$_file" < /dev/tty,run "$_file" -y,' | sh && \
    rustup default stable && \
    rustup target add x86_64-unknown-linux-musl && \
    echo "[build]\ntarget = \"x86_64-unknown-linux-musl\"\n" >> /home/rust/.cargo/config
