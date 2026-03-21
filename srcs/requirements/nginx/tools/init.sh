#!/bin/sh
set -e

# Copia los certificados desde secrets
mkdir -p /etc/nginx/ssl
cp /run/secrets/server.crt /etc/nginx/ssl/server.crt
cp /run/secrets/server.key /etc/nginx/ssl/server.key

exec nginx -g "daemon off;"

