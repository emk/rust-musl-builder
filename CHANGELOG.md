# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). We do not use Semantic Versioning, because our images are tagged based on Rust releases. However, we try to maintain as much backwards compatibility as possible.

For maximum stablity, use images with tags like `ekidd/rust-musl-builder:1.46.0` or `ekidd/rust-musl-builder:nightly-2020-08-26`. These may occasionally be rebuilt, but only while they're "current", or possibly if they're recent and serious security issues are discovered in a library.

## [Unreleased]

### Changed

- Updated base image to Ubuntu 20.04. Major thanks to @asaaki for figuring out why the check for successful static linking was returning false negatives.

## 2021-12-23

### Added

- Set up weekly cron builds every Thursday, a few hours after Rust releases often happen. This should keep `stable` and `beta` more-or-less up-to-date. (Tagged releases like `1.57.0` will still need to be made manually.)
- Retroactively built missing stable releases. We have these going way back, so we might as well add the rest.
- Added a note explaining who can switch to `cross` and how to do it.

### Changed

- **Moved release builds from Docker Hub to GitHub!** This allows us to once again start building images without paying Docker Hub for slow, frustrating builders.
- Moved PR tests from Travis CI to GitHub.
- Updated `examples/` to use newer dependencies.
- Updated to OpenSSL 1.1.1m.
- Updated to mdbook 0.4.14.
- Updated to mbbook-graphviz 0.1.3 (now using upstream binaries).
- Updated to cargo-about 0.4.4.
- Updated to cargo-audit 0.16.0 (now using upstream binaries).
- Updated to PostgreSQL 11.14. Still no PostgreSQL 12 unless someone wants to look into diesel and static linking.

## 2021-02-13

### Changed

- mdbook: Updated to 0.4.6.
- Postgres: Updated to 11.11.

## 2021-01-07

### Fixed

- SECURITY: Update `mdbook` to 0.4.5 to fix [CVE-2020-26297](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-26297), as [described on the Rust blog](https://blog.rust-lang.org/2021/01/04/mdbook-security-advisory.html). Thank you to Kyle McCarthy. This potentially affects people who use the bundled `mdbook` to build and publish their documentation.

## 2021-01-04

This release contains a number of major changes, including dropping our ancient and incomplete ARM support and supporting building as `root` as a first step towards better supporting GitHub Actions.

### Changed

- You'll need to use `USER root` and `env RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo rustup $ARGS` to install any new Rust components using `rustup`.
- `rustup`, `cargo`, and associated tools are all installed in `/opt/rust`, so that they should be available to the users `rust`, `root`, and any other users that get added.
- Some other minor supporting tools like `git-credential-ghtoken` should now be available as `root`, as well.
- We have updated our dependencies to the newest versions:
  - OpenSSL 1.1.1i (contains security fixes)
  - `mdbook` 0.4.4
  - `cargo about` 0.2.3
  - `cargo deny` 0.8.5 (may have breaking changes)
- Our example programs now use newer versions of their Rust dependencies.

### Removed

- ARM support has been removed, because it needs to be split into a separate base image. This would also allow us to build OpenSSL, etc., for ARM targets.
- The `rust-docs` component is no longer installed by default.

## 2020-09-04

### Added

- Added `examples/using-sqlx`.

### Changed

- Our OpenSSL configuration now uses environment variables prefixed with `X86_64_UNKNOWN_LINUX_MUSL_`. See [sfackler/rust-openssl#1337](https://github.com/sfackler/rust-openssl/issues/1337) and [launchbadge/sqlx#670](https://github.com/launchbadge/sqlx/issues/670) for background. This allows us to support static builds of `sqlx`, but it may break very old versions of `openssl-sys` (which were probably already broken when OpenSSL 1.0 reached its end-of-life).

## 2020-08-27

### Updated

- Update to `cargo deny` 0.7.3.
- Update to PostgreSQL 11.9.

## 2020-07-16

### Updated

- Update to `mdbook` version 0.4.1.
- Update to `cargo deny` 0.7.0.

## 2020-06-05

### Changed

- Previously, `stable` included OpenSSL 1.0.2, and `stable-openssl11` included OpenSSL 1.1.1. However, OpenSSL 1.0.2 is **no longer receiving security fixes,** so the new tagging system will be:
  - `stable`: OpenSSL 1.1.1 and the latest stable Rust.
  - **DEPRECATED** `stable-openssl11`: OpenSSL 1.1 and Rust 1.42.0. This will no longer be updated. Use `stable` instead.
  - **DEPRECATED** `1.42.0-openssl10` and `nightly-2020-03-12-openssl10`: OpenSSL 1.0.2. These will not be updated to newer Rust. You will still be able to build newer OpenSSL 1.0.2 images manually.

  I hate to break compatibility with projects that require OpenSSL 1.0.2, but since it will receive no future security updates, I no longer feel comfortable supplying pre-built images.

### Updated

- Update to `cargo deny` 0.6.7.
- Update to PostgreSQL 11.8.
