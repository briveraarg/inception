FROM alpine:3.20

RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client

COPY conf/50-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
