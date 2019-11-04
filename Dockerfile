FROM alpine:3.10
MAINTAINER NV <neovortex@gmail.com>

# This is the release of Nomad to pull in.
ENV NOMAD_VERSION=0.10.1

ENV GLIBC_VERSION=2.29-r0

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN set -eux && \
  apk add --no-cache curl gnupg dumb-init openssl ca-certificates && \
  for keyserver in $(shuf -e \
    ha.pool.sks-keyservers.net \
    hkp://p80.pool.sks-keyservers.net:80 \
    keyserver.ubuntu.com \
    hkp://keyserver.ubuntu.com:80); \
    do gpg --keyserver $keyserver --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && break || true ; \
  done && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  curl -L -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  curl -L -o glibc-${GLIBC_VERSION}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
  apk add glibc-${GLIBC_VERSION}.apk && \
  curl -L -o nomad_${NOMAD_VERSION}_linux_amd64.zip ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip && \
  curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS      ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS && \
  curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS.sig  ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig && \
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
