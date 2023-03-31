FROM ubuntu:20.04 as build

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      g++ \
      curl \
      ca-certificates \
      libc6-dev \
      make \
      libssl-dev \
      pkg-config \
      git \
      cmake \
      zlib1g-dev

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain stable --profile minimal -y

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get install -y nodejs

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
COPY ./collector ./collector
COPY ./database ./database
COPY ./intern ./intern
COPY ./site ./site

RUN cd site/frontend && npm ci
RUN cd site/frontend && npm run check
RUN cd site/frontend && npm run build

RUN bash -c 'source $HOME/.cargo/env && cargo build --release -p site'
RUN bash -c 'source $HOME/.cargo/env && cargo build --release --bin postgres-to-sqlite'

FROM ubuntu:20.04 as binary

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    git

COPY --from=build /target/release/postgres-to-sqlite /usr/local/bin/rustc-perf-postgres-to-sqlite
COPY --from=build /target/release/site /usr/local/bin/rustc-perf-site

CMD rustc-perf-site
