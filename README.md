# `rust-musl-builder`: Docker container for easily building static Rust binaries

Do you want to compile a completely static Rust binary with no external
dependencies?  If so, try:

```sh
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'
rust-musl-builder cargo build --rebase
```

This command assumes that `$(pwd)` is readable and writable by uid 1000,
gid 1000.  It will output binaries in
`target/x86_64-unknown-linux-musl/release`.  At the moment, it doesn't
attempt to cache libraries between builds, so this is best reserved for
making final release builds.

## Deploying your Rust application

With a bit of luck, you should be able to just copy your application binary
from `target/x86_64-unknown-linux-musl/release`, and install it directly on
any reasonably modern x86_64 Linux machine.  In particular, you should be
able to copy your Rust application into an
[Alpine Linux container][].

## How it works

`rust-musl-builder` uses [musl-libc][], [musl-gcc][], and the new
[rustup][] `target` support.  It includes static versions of several
libraries:

- The standard `musl-libc` libraries.
- OpenSSL, which is needed by many Rust applications.

## Adding more C libraries

If you're using Docker crates which require specific C libraries to be
installed, you can create a Dockerfile based on this one, and use
`musl-gcc` to compile the libraries you need.  For example:

```Dockerfile
FROM ekidd/rust-musl-builder:stable

RUN VERS=1.2.8 && \
    mkdir -p /home/rust/libs && cd /home/rust/libs && \
    curl -LO http://zlib.net/zlib-$VERS.tar.gz && \
    tar xzf zlib-$VERS.tar.gz && cd zlib-$VERS && \
    CC=musl-gcc ./configure --static --prefix=/usr/local/musl && \
    make && sudo make install && \
    rm -rf /home/rust/libs/zlib-$VERS.tar.gz /home/rust/libs/zlib-$VERS
```

This usually involves a bit of experimentation for each new library, but it
seems to work well for most simple, standalone libraries.

If you need an especially common library, please feel free to submit a pull
request adding it to the main `Dockerfile`!  We'd like to support popular
Rust crates out of the box.

[Alpine Linux container]: https://hub.docker.com/_/alpine/
[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[rustup]: https://www.rustup.rs/
