FROM rust:1.40-stretch as builder

ENV USER root
ENV CI_PROJECT_NAME docker

RUN apt-get update && apt-get install -y git cmake pkg-config libssl-dev git clang libclang-dev

RUN rustup default nightly && rustup target add wasm32-unknown-unknown

COPY . .

RUN CI_PROJECT_NAME=docker sh scripts/init.sh

RUN cargo build --release

FROM debian:stretch-slim

# metadata
ARG VCS_REF
ARG BUILD_DATE

LABEL io.parity.image.authors="dev@mvs.org" \
	io.parity.image.vendor="Viewfin" \
	io.parity.image.title="mvs-org/metaverse" \
	io.parity.image.description="Metaverse: The new reality" \
	io.parity.image.source="https://github.com/mvs-org/Hyperspace/blob/${VCS_REF}/scripts/docker/Dockerfile" \
	io.parity.image.revision="${VCS_REF}" \
	io.parity.image.created="${BUILD_DATE}" \
	io.parity.image.documentation="https://learn.mvs.org"

# show backtraces
ENV RUST_BACKTRACE 1

# install tools and dependencies
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
		libssl1.1 \
		ca-certificates \
		curl && \
# apt cleanup
	apt-get autoremove -y && \
	apt-get clean && \
	find /var/lib/apt/lists/ -type f -not -name lock -delete; \
# add user
	useradd -m -u 1000 -U -s /bin/sh -d /metaverse mvs

# add binary to docker image
COPY --from=builder /Hyperspace/target/release/hyperspace /usr/local/bin/metaverse
COPY --from=builder /Hyperspace/hyperspace.json ./mainnet
COPY --from=builder /Hyperspace/hyperspace.json .
COPY --from=builder /Hyperspace/testnet.json ./testnet
COPY --from=builder /Hyperspace/testnet.json .

USER mvs

# check if executable works in this container
RUN /usr/local/bin/metaverse --version 

# 30333 p2p
# 9933 http rpc
# 9944 ws rpc
# 9615 prometheus
EXPOSE 30333 9933 9944 9615
VOLUME ["/metaverse"]

ENTRYPOINT ["/usr/local/bin/metaverse", "--unsafe-rpc-external", "--unsafe-ws-external"]
