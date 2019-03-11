FROM alpine:3.7
MAINTAINER NV <neovortex@gmail.com>

# This is the release of Nomad to pull in.
ENV NOMAD_VERSION=0.8.7

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN set -eux && \
  apk add --no-cache curl gnupg openssl ca-certificates && \
  gpg --keyserver pgp.mit.edu --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  curl -L -o nomad_${NOMAD_VERSION}_linux_amd64.zip ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip && \
  curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS      ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS && \
  curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS.sig  ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig && \
  gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS && \
  grep nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip -d /bin nomad_${NOMAD_VERSION}_linux_amd64.zip && \
  chmod +x /bin/nomad && \
  cd /tmp && \
  rm -rf /tmp/build && \
  apk del gnupg openssl && \
  rm -rf /root/.gnupg && \
  # tiny smoke test to ensure the binary we downloaded runs
  nomad version

RUN mkdir -p /nomad/data && \
    mkdir -p /etc/nomad

EXPOSE 4646 4647 4648 4648/udp

ADD start.sh /usr/local/bin/start.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
