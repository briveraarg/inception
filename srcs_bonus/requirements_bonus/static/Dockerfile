FROM alpine:3.20

RUN apk add --no-cache nginx

COPY html/ /var/www/html/

RUN chown -R nginx:nginx /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]