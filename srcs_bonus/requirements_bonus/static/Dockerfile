FROM alpine:3.20

RUN apk add --no-cache nginx

# Crear directorio http.d (donde Alpine NGINX incluye configuraciones)
RUN mkdir -p /etc/nginx/http.d

# Copiar configuración personalizada de NGINX
COPY nginx.conf /etc/nginx/http.d/default.conf

COPY html/ /var/www/html/

RUN chown -R nginx:nginx /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]