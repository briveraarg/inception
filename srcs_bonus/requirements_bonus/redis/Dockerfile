FROM alpine:3.20

RUN apk add --no-cache redis

EXPOSE 6379

ENTRYPOINT ["redis-server", "--bind", "0.0.0.0"]
