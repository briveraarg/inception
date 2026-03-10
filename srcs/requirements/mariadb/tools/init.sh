#!/bin/sh
set -e

# crear el directorio para socket si no existe
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Solo inicializa si la base de datos no existe aún
if [ ! -d "/var/lib/mysql/mysql" ]; then

    # Inicializa el sistema de datos
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Arranca MariaDB temporalmente para configurarla
    mysqld --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;

-- Elimina usuarios anónimos y base de datos de test
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

-- Crea la base de datos de WordPress
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Crea el usuario de WordPress
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Cambia la contraseña de root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

fi

# Arranca MariaDB en primer plano (PID 1)
exec mysqld --user=mysql
