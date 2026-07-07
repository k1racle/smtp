#!/usr/bin/env bash
# Генерация самоподписанного сертификата для доступа к Stalwart по IP сервера.
# Запускайте на сервере, где установлен Nginx.

set -euo pipefail

SERVER_IP="${SERVER_IP:-127.0.0.1}"
SSL_DIR="${SSL_DIR:-/etc/nginx/ssl}"
KEY_FILE="${SSL_DIR}/mail-server.key"
CRT_FILE="${SSL_DIR}/mail-server.crt"

echo "Generating self-signed certificate for IP: ${SERVER_IP}"
echo "Output directory: ${SSL_DIR}"

mkdir -p "${SSL_DIR}"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${KEY_FILE}" \
  -out "${CRT_FILE}" \
  -subj "/CN=${SERVER_IP}" \
  -addext "subjectAltName=IP:${SERVER_IP}"

chmod 600 "${KEY_FILE}"
chmod 644 "${CRT_FILE}"

echo "Done:"
echo "  ${KEY_FILE}"
echo "  ${CRT_FILE}"
echo ""
echo "Reload nginx: sudo systemctl reload nginx"
