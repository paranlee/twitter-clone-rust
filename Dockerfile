# build stage
FROM rust:latest as cargo-build

RUN apt-get update && apt-get install libpq-dev musl-tools -y
RUN rustup toolchain install nightly && rustup default nightly

WORKDIR /usr/src/app

COPY . .

RUN RUSTFLAGS="-Z instrument-mcount -C passes=ee-instrument<post-inline>" cargo build

# final stage
FROM debian:latest

# ---- for uftrace
ARG test
RUN apt-get update \
    && apt-get install -y --no-install-recommends git gcc make ca-certificates
RUN mkdir -p /usr/src
RUN git clone https://github.com/namhyung/uftrace /usr/src/uftrace
RUN if [ "$test" = "yes" ] ; then \
        cd /usr/src/uftrace \
        && ./misc/install-deps.sh -y \
        && ./configure && make ASAN=1 && make ASAN=1 unittest; \
    else \
        cd /usr/src/uftrace && ./misc/install-deps.sh -y && ./configure && make && make install; \
    fi
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# ---- for uftrace

# RUN apk add postgresql-dev

RUN addgroup -gid 1000 app
RUN useradd -s /bin/sh -u 1000 -g app app

WORKDIR /home/app/bin/

COPY --from=cargo-build /usr/src/app/target/debug/twitter-clone-rust .

RUN chown app:app /home/app/

USER app

# ---- uftrace default port
EXPOSE 8090

EXPOSE 9090

CMD /usr/src/uftrace/uftrace -d /home/app/$UFTRACE_DATA --libmcount-path=/usr/src/uftrace record --host $UFTRACE_RECV ./twitter-clone-rust
