#!/bin/sh
set -e

# Crea el directorio para el certificado
mkdir -p /etc/nginx/ssl

# Genera el certificado autofirmado si no existe
if [ ! -f "/etc/nginx/ssl/cert.pem" ]; then
    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=brivera.42.fr"
fi

# Arranca NGINX en primer plano (PID 1)
exec nginx -g "daemon off;"
