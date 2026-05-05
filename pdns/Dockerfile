FROM debian:bookworm-slim AS base

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

FROM base AS authoritative

RUN apt-get -y --no-install-recommends install pdns-server pdns-backend-pgsql && \
    rm -rf /var/lib/apt/lists/*

COPY pdns.conf /etc/powerdns/pdns.d/pdns.conf

#ARG LOG_LEVEL

RUN --mount=type=secret,id=db_password --mount=type=secret,id=api_key sed -i "s/secret_pdns_password/$(cat /run/secrets/db_password)/g" /etc/powerdns/pdns.d/pdns.conf && \
    sed -i "s/secret_api_key/$(cat /run/secrets/api_key)/g" /etc/powerdns/pdns.d/pdns.conf && \
    mkdir /var/run/pdns && \
    chown -R pdns:pdns /var/run/pdns /etc/powerdns/

USER pdns

ENTRYPOINT [ "pdns_server" ]

HEALTHCHECK --start-period=10s --start-interval=2s CMD dig +short +norecurse +retry=0 @127.0.0.1 && curl -s --fail http://127.0.0.1:8081 || exit 1

FROM base AS recursor

RUN apt-get -y --no-install-recommends install pdns-recursor && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=pdns:pdns recursor.conf /etc/powerdns/recursor.d/recursor.conf

ARG LOG_LEVEL

RUN mkdir /var/run/pdns && \
    sed -i "s/log_level/${LOG_LEVEL}/g" /etc/powerdns/recursor.d/recursor.conf && \
    chown -R pdns:pdns /var/run/pdns

USER pdns

ENTRYPOINT [ "pdns_recursor" ]

HEALTHCHECK --start-period=10s --start-interval=2s CMD dig +short +norecurse +retry=0 @127.0.0.1 || exit 1

FROM recursor AS forwarder

COPY --chown=pdns:pdns forwarder.conf /etc/powerdns/recursor.d/forwarder.conf
