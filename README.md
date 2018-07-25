# `rust-musl-builder`: Docker container for easily building static Rust binaries

[![Docker Image](https://img.shields.io/docker/pulls/ekidd/rust-musl-builder.svg?maxAge=2592000)](https://hub.docker.com/r/ekidd/rust-musl-builder/)

Do you want to compile a completely static Rust binary with no external dependencies?  If so, try:

```sh
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'
rust-musl-builder cargo build --release
```

This command assumes that `$(pwd)` is readable and writable by uid 1000, gid 1000. At the moment, it doesn't attempt to cache libraries between builds, so this is best reserved for making final release builds.

To target ARM hard float (Raspberry Pi):
```sh
rust-musl-builder cargo build --target=armv7-unknown-linux-musleabihf --release
```

Binaries will be written to `target/$TARGET_ARCHITECTURE/release`. By default it targets `x86_64-unknown-linux-musl` unless specified with `--target`.

## Deploying your Rust application

With a bit of luck, you should be able to just copy your application binary from `target/x86_64-unknown-linux-musl/release`, and install it directly on any reasonably modern x86_64 Linux machine.  In particular, you should be able make static release binaries using TravisCI and GitHub, or you can copy your Rust application into an [Alpine Linux container][]. See below for details!

## Caching builds

You may be able to speed up build performance by adding the following `-v` commands to the `rust-musl-builder` alias:

```
-v cargo-git:/home/rust/.cargo/git -v cargo-registry:/home/rust/.cargo/registry
```

You will also need to fix the permissions on the mounted volumes:

```sh
rust-musl-builder sudo chown -R rust:rust /home/rust/.cargo/git /home/rust/.cargo/registry
```

## How it works

`rust-musl-builder` uses [musl-libc][], [musl-gcc][], and the new [rustup][] `target` support.  It includes static versions of several libraries:

- The standard `musl-libc` libraries.
- OpenSSL, which is needed by many Rust applications.
- `libpq`, which is needed for applications that use `diesel` with PostgreSQL. Note that this may be broken under Rust 1.21.0 and later (see https://github.com/emk/rust-musl-builder/issues/27).
- `libz`, which is needed by `libpq`.
- SQLite3. See [examples/using-diesel](./examples/using-diesel/).

This library also sets up the environment variables needed to compile popular Rust crates using these libraries.

## Extras

This image also supports the following extra goodies:

- Basic compilation for `armv7` using `musl-libc`. Not all libraries are supported at the moment, however.
- [`mdbook`][mdbook] for building searchable HTML documentation from Markdown files. Build manuals to use alongside your `cargo doc` output!
- [`cargo audit`][audit] to check your Rust project for known security issues.

## Making OpenSSL work

If your application uses OpenSSL, you will also need to take a few extra steps to make sure that it can find OpenSSL's list of trusted certificates, which is stored in different locations on different Linux distributions. You can do this using [`openssl-probe`](https://crates.io/crates/openssl-probe) as follows:

```rust
extern crate openssl_probe;

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

For PostgreSQL, you'll also need to include `openssl` in your `main.rs` (in order to avoid linker errors):

```toml
extern crate openssl;
```

See [this PR](https://github.com/sgrif/pq-sys/pull/18) for a discussion of the issues involved in cross-compiling `diesel` and `diesel_codegen`.

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

```rust
FROM ekidd/rust-musl-builder

# We need to add the source code to the image because `rust-musl-builder`
# assumes a UID of 1000, but TravisCI has switched to 2000.
ADD . ./
RUN sudo chown -R rust:rust .

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

After modifying the image, run `./test-image` to make sure that everything works.xs

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
[audit]: https://github.com/RustSec/cargo-audit
[mdbook]: https://github.com/rust-lang-nursery/mdBook
[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[rustup]: https://www.rustup.rs/
