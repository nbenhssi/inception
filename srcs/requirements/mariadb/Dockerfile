FROM debian:bookworm
RUN apt update && \
    apt install -y mariadb-server && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/lib/mysql/*
RUN sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
    /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/mariadb.sh /usr/local/bin/mariadb.sh
RUN chmod +x /usr/local/bin/mariadb.sh
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld
EXPOSE 3306
ENTRYPOINT ["mariadb.sh"]