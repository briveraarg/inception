#!/bin/sh
set -e

# Copia los certificados desde secrets
mkdir -p /etc/nginx/ssl
cp /run/secrets/server.crt /etc/nginx/ssl/server.crt
cp /run/secrets/server.key /etc/nginx/ssl/server.key


# Procesa la plantilla nginx.conf.template con las variables de entorno
envsubst '${HTTPS_PORT} ${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
#envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf


exec nginx -g "daemon off;"

