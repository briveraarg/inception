#!/bin/sh

# Leer la contraseña desde el secret
if [ -f "/run/secrets/redis_password" ]; then
	REDIS_PASSWORD=$(cat /run/secrets/redis_password)
	redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD"
else
	# Fallback si no hay secret (solo para desarrollo)
	redis-server --bind 0.0.0.0
fi
