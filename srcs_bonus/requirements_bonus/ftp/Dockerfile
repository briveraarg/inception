FROM alpine:3.20

RUN apk add --no-cache vsftpd \
    && adduser -D -h /home/ftpuser -s /sbin/nologin ftpuser \
    && mkdir -p /home/ftpuser/wordpress \
    && chown -R ftpuser:ftpuser /home/ftpuser/wordpress \
    && chown root:root /home/ftpuser \
    && chmod 755 /home/ftpuser

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

# Asegurar que root es dueño del conf
RUN chown root:root /etc/vsftpd/vsftpd.conf && chmod 600 /etc/vsftpd/vsftpd.conf

COPY --chmod=755 tools/entrypoint.sh /entrypoint.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/entrypoint.sh"]