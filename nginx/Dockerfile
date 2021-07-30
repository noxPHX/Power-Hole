FROM debian:buster-slim

RUN apt-get update && \
    apt-get -y install \
    curl \
    nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /etc/nginx

COPY nginx.conf .
COPY proxy_admin proxy_pihole sites-available/

RUN touch /tmp/nginx.pid && \
    chown -R www-data:www-data /var/log/nginx && \
    chown -R www-data:www-data /tmp/nginx.pid && \
    chown -R www-data:www-data /var/lib/nginx && \
    chown -R www-data:www-data /srv && \
    chown -R www-data:www-data . && \
    cd sites-enabled && \
    rm -r default && \
    ln -s ../sites-available/proxy_admin && \
    ln -s ../sites-available/proxy_pihole && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

ARG ADMIN_HOSTNAME
ARG PIHOLE_HOSTNAME

RUN sed -i "s/pdns.local.intra/${ADMIN_HOSTNAME}/g" sites-available/proxy_admin && \
    sed -i "s/pihole.local.intra/${PIHOLE_HOSTNAME}/g" sites-available/proxy_pihole

STOPSIGNAL SIGTERM

USER www-data

CMD [ "nginx", "-g", "daemon off;" ]

HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD curl -sfk https://localhost:44380/health/ || exit 1
