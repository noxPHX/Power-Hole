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
    apt-get -y --no-install-recommends install pdns-recursor && \
    rm -rf /var/lib/apt/lists/*

COPY recursor.conf /etc/powerdns/recursor.d/recursor.conf
COPY zones /etc/powerdns/zones

ARG UPSTREAM

RUN sed -i "s/UPSTREAM/${UPSTREAM}/g" /etc/powerdns/recursor.d/recursor.conf && \
    mkdir /var/run/pdns && \
    chown -R pdns:pdns /var/run/pdns /etc/powerdns/

USER pdns

ENTRYPOINT [ "pdns_recursor" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 || exit 1
