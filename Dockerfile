FROM ghcr.io/actions/actions-runner:2.337.0@sha256:e5496277be5d09bc968b3d64911b74e219ac4a3f2edce956a3ecf9271bea1ef4

ARG TARGETARCH
# renovate: datasource=github-releases depName=node-22-toolcache packageName=actions/node-versions
ARG NODE_22_RELEASE=22.23.2-30508424155
# renovate: datasource=github-releases depName=node-24-toolcache packageName=actions/node-versions
ARG NODE_24_RELEASE=24.20.0-33034074684
# renovate: datasource=github-releases depName=bun packageName=oven-sh/bun
ARG BUN_COMPAT_VERSION=1.4.0
ARG BUN_VERSION=1.4.2

USER root

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN NODE_22_VERSION="${NODE_22_RELEASE%%-*}" \
    && NODE_24_VERSION="${NODE_24_RELEASE%%-*}" \
    && test "${TARGETARCH}" = "amd64" \
    && install -d /opt/hostedtoolcache/node/${NODE_22_VERSION}/x64 \
    && curl --fail --location --retry 3 \
      "https://github.com/actions/node-versions/releases/download/${NODE_22_RELEASE}/node-${NODE_22_VERSION}-linux-x64.tar.gz" \
      | tar --extract --gzip --strip-components=1 \
        --directory=/opt/hostedtoolcache/node/${NODE_22_VERSION}/x64 \
    && touch /opt/hostedtoolcache/node/${NODE_22_VERSION}/x64.complete \
    && install -d /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64 \
    && curl --fail --location --retry 3 \
      "https://github.com/actions/node-versions/releases/download/${NODE_24_RELEASE}/node-${NODE_24_VERSION}-linux-x64.tar.gz" \
      | tar --extract --gzip --strip-components=1 \
        --directory=/opt/hostedtoolcache/node/${NODE_24_VERSION}/x64 \
    && touch /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64.complete

RUN for version in "${BUN_COMPAT_VERSION}" "${BUN_VERSION}"; do \
      curl --fail --location --retry 3 \
        "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip" \
        --output "/tmp/bun-${version}.zip"; \
      unzip -q "/tmp/bun-${version}.zip" -d "/tmp/bun-${version}"; \
      install -D -m 0755 "/tmp/bun-${version}/bun-linux-x64/bun" "/opt/bun/${version}/bin/bun"; \
    done \
    && ln -s /opt/bun/${BUN_VERSION}/bin/bun /usr/local/bin/bun \
    && rm -rf /tmp/bun-*

RUN NODE_24_VERSION="${NODE_24_RELEASE%%-*}" \
    && ln -s /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64/bin/node /usr/local/bin/node \
    && ln -s /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64/bin/npm /usr/local/bin/npm \
    && ln -s /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64/bin/npx /usr/local/bin/npx \
    && ln -s /opt/hostedtoolcache/node/${NODE_24_VERSION}/x64/bin/corepack /usr/local/bin/corepack

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ENV NODE_22_RELEASE=${NODE_22_RELEASE}
ENV NODE_24_RELEASE=${NODE_24_RELEASE}
ENV BUN_COMPAT_INSTALL=/opt/bun/${BUN_COMPAT_VERSION}
ENV BUN_INSTALL=/opt/bun/${BUN_VERSION}
ENV PATH=/opt/bun/${BUN_VERSION}/bin:${PATH}

RUN chown -R runner:runner /opt/hostedtoolcache /opt/bun \
    && node --version \
    && npm --version \
    && bun --version

USER runner
