#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    service mariadb start

    until mariadb-admin ping --silent; do
        sleep 1
    done

    echo "Creating database..."
    mariadb -u root -e "CREATE DATABASE IF NOT EXISTS \`${MARIA_DB}\`;"

    echo "Creating user..."
    mariadb -u root -e "CREATE USER IF NOT EXISTS '${MARIA_USER}'@'%' IDENTIFIED BY '${MARIA_PASSWORD}';"

    echo "Granting privileges..."
    mariadb -u root -e "GRANT ALL PRIVILEGES ON \`${MARIA_DB}\`.* TO '${MARIA_USER}'@'%';"

    echo "Setting root password..."
    mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIA_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

    echo "Shutting down mariadb..."
    mariadb-admin -u root -p"${MARIA_ROOT_PASSWORD}" shutdown

    echo "MariaDB initialization completed."
else
    echo "MariaDB already initialized."
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0