# `rust-musl-builder`: Docker container for easily building static Rust binaries

[![Docker Image](https://img.shields.io/docker/pulls/ekidd/rust-musl-builder.svg?maxAge=2592000)](https://hub.docker.com/r/ekidd/rust-musl-builder/)

- [Source on GitHub](https://github.com/emk/rust-musl-builder)
- [Changelog](https://github.com/emk/rust-musl-builder/blob/master/CHANGELOG.md)

**UPDATED:**

- We are now using Ubuntu 20.04 as our base image!
- We are now running builds on GitHub, including scheduled builds of `stable` and `beta` every Thursday!

See our [CHANGELOG](https://github.com/emk/rust-musl-builder/blob/main/CHANGELOG.md) for more details.

## What is this?

This image allows you to build static Rust binaries using `diesel`, `sqlx` or `openssl`. These images can be distributed as single executable files with no dependencies, and they should work on any modern Linux system.

To try it, run:

```sh
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'
rust-musl-builder cargo build --release
```

This command assumes that `$(pwd)` is readable and writable by uid 1000, gid 1000. At the moment, it doesn't attempt to cache libraries between builds, so this is best reserved for making final release builds.

For a more realistic example, see the `Dockerfile`s for [examples/using-diesel](./examples/using-diesel) and [examples/using-sqlx](./examples/using-sqlx).

## Should you use this to distribute your Rust program?

In general, linking against OpenSSL and/or `libpq` will limit your portability and bring you extra headaches. In an ideal world, you would avoid C libraries, replace OpenSSL with [`rustls`][rustls], and build your binary using [`cross`](https://github.com/rust-embedded/cross). It's a super nice workflow:

```sh
# What you would ideally do instead of using rust-musl-builder.
cross build --target=x86_64-unknown-linux-musl --release
```

`cross` is a drop-in replacement for `cargo`, and it will allow you cross-compile for many different platforms. Even better, it's supported by the Rust Tools team. The downside: It doesn't support OpenSSL, or anything which requires OpenSSL. So if you want to do this, you'll need to configure libraries like `hyper`, `reqwest` and `tokio-postgres` to use [`rustls`][rustls] instead. See the documentation for each library for instructions. This is often the least painful choice.

### Use case 1 for `rust-musl-builder`: You need to link `libpq` and OpenSSL for `diesel`

The standard PostgreSQL client library for C is `libpq`. The popular [Diesel](https://diesel.rs/) crate uses `libpq`. And `libpq` links against OpenSSL. So in order to use `diesel`, you need to link against OpenSSL. If you want to link OpenSSL and `libpq` statically, then you can't use `cross`. But you can use `rust-musl-builder`.

### Use case 2 for `rust-musl-builder`: You need to support weird TLS certificates

[`rustls`][rustls] is a fantastic crate and it's very easy to work with. However, it relies on `webpki` to parse TLS certificates, and `webpki` may break if it encounters weird certificates. For example, [it requires a valid `subjectAltName`](https://github.com/briansmith/webpki/issues/11). Unfortunately, hosted PostgreSQL servers tend to omit `subjectAltName`. This is known to be a problem with the soon-to-be-defunct Citus Data, and with Google's Cloud PostgreSQL solution. In these cases, you'll probably need OpenSSL for now.

[rustls]: https://github.com/rustls

## Deploying your Rust application

With a bit of luck, you should be able to just copy your application binary from `target/x86_64-unknown-linux-musl/release`, and install it directly on any reasonably modern x86_64 Linux machine.  In particular, you should be able make static release binaries using TravisCI and GitHub, or you can copy your Rust application into an [Alpine Linux container][]. See below for details!

## Available tags

In general, we provide the following tagged Docker images:

- `latest`, `stable`: Current stable Rust, now with OpenSSL 1.1. We
  try to update this fairly rapidly after every new stable release, and
  after most point releases.
- `X.Y.Z`: Specific versions of stable Rust.
- `beta`: This usually gets updated every six weeks alongside the stable
  release. It will usually not be updated for beta bugfix releases.
- `nightly-YYYY-MM-DD`: Specific nightly releases. These should almost
  always support `clippy`, `rls` and `rustfmt`, as verified using
  [rustup components history][comp]. If you need a specific date for
  compatibility with `tokio` or another popular library using unstable
  Rust, please file an issue.

At a minimum, each of these images should be able to
compile [examples/using-diesel](./examples/using-diesel) and [examples/using-sqlx](./examples/using-sqlx).

[comp]: https://rust-lang.github.io/rustup-components-history/index.html

## Caching builds

You may be able to speed up build performance by adding the following `-v` commands to the `rust-musl-builder` alias:

```sh
-v cargo-git:/home/rust/.cargo/git
-v cargo-registry:/home/rust/.cargo/registry
-v target:/home/rust/src/target
```

You will also need to fix the permissions on the mounted volumes:

```sh
rust-musl-builder sudo chown -R rust:rust \
  /home/rust/.cargo/git /home/rust/.cargo/registry /home/rust/src/target
```

## How it works

`rust-musl-builder` uses [musl-libc][], [musl-gcc][], and the new [rustup][] `target` support.  It includes static versions of several libraries:

- The standard `musl-libc` libraries.
- OpenSSL, which is needed by many Rust applications.
- `libpq`, which is needed for applications that use `diesel` with PostgreSQL.
- `libz`, which is needed by `libpq`.
- SQLite3. See [examples/using-diesel](./examples/using-diesel/).

This library also sets up the environment variables needed to compile popular Rust crates using these libraries.

## Extras

This image also supports the following extra goodies:

- Basic compilation for `armv7` using `musl-libc`. Not all libraries are supported at the moment, however.
- [`mdbook`][mdbook] and `mdbook-graphviz` for building searchable HTML documentation from Markdown files. Build manuals to use alongside your `cargo doc` output!
- [`cargo about`][about] to collect licenses for your dependencies.
- [`cargo deb`][deb] to build Debian packages
- [`cargo deny`][deny] to check your Rust project for known security issues.

## Making OpenSSL work

If your application uses OpenSSL, you will also need to take a few extra steps to make sure that it can find OpenSSL's list of trusted certificates, which is stored in different locations on different Linux distributions. You can do this using [`openssl-probe`](https://crates.io/crates/openssl-probe) as follows:

```rust
fn main() {
    openssl_probe::init_ssl_cert_env_vars();
    //... your code
}
```

## Making Diesel work

In addition to setting up OpenSSL, you'll need to add the following lines to your `Cargo.toml`:

```toml
[dependencies]
diesel = { version = "1", features = ["postgres", "sqlite"] }

# Needed for sqlite.
libsqlite3-sys = { version = "*", features = ["bundled"] }

# Needed for Postgres.
openssl = "*"
```

For PostgreSQL, you'll also need to include `diesel` and `openssl` in your `main.rs` in the following order (in order to avoid linker errors):

```rust
extern crate openssl;
#[macro_use]
extern crate diesel;
```

If this doesn't work, you _might_ be able to fix it by reversing the order. See [this PR](https://github.com/emk/rust-musl-builder/issues/69) for a discussion of the latest issues involved in linking to `diesel`, `pq-sys` and `openssl-sys`.

## Making static releases with Travis CI and GitHub

These instructions are inspired by [rust-cross][].

First, read the [Travis CI: GitHub Releases Uploading][uploading] page, and run `travis setup releases` as instructed.  Then add the following lines to your existing `.travis.yml` file, replacing `myapp` with the name of your package:

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

Next, copy [`build-release`](./examples/build-release) into your project and run `chmod +x build-release`.

Finally, add a `Dockerfile` to perform the actual build:

```Dockerfile
FROM ekidd/rust-musl-builder

# We need to add the source code to the image because `rust-musl-builder`
# assumes a UID of 1000, but TravisCI has switched to 2000.
ADD --chown=rust:rust . ./

CMD cargo build --release
```

When you push a new tag to your project, `build-release` will automatically build new Linux binaries using `rust-musl-builder`, and new Mac binaries with Cargo, and it will upload both to the GitHub releases page for your repository.

For a working example, see [faradayio/cage][cage].

[rust-cross]: https://github.com/japaric/rust-cross
[uploading]: https://docs.travis-ci.com/user/deployment/releases
[cage]: https://github.com/faradayio/cage

## Making tiny Docker images with Alpine Linux and Rust binaries

Docker now supports [multistage builds][multistage], which make it easy to build your Rust application with `rust-musl-builder` and deploy it using [Alpine Linux][]. For a working example, see [`examples/using-diesel/Dockerfile`](./examples/using-diesel/Dockerfile).

[multistage]: https://docs.docker.com/engine/userguide/eng-image/multistage-build/
[Alpine Linux]: https://alpinelinux.org/

## Adding more C libraries

If you're using Docker crates which require specific C libraries to be installed, you can create a `Dockerfile` based on this one, and use `musl-gcc` to compile the libraries you need.  For an example, see [`examples/adding-a-library/Dockerfile`](./examples/adding-a-library/Dockerfile). This usually involves a bit of experimentation for each new library, but it seems to work well for most simple, standalone libraries.

If you need an especially common library, please feel free to submit a pull request adding it to the main `Dockerfile`!  We'd like to support popular Rust crates out of the box.

## Development notes

After modifying the image, run `./test-image` to make sure that everything works.

## Other ways to build portable Rust binaries

If for some reason this image doesn't meet your needs, there's a variety of other people working on similar projects:

- [messense/rust-musl-cross](https://github.com/messense/rust-musl-cross) shows how to build binaries for many different architectures.
- [japaric/rust-cross](https://github.com/japaric/rust-cross) has extensive instructions on how to cross-compile Rust applications.
- [clux/muslrust](https://github.com/clux/muslrust) also supports libcurl.
- [golddranks/rust_musl_docker](https://github.com/golddranks/rust_musl_docker). Another Docker image.

## License

Either the [Apache 2.0 license](./LICENSE-APACHE.txt), or the
[MIT license](./LICENSE-MIT.txt).

[Alpine Linux container]: https://hub.docker.com/_/alpine/
[about]: https://github.com/EmbarkStudios/cargo-about
[deb]: https://github.com/mmstick/cargo-deb
[deny]: https://github.com/EmbarkStudios/cargo-deny
[mdbook]: https://github.com/rust-lang-nursery/mdBook
[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[rustup]: https://www.rustup.rs/
