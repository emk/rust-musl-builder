# -*- mode: dockerfile -*-
#
# An example Dockerfile showing how to add build new static C libraries using
# musl-gcc.

FROM platten/rust-musl-builder as builder

RUN git clone http://github.com/enarx/enarx.git . && \
    cargo build --release && \
    cargo install --bin enarx --path ./

FROM alpine
COPY --from=builder /root/.cargo/bin/enarx /bin/enarx
