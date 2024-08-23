#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo "Ange domännamn som argument."
  exit 1
fi

SSL_DIR="/etc/ssl"
CERT_DIR="$SSL_DIR/certs"
KEY_DIR="$SSL_DIR/private"
CERT_FILE="$CERT_DIR/$DOMAIN.crt"
KEY_FILE="$KEY_DIR/$DOMAIN.key"
CONF_DIR="/var/www/$DOMAIN/conf/nginx"
SSL_CONF="$CONF_DIR/ssl.conf"

# Skapa kataloger om de inte redan finns
sudo mkdir -p "$CERT_DIR" "$KEY_DIR" "$CONF_DIR"

# Kontrollera om certifikatet redan finns
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
  echo "Certifikat och nyckel för $DOMAIN finns redan."
else
  # Skapa ett självsignerat certifikat
  echo "Skapar självsignerat SSL-certifikat för $DOMAIN."
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=SE/ST=Stockholm/L=Stockholm/O=Example/CN=$DOMAIN"
  echo "Självsignerat SSL-certifikat skapades för $DOMAIN."
fi

# Skapa SSL-konfigurationsfilen
if [ ! -f "$SSL_CONF" ]; then
  echo "Skapar SSL-konfigurationsfil $SSL_CONF."
  sudo bash -c "cat > $SSL_CONF << EOF
    ssl_stapling off;
    ssl_stapling_verify off;
	
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_FILE;
    ssl_certificate_key $KEY_FILE;

    # Lägg till eventuella andra SSL- eller serverinställningar här

EOF"
else
  echo "SSL-konfigurationsfilen $SSL_CONF finns redan."
fi

# Uppdatera huvudkonfigurationen för Nginx att inkludera SSL-konfigurationsfilen
MAIN_CONF="/etc/nginx/sites-available/$DOMAIN"

if [ ! -f "$MAIN_CONF" ]; then
  echo "Nginx-konfiguration för $DOMAIN hittades inte!"
  exit 1
fi

# Kontrollera om ssl.conf redan är inkluderad
#if grep -q "include $CONF_DIR/ssl.conf;" "$MAIN_CONF"; then
#  echo "SSL-konfigurationsfilen är redan inkluderad i $MAIN_CONF"
#else
#  echo "Lägger till inkludering av SSL-konfigurationsfil i $MAIN_CONF"
#  sudo bash -c "sed -i '/server {/a \    include $CONF_DIR/ssl.conf;' $MAIN_CONF"
#fi

# Testa och ladda om Nginx
sudo nginx -t && sudo systemctl reload nginx

echo "SSL-konfiguration tillagd och Nginx har laddats om."
