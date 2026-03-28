FROM alpine:3.20

RUN apk update && apk add --no-cache \
    nginx \
    openssl \
    gettext

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init.sh"]


