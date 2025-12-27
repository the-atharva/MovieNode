#!/bin/bash
set -eu

#Timzones
TIMEZONE=Asia/Kolkata
USERNAME=movienode

#PW for smtp server
read -p "Enter password for smtp server: " SMTP_PASSWORD
echo "SMTP_PASSWORD='${SMTP_PASSWORD}'" >> /etc/environment

#PW for movidenode db user
read -p "Enter password for movienode DB user: " DB_PASSWORD

export LC_ALL=en_US.UTF-8

#Configure server
add-apt-repository --yes universe

apt update 
apt --yes -o Dpkg::Options::="--force-confnew" upgrade

timedatectl set-timezone ${TIMEZONE}
apt --yes install locales-all

useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"

passwd --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"

rsync --archive --chown=${USERNAME}:${USERNAME} /root/.ssh /home/${USERNAME}

#Configure firewall
ufw allow 22
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

apt --yes install fail2ban

#Migrate tool
curl -L https://github.com/golang-migrate/migrate/releases/download/v4.19.1/migrate.linux-amd64.tar.gz | tar xvz
mv migrate /usr/local/bin/migrate

#Postgres DB
apt --yes install postgresql

sudo -i -u postgres psql -c "CREATE DATABASE movienode"
sudo -i -u postgres psql -d movienode -c "CREATE EXTENSION IF NOT EXISTS citext"
sudo -i -u postgres psql -d movienode -c "CREATE ROLE movienode WITH LOGIN PASSWORD '${DB_PASSWORD}'"
sudo -i -u postgres psql -d movienode -c "GRANT USAGE, CREATE ON SCHEMA public to ${USERNAME}"

echo "MOVIENODE_DB_DSN='postgres://movienode:${DB_PASSWORD}@localhost/movienode'" >> /etc/environment

#Caddy RP
apt --yes install debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
apt update
apt --yes install caddy
 
 echo "Script complete! Rebooting..."
 reboot