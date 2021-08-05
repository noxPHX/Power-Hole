FROM debian:buster-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

RUN echo "deb [arch=$(dpkg --print-architecture)] http://repo.powerdns.com/debian buster-auth-45 main" > /etc/apt/sources.list.d/pdns.list && \
    curl -s https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add -

RUN apt-get update && \
    apt-get -y --no-install-recommends install pdns-server pdns-backend-pgsql && \
    rm -rf /var/lib/apt/lists/*

COPY pdns.conf /etc/powerdns/pdns.d/pdns.conf

RUN --mount=type=secret,id=db_password --mount=type=secret,id=api_key sed -i "s/secret_pdns_password/$(cat /run/secrets/db_password)/g" /etc/powerdns/pdns.d/pdns.conf && \
    sed -i "s/secret_api_key/$(cat /run/secrets/api_key)/g" /etc/powerdns/pdns.d/pdns.conf && \
    mkdir /var/run/pdns && \
    chown -R pdns:pdns /var/run/pdns /etc/powerdns/

USER pdns

ENTRYPOINT [ "pdns_server" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 && curl -s --fail http://127.0.0.1:8081 || exit 1
