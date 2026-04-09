#!/bin/sh

FTP_PASSWORD="$(cat /run/secrets/ftp_password)"
echo "ftpuser:${FTP_PASSWORD}" | chpasswd

echo "Starting vsftpd..."
vsftpd /etc/vsftpd/vsftpd.conf
echo "vsftpd exited with code $?"