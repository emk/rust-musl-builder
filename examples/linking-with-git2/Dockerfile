# -*- mode: dockerfile -*-
#
# An example Dockerfile showing how to add new static C libraries using
# musl-gcc.

# Our first FROM statement declares the build environment.
FROM passfort/rust-musl-builder AS builder

# Add our source code.
ADD --chown=rust:rust . ./

# Build our application.
RUN cargo build
