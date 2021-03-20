# -*- mode: dockerfile -*-
#
# An example Dockerfile showing how to add new static C libraries using
# musl-gcc.

# Our first FROM statement declares the build environment.
FROM ekidd/rust-musl-builder AS builder

# Add our source code.
ADD --chown=rust:rust . ./

# Build our application.
RUN cargo build

# Now, we need to build our _real_ Docker container, copying in `linking-with-git2`.
FROM debian:stretch-slim
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder \
  /home/rust/src/target/x86_64-unknown-linux-musl/debug/linking-with-git2 \
  /usr/local/bin/
CMD /usr/local/bin/linking-with-git2
