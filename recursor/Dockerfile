FROM debian:buster-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    gnupg \
    dnsutils

RUN echo "deb [arch=$(dpkg --print-architecture)] http://repo.powerdns.com/debian buster-rec-45 main" > /etc/apt/sources.list.d/pdns.list && \
    curl -s https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add -

RUN apt-get update && \
    apt-get -y --no-install-recommends install pdns-recursor && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=pdns:pdns recursor.conf /etc/powerdns/recursor.d/recursor.conf

RUN mkdir /var/run/pdns && \
    chown -R pdns:pdns /var/run/pdns

USER pdns

ENTRYPOINT [ "pdns_recursor" ]

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 || exit 1
