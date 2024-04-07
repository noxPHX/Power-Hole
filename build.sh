#!/usr/bin/env bash

# Check the script is run as by a user with docker's rights
if [ "$EUID" -ne 0 ]; then
  if ! id -nGz "$USER" | grep -qzxF docker; then
    echo "Please run with docker's rights (either run as root or add yourself to the docker group)"
    exit 1
  fi
fi

this_script_path=$(dirname "$0")                  # Relative
this_script_path=$(cd "$this_script_path" && pwd) # Absolutized and normalized
if [ -z "$this_script_path" ]; then
  # Error, for some reason, the path is not accessible to the script (e.g. permissions re-evalued after suid)
  exit 1 # Fail
fi

cd "$this_script_path" || exit 1

# Authoritative server's populating script
wget -qO authoritative/init.sql https://raw.githubusercontent.com/PowerDNS/pdns/rel/auth-4.4.x/modules/gpgsqlbackend/schema.pgsql.sql

# Compose does not allow yet BuildKit secrets
export DOCKER_BUILDKIT=1
docker build --secret id=db_password,src=secrets/db_password.txt --secret id=api_key,src=secrets/api_key.txt -t powerhole:authoritative authoritative

# Build the recursor, forwarder and nginx
docker-compose build powerhole_pdns_recursor powerhole_pdns_forwarder powerhole_nginx

# Locally build the PowerDNS-Admin image because the Docker Hub does not provide an image for ARM devices
cd /tmp || exit 1
git clone https://github.com/PowerDNS-Admin/PowerDNS-Admin.git && cd PowerDNS-Admin || exit 1
git checkout v0.4.1
docker build --no-cache -t powerhole:admin -f docker/Dockerfile .
cd "$this_script_path" || exit 1
rm -r /tmp/PowerDNS-Admin

#diff --git a/docker/Dockerfile b/docker/Dockerfile
#index 55ccdfd..3d028fb 100644
#--- a/docker/Dockerfile
#+++ b/docker/Dockerfile
#@@ -8,6 +8,7 @@ ARG BUILD_DEPENDENCIES="build-base \
#     openldap-dev \
#     python3-dev \
#     xmlsec-dev \
#+    freetype-dev libpng-dev jpeg-dev libjpeg-turbo-dev \
#     npm \
#     yarn \
#     cargo"
#@@ -15,7 +16,8 @@ ARG BUILD_DEPENDENCIES="build-base \
# ENV LC_ALL=en_US.UTF-8 \
#     LANG=en_US.UTF-8 \
#     LANGUAGE=en_US.UTF-8 \
#-    FLASK_APP=/build/powerdnsadmin/__init__.py
#+    FLASK_APP=/build/powerdnsadmin/__init__.py \
#+    CARGO_HTTP_CHECK_REVOKE=false
# 
# # Get dependencies
# # py3-pip should not belong to BUILD_DEPENDENCIES. Otherwise, when we remove
#@@ -37,7 +39,7 @@ RUN pip install --upgrade pip && \
# COPY . /build
# 
# # Prepare assets
#-RUN yarn install --pure-lockfile --production && \
#+RUN yarn install --pure-lockfile --production --network-timeout 100000 && \
#     yarn cache clean && \
#     sed -i -r -e "s|'rcssmin',\s?'cssrewrite'|'rcssmin'|g" /build/powerdnsadmin/assets.py && \
#     flask assets build
#@@ -73,7 +75,7 @@ FROM alpine:3.17
# ENV FLASK_APP=/app/powerdnsadmin/__init__.py \
#     USER=pda
# 
#-RUN apk add --no-cache mariadb-connector-c postgresql-client py3-gunicorn py3-pyldap py3-flask py3-psycopg2 xmlsec tzdata libcap && \
#+RUN apk add --no-cache mariadb-connector-c postgresql-client py3-gunicorn py3-pyldap py3-flask py3-psycopg2 xmlsec tzdata libcap freetype-dev libpng-dev jpeg-dev libjpeg-turbo-dev && \
#     addgroup -S ${USER} && \
#     adduser -S -D -G ${USER} ${USER} && \
#     mkdir /data && \
#diff --git a/requirements.txt b/requirements.txt
#index 0db7b16..ffd2d98 100644
#--- a/requirements.txt
#+++ b/requirements.txt
#@@ -9,7 +9,7 @@ Flask-SeaSurf==1.1.1
# Flask-Session==0.4.0
# Flask==2.1.3
# Jinja2==3.1.2
#-PyYAML==5.4
#+PyYAML==5.3.1
# SQLAlchemy==1.3.24
# #alembic==1.9.0
# bcrypt==4.0.1
#@@ -45,4 +45,4 @@ zipp==3.11.0
# rcssmin==1.1.1
# zxcvbn==4.4.28
# psycopg2==2.9.5
#-setuptools==65.5.1 # fixes CVE-2022-40897
#\ No newline at end of file
#+setuptools==65.5.1 # fixes CVE-2022-40897
