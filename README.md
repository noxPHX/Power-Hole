# Power-Hole

Power-Hole is a simple Docker Compose stack featuring [PowerDNS](https://github.com/PowerDNS/pdns), [PowerDNS-Admin](https://github.com/ngoduykhanh/PowerDNS-Admin) and [Pi-hole](https://github.com/pi-hole/pi-hole) for a quick & easy DNS setup.  

*This project is intended to meet my personal requirements and thus fulfill a very specific need (see more below).*  

## Introduction 🖋️
[PowerDNS](https://github.com/PowerDNS/pdns) is a suite of various pieces of software which provide an authoritative and a recursive DNS server as well as a load balancer.  
[PowerDNS-Admin](https://github.com/ngoduykhanh/PowerDNS-Admin) is a web interface to make simple the management of PowerDNS thanks to the REST API the latter provides.  
Finally [Pi-hole](https://github.com/pi-hole/pi-hole) is a [DNS sinkhole](https://en.wikipedia.org/wiki/DNS_sinkhole) which primary goal is to provide network-wide ad blocking.  

The aim of this project is to supply an easy way to deploy and manage a stack of DNS services featuring:
+ 👮 Your own DNS zones, with the authoritative server
+ 🚀 Fast speeds, with local DNS caching
+ 🛡️ Secure network, blocking unwanted content
+ 🚫 Privacy, with your own recursive server
+ 🔒 Secure access, with HTTPS and authentication
+ ☁️ Lightweight, the stack can run on a Raspberry Pi

## Table of contents 📋
See below the top level parts of this README:

+ [Requirements](#requirements-)
+ [The Stack](#the-stack-)
+ [Getting Started](#getting-started-%EF%B8%8F)
+ [Contributing](#contributing-)
+ [Licence](#licence-)

## Requirements 🧰
Only [Docker](https://docs.docker.com/get-docker/) and [Compose](https://docs.docker.com/compose/) are required by Power-Hole to deploy the stack, the following versions are the minimal requirements:

| Tool          | Version |
|:-------------:|:-------:|
| Docker        | 20      |
| Compose       | 1.29    |

*I will not detail how to set up this project without Docker, but understanding the stack below you might be able to install and configure each component separately.*

## The Stack 🐳

The `docker-compose.yml` file defines **8** services:
+ **The authoritative DNS server** and its **database**
+ **The admin web interface** and its **database**
+ **The recursive server**, for domain resolution
+ **Pi-hole**, the DNS sinkhole and the **server to forward its requests**
+ **Nginx**, the reverse proxy, to handle SSL

In a nutshell, to resolve a domain, **Pi-hole** receive the DNS request and decide whether to block it or not, if the domain is authorized the request is passed to the **forwarder**.  
The **forwarder** will then pass the request to the **authoritative server**, if the latter does not manage the domain, the request is sent to the **recursive server** to be resolved.

## Getting Started 🛠️
Fetch the code from the repository and enter the folder.
```bash
git clone https://github.com/noxPHX/Power-Hole.git && cd Power-Hole
```

### Secrets
To properly work, Power-Hole needs to have some secrets defined:
+ **db_password.txt**, the PowerDNS authoritative server database password
+ **admin_db_password.txt**, the PowerDNS-Admin database password
+ **db_uri.txt** the PowerDNS-Admin link to the database
+ **api_key.txt**, the PowerDNS authoritative server REST API key
+ **pdns_admin_secret_key.txt**, the PowerDNS-Admin internal secret key

⚠️ Be sure to set the same string for the **admin_db_password.txt** and within the **db_uri.txt** ⚠️  

Here is some inspiration to help you randomly create these secrets, feel free to set them as you please.
```bash
cd secrets
date +%s | sha256sum | base64 | head -c 32 > db_password.txt
openssl rand -base64 32 > admin_db_password.txt
echo "postgresql://powerhole_admin:$(cat admin_db_password.txt)@powerhole_pdns_admin_db/powerhole_admin" > db_uri.txt
dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 | tr -d / > api_key.txt
cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 > pdns_admin_secret_key.txt
```

### SSL
The stack comes with a nginx container which needs a certificate and its private key as well as Diffie-Hellman parameters.  

If needed, you can quickly generate a self-signed certificate as shown below:
```bash
openssl req -x509 -newkey rsa:4096 -nodes -keyout ssl/privkey.pem -out ssl/fullchain.pem -days 365 -subj '/CN=localhost' -addext "subjectAltName=DNS:pdns.local.intra,DNS:pihole.local.intra,IP:127.0.0.1,IP:0.0.0.0"
```

Regarding the D-H parameters you can generate them as follows:
```bash
openssl dhparam -out ssl/dhparams.pem 4096
```
*Depending on your machine, you might have time to grab a coffee* ☕

Finally, apply correct ownership (*www-data has id 33*)
```bash
chown -R $USER:33 ssl/
chmod 640 ssl/privkey.pem
```

### Configuration
The only thing you might want to change are the domain names for the admin interface and Pi-hole.  
You can change them in the `docker-compose.yml` file under the `powerhole_nginx` service as build arguments *(l. 184 - 185)*.  

If you want to fine tune even more the different services, you can have a look at their respective documentation:
+ [PowerDNS Authoritative settings page](https://doc.powerdns.com/authoritative/settings.html)
+ [PowerDNS Recursor settings page](https://doc.powerdns.com/recursor/settings.html)
+ [PowerDNS-Admin GitHub](https://github.com/ngoduykhanh/PowerDNS-Admin)
+ [Pi-hole GitHub](https://github.com/pi-hole/docker-pi-hole)
+ [Postgres environment variables](https://github.com/docker-library/docs/tree/master/postgres#how-to-extend-this-image)

### Run!

When you are ready, these commands will suffice to build the images and run the services.  

⚠️ **You must ensure that no other service is running on port 53 (eg systemd-resolved) otherwise you can change the port to bind.** ⚠️

```bash
./build.sh
docker-compose up -d
```
The `docker-compose build` command can not be used here because I need to use Docker's build time secrets which are currently not supported by Compose.  
Also, to support ARM devices (my personal setup runs on a Raspberry Pi 4) the [PowerDNS-Admin image](https://hub.docker.com/r/ngoduykhanh/powerdns-admin) must be built locally, which can by the way take quite some times.  
For these reasons, a convenient script replace the build command here.

### Usage
You can access PowerDNS-Admin at `https://localhost` as it's the default server, from there you can create the DNS entry (*default is pihole.local.intra*) to access Pi-hole.

The first time you access it, you will be asked for the `PDNS API URL`, here you can specify `http://powerhole_pdns_authoritative:8081`.  
The `PDNS VERSION` parameter depends on the version installed by the package manager but at the time it is `4.4.2`.  
The `PDNS API KEY` should be the same as the one generated earlier.  

Finally, change the DNS server of your devices to the host and port on which you deployed the stack.  
Depending on your ISP, you might even be able to change it on your router's settings directly.  


## Contributing 🤝
This repository is to fulfill my personal's needs and major changes from pull requests might not be welcome.  
However, if you ever find an issue please feel free to report it and I will be glad to solve it.  

## Licence 📃
[GPL-3.0](https://github.com/noxPHX/Power-Hole/blob/main/LICENSE)
