#!/bin/bash

set -e

echo "Waiting for MariaDB..."

until mariadb -h"$WORDPRESS_DB_HOST" \
    -u"$MARIA_USER" \
    -p"$MARIA_PASSWORD" \
    "$MARIA_DB" \
    -e "SELECT 1" > /dev/null 2>&1
do
    sleep 2
done

echo "MariaDB is ready."

cd /var/www/html

if [ ! -f wp-config.php ]; then

    echo "Installing WordPress..."

    wp core download --allow-root

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root

    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --allow-root

    wp user create \
        "$WORDPRESS_USER" \
        "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" \
        --allow-root

    chown -R www-data:www-data /var/www/html

    echo "WordPress installation completed."

else

    echo "WordPress already installed."

fi

exec /usr/sbin/php-fpm8.2 -F