# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). We do not use Semantic Versioning, because our images are tagged based on Rust releases. However, we try to maintain as much backwards compatibility as possible.

For maximum stablity, use images with tags like `ekidd/rust-musl-builder:1.46.0` or `ekidd/rust-musl-builder:nightly-2020-08-26`. These may occasionally be rebuilt, but only while they're "current", or possibly if they're recent and serious security are discovered in a library.

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
