FROM alpine:3.20

RUN apk add --no-cache redis

COPY tools/init.sh /usr/local/bin/init.sh
COPY tools/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/init.sh /usr/local/bin/healthcheck.sh

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/init.sh"]
