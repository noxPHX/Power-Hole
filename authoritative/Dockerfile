FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

RUN apt-get -y --no-install-recommends install pdns-server pdns-backend-pgsql && \
    rm -rf /var/lib/apt/lists/*

COPY pdns.conf /etc/powerdns/pdns.d/pdns.conf

ARG LOG_LEVEL

RUN --mount=type=secret,id=db_password --mount=type=secret,id=api_key sed -i "s/secret_pdns_password/$(cat /run/secrets/db_password)/g" /etc/powerdns/pdns.d/pdns.conf && \
    sed -i "s/secret_api_key/$(cat /run/secrets/api_key)/g" /etc/powerdns/pdns.d/pdns.conf && \
    sed -i "s/log_level/${LOG_LEVEL}/g" /etc/powerdns/pdns.d/pdns.conf && \
    mkdir /var/run/pdns && \
    chown -R pdns:pdns /var/run/pdns /etc/powerdns/

USER pdns

ENTRYPOINT [ "pdns_server" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 && curl -s --fail http://127.0.0.1:8081 || exit 1
