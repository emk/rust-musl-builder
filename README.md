# NOTE:
Fork of https://github.com/emk/rust-musl-builder to have control of updates


# `rust-musl-builder`: Docker container for easily building static Rust binaries

[![Docker Image](https://img.shields.io/docker/pulls/xliiv/rust-musl-builder.svg?maxAge=2592000)](https://hub.docker.com/r/xliiv/rust-musl-builder/)

Do you want to compile a completely static Rust binary with no external
dependencies?  If so, try:

```sh
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src xliiv/rust-musl-builder'
rust-musl-builder cargo build --release
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
FROM xliiv/rust-musl-builder

RUN VERS=1.2.8 && \
    cd /home/rust/libs && \
    curl -LO http://zlib.net/zlib-$VERS.tar.gz && \
    tar xzf zlib-$VERS.tar.gz && cd zlib-$VERS && \
    CC=musl-gcc ./configure --static --prefix=/usr/local/musl && \
    make && sudo make install && \
    cd .. && rm -rf zlib-$VERS.tar.gz zlib-$VERS
```

This usually involves a bit of experimentation for each new library, but it
seems to work well for most simple, standalone libraries.

If you need an especially common library, please feel free to submit a pull
request adding it to the main `Dockerfile`!  We'd like to support popular
Rust crates out of the box.

## Making static releases with Travis CI and GitHub

These instructions are inspired by [rust-cross][].

First, read the [Travis CI: GitHub Releases Uploading][uploading] page, and
run `travis setup releases` as instructed.  Then add the following lines to
your existing `.travis.yml` file, replacing `myapp` with the name of your
package:

```yaml
language: rust
sudo: required
os:
- linux
- osx
rust:
- stable
services:
- docker
before_deploy: "./build-release myapp ${TRAVIS_TAG}-${TRAVIS_OS_NAME}"
deploy:
  provider: releases
  api_key:
    secure: "..."
  file_glob: true
  file: "myapp-${TRAVIS_TAG}-${TRAVIS_OS_NAME}.*"
  skip_cleanup: true
  on:
    rust: stable
    tags: true
```

Next, copy [`build-release`](./examples/build-release) into your project
and run `chmod +x build-release`.

When you push a new tag to your project, `build-release` will automatically
build new Linux binaries using `rust-musl-builder`, and new Mac binaries
with Cargo, and it will upload both to the GitHub releases page for your
repository.

For a working example, see [faradayio/conductor][conductor].

[rust-cross]: https://github.com/japaric/rust-cross
[uploading]: https://docs.travis-ci.com/user/deployment/releases
[conductor]: https://github.com/faradayio/conductor

## Development notes

After modifying the image, run `./test-image` to make sure that everything
works.

MAINTAINERS ONLY: After making changes, they must be pushed to the `stable`
branch to build the official `stable` and `latest` images on Docker Hub.
Tagged versions of Rust (such as `1.11`) must be given their own branches
and manually configured on Docker Hub.

```sh
git push origin master:stable
git push origin master:rust-$(rustc --version | awk '{ print $2 }')
```

## License

Either the [Apache 2.0 license](./LICENSE-APACHE.txt), or the
[MIT license](./LICENSE-MIT.txt).

[Alpine Linux container]: https://hub.docker.com/_/alpine/
[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[rustup]: https://www.rustup.rs/
