#  MIT License, Copyright (c) 2020 Frank Felhoffer
#
#  A very small docker image with cfssl, cfssljson and a few scripts in it
#  to support easy key material generation for projects.

FROM    golang:1.14.2 as builder

# the version of cfssl to build
ARG     cfssl_version=1.4.1

# want to make the binaries static so I can use them
# with alpine or with any other Linux distributions
ENV     LDFLAGS="-s -w -extldflags '-static' -X github.com/cloudflare/cfssl/cli/version.version=${cfssl_version}"

# some other tags to make the binaries truely static
# https://github.com/golang/go/issues/26492
ENV     GOTAGS="osusergo netgo static_build"
#
RUN     set -ex; \
        apt-get update; \
        apt install -y git build-essential; \
        mkdir -p /go/src/github.com/cloudflare; \
        # clone git repo and check out desired version
        git clone https://github.com/cloudflare/cfssl.git /go/src/github.com/cloudflare/cfssl; \
        cd /go/src/github.com/cloudflare/cfssl; \
        git checkout v${cfssl_version}; \
        # compiling binaries
        mkdir bin; \
        go build -ldflags "${LDFLAGS}" -buildmode pie -tags "${GOTAGS}" -o bin/cfssl ./cmd/cfssl; \
        go build -ldflags "${LDFLAGS}" -buildmode pie -tags "${GOTAGS}" -o bin/cfssljson ./cmd/cfssljson


# final container
FROM    alpine:3

# copy over the static binaries from the builder
COPY --from=builder /go/src/github.com/cloudflare/cfssl/bin/cfssl /usr/local/bin/
COPY --from=builder /go/src/github.com/cloudflare/cfssl/bin/cfssljson /usr/local/bin/

ENTRYPOINT ["cfssl"]
CMD ["--help"]
