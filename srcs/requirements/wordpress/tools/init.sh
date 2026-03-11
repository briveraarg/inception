#!/bin/sh
set -e

until mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "SELECT 1;" > /dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 2
done

echo "MariaDB is ready!"

if [ ! -f "/var/www/html/wp-config.php" ]; then

    echo "Installing WordPress..."

    php -d memory_limit=256M /usr/local/bin/wp core download \
        --path=/var/www/html \
        --allow-root

    wp config create \
        --path=/var/www/html \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --path=/var/www/html \
        --url=https://${DOMAIN_NAME} \
        --title="Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --skip-email \
        --allow-root

    wp user create \
        ${WP_USER} ${WP_USER_EMAIL} \
        --path=/var/www/html \
        --user_pass=${WP_USER_PASSWORD} \
        --role=author \
        --allow-root

    echo "WordPress installed!"

fi

exec php-fpm83 -F
