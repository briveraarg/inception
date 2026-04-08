#!/bin/sh

# Leer la contraseña desde el secret y hacer healthcheck
if [ -f "/run/secrets/redis_password" ]; then
	REDIS_PASSWORD=$(cat /run/secrets/redis_password)
	redis-cli -a "$REDIS_PASSWORD" --no-auth-warning ping
else
	redis-cli ping
fi
