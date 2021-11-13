FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

RUN apt-get -y --no-install-recommends install pdns-recursor && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=pdns:pdns recursor.conf /etc/powerdns/recursor.d/recursor.conf

ARG LOG_LEVEL

RUN mkdir /var/run/pdns && \
    sed -i "s/log_level/${LOG_LEVEL}/g" /etc/powerdns/recursor.d/recursor.conf && \
    chown -R pdns:pdns /var/run/pdns

USER pdns

ENTRYPOINT [ "pdns_recursor" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 || exit 1
