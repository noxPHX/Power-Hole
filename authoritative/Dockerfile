FROM debian:buster-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

RUN echo "deb [arch=amd64] http://repo.powerdns.com/debian buster-auth-master main" > /etc/apt/sources.list.d/pdns.list && \
    curl https://repo.powerdns.com/CBC8B383-pub.asc | apt-key add - && \
    echo "Package: pdns-*" > /etc/apt/preferences.d/pdns && \
    echo "Pin: origin repo.powerdns.com" >> /etc/apt/preferences.d/pdns && \
    echo "Pin-Priority: 600" >> /etc/apt/preferences.d/pdns

RUN apt-get update && \
    apt-get -y --no-install-recommends install pdns-server pdns-backend-pgsql && \
    rm -rf /var/lib/apt/lists/*

COPY pdns.conf /etc/powerdns/pdns.d/pdns.conf

RUN --mount=type=secret,id=db_password --mount=type=secret,id=api_key sed -i "s/secret_pdns_password/$(cat /run/secrets/db_password)/g" /etc/powerdns/pdns.d/pdns.conf && \
    sed -i "s/secret_api_key/$(cat /run/secrets/api_key)/g" /etc/powerdns/pdns.d/pdns.conf

#USER pdns
ENTRYPOINT [ "pdns_server" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 && curl -s --fail http://127.0.0.1:8081 || exit 1
