# `rust-musl-builder`: Docker container for easily building static Rust binaries

[![Docker Image](https://img.shields.io/docker/pulls/platten/rust-musl-builder.svg?maxAge=2592000)](https://hub.docker.com/r/platten/rust-musl-builder/)

- [Source on GitHub](https://github.com/platten/rust-musl-builder)

However, **[`rustls`](rustls) now works well** with most of the Rust ecosystem, including `reqwest`, `tokio` and many others.

- See if you can switch away from OpenSSL, typically by using `features` in `Cargo.toml` to ask your dependencies to use [`rustls`](rustls) instead.
- If you don't need OpenSSL, try [`cross build --target=x86_64-unknown-linux-musl --release`](https://github.com/rust-embedded/cross) to cross-compile your binaries for `libmusl`. This supports many more platforms, with less hassle!

[rustls]: https://github.com/rustls

## What is this?

This image allows you to build static Rust binaries using `openssl`. These images can be distributed as single executable files with no dependencies, and they should work on any modern Linux system.


## Deploying your Rust application

With a bit of luck, you should be able to just copy your application binary from `target/x86_64-unknown-linux-musl/release`, and install it directly on any reasonably modern x86_64 Linux machine.  In particular, you should be able make static release binaries using TravisCI and GitHub, or you can copy your Rust application into an [Alpine Linux container][]. See below for details!


## How it works

`rust-musl-builder` uses [musl-libc][], [musl-gcc][], and the new [rustup][] `target` support.  It includes static versions of the following libraries:

- The standard `musl-libc` libraries.
- OpenSSL, which is needed by many Rust applications.


## Making OpenSSL work

If your application uses OpenSSL, you will also need to take a few extra steps to make sure that it can find OpenSSL's list of trusted certificates, which is stored in different locations on different Linux distributions. You can do this using [`openssl-probe`](https://crates.io/crates/openssl-probe) as follows:

```rust
fn main() {
    openssl_probe::init_ssl_cert_env_vars();
    //... your code
}
```

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
[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[rustup]: https://www.rustup.rs/
