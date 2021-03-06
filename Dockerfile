FROM alpine:3
MAINTAINER NV <neovortex@gmail.com>

# This is the release of Nomad to pull in.
ENV NOMAD_VERSION=1.1.0

ENV GLIBC_VERSION=2.33-r0

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN set -eux && \
  apk add --no-cache curl gnupg dumb-init openssl ca-certificates && \
  for keyserver in $(shuf -e \
    ha.pool.sks-keyservers.net \
    hkp://p80.pool.sks-keyservers.net:80 \
    keyserver.ubuntu.com \
    hkp://keyserver.ubuntu.com:80); \
    do gpg --keyserver $keyserver --recv-keys C874011F0AB405110D02105534365D9472D7468F && break || true ; \
  done && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  curl -sL -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  curl -sL -o glibc-${GLIBC_VERSION}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
  apk add glibc-${GLIBC_VERSION}.apk && \
  curl -sL -o nomad_${NOMAD_VERSION}_linux_amd64.zip ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip && \
  curl -sL -o nomad_${NOMAD_VERSION}_SHA256SUMS      ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS && \
  curl -sL -o nomad_${NOMAD_VERSION}_SHA256SUMS.sig  ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig && \
  gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS && \
  grep nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip -d /bin nomad_${NOMAD_VERSION}_linux_amd64.zip && \
  chmod +x /bin/nomad && \
  cd /tmp && \
  rm -rf /tmp/build && \
  apk del curl gnupg && \
  sleep 1 && rm -rf /root/.gnupg && \
  # tiny smoke test to ensure the binary we downloaded runs
  nomad version

RUN mkdir -p /nomad/data && \
    mkdir -p /etc/nomad

EXPOSE 4646 4647 4648 4648/udp

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["agent"]
