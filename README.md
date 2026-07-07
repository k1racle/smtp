# Stalwart Mail Server — деплой через Portainer

Готовый репозиторий для развертывания почтового сервера [Stalwart](https://stalw.art/) через Docker Compose / Portainer Stack.

## Что внутри

- `docker-compose.yml` — стек Stalwart Mail Server.
- `.env.example` — пример переменных окружения.
- `nginx/` — пример конфигурации **вашего отдельного Nginx** + скрипт генерации самоподписанного сертификата.

## Особенности

- Почтовые службы (SMTP/IMAP/POP3/Sieve) слушают на IP сервера напрямую.
- Веб-админка доступна через ваш Nginx по HTTPS на IP сервера (самоподписанный сертификат).
- Внутри веб-админки вы создаете **любое количество доменов** и почтовых ящиков.
- Nginx не входит в стек — он у вас уже есть отдельно.

## Требования

- Сервер с Linux + Docker + Portainer.
- Публичный статический IP.
- Для нормальной доставки почты желательно:
  - настроить PTR/rDNS на тот hostname, который вы укажете в `STALWART_HOSTNAME`;
  - открыть порты 25, 465/587, 993 (143, 110, 995, 4190 — по желанию);
  - в DNS каждого домена прописать MX, SPF, DKIM, DMARC (Stalwart выдаст готовую зону).

## Подготовка

1. Скопируйте `.env.example` в `.env` (или задайте переменные прямо в Portainer при создании Stack):

   ```bash
   cp .env.example .env
   ```

2. Отредактируйте `.env`:

   ```env
   SERVER_IP=203.0.113.10
   STALWART_HOSTNAME=mail.example.com
   STALWART_RECOVERY_ADMIN=admin:MySuperSecretPass
   STALWART_PUBLIC_URL=https://203.0.113.10/
   ADMIN_BIND_IP=127.0.0.1
   ADMIN_PORT=18080
   TZ=Europe/Moscow
   ```

   - `STALWART_HOSTNAME` — домен, который резолвится на IP сервера. Используется в SMTP-приветствии и для TLS/ACME.
   - `STALWART_PUBLIC_URL` — публичный URL для JMAP/OAuth/редиректов. Если Nginx раздает HTTPS по IP — укажите `https://<SERVER_IP>/`.
   - `ADMIN_BIND_IP=127.0.0.1` означает, что веб-админка доступна только локально и проксируется через Nginx. Если Nginx на другом хосте — поменяйте на `0.0.0.0` или конкретный IP.
   - `ADMIN_PORT=18080` — внешний порт веб-админки. Если на сервере уже занят 8080, используйте 18080 или любой другой свободный порт.

## Деплой в Portainer

1. В Portainer перейдите в **Stacks** → **Add stack**.
2. Выберите **Repository**.
3. Укажите URL этого репозитория.
4. Compose path: `docker-compose.yml`.
5. В разделе **Environment variables** вставьте содержимое `.env` (или задайте переменные вручную).
6. Нажмите **Deploy the stack**.

После запуска контейнер будет в bootstrap-режиме: откроется порт 8080 и будет доступен wizard первоначальной настройки.

## Настройка Nginx

На вашем отдельном сервере с Nginx:

1. Сгенерируйте сертификат:

   ```bash
   sudo SERVER_IP=203.0.113.10 ADMIN_PORT=18080 bash nginx/generate-ssl.sh
   ```

2. Скопируйте конфиг:

   ```bash
   sudo cp nginx/mail-server.conf /etc/nginx/sites-available/mail-server
   sudo ln -s /etc/nginx/sites-available/mail-server /etc/nginx/sites-enabled/mail-server
   sudo nginx -t
   sudo systemctl reload nginx
   ```

   Если Nginx находится на другом хосте, в `proxy_pass` укажите IP/порт сервера Stalwart и откройте соответствующий `ADMIN_PORT` для этого IP.

## Первый запуск и настройка Stalwart

1. Откройте в браузере:

   ```
   https://<SERVER_IP>/admin
   ```

   Браузер предупредит о самоподписанном сертификате — это нормально.

2. Войдите с учетными данными из `STALWART_RECOVERY_ADMIN` (по умолчанию `admin:ChangeMeStrongPassword123`).
3. Пройдите setup wizard:
   - **Server hostname**: `mail.example.com` (или ваш домен).
   - **Default email domain**: ваш основной домен.
   - **Automatically obtain TLS certificate**: отключите, если используете Nginx с самоподписанным сертификатом. Для боевой почты лучше получить валидный сертификат (через Stalwart ACME или загрузить свой).
   - **Storage**, **Directory**, **Logging** — оставьте внутренние значения по умолчанию.
   - **DNS management**: выберите Manual.
4. На финальном экране wizard запишите email и пароль постоянного администратора.
5. **Перезапустите стек** в Portainer, чтобы применилась конфигурация.
6. Снова откройте `https://<SERVER_IP>/admin` и войдите уже постоянным администратором.

## Создание доменов и ящиков

В веб-админке:

- **Management → Domains → Create** — добавьте все свои домены.
- Для каждого домена откройте меню **View DNS Zone file** и скопируйте записи (MX, SPF, DKIM, DMARC, MTA-STS) в панель управления DNS вашего регистратора/хостера.
- **Management → Accounts → Create** — создавайте почтовые ящики в нужных доменах.

## Подключение почтовых клиентов

Пример настроек для ящика `user@example.com`:

- **IMAP**: `mail.example.com`, порт 993, SSL/TLS.
- **SMTP**: `mail.example.com`, порт 587, STARTTLS.
- **POP3**: `mail.example.com`, порт 995, SSL/TLS (если нужен).

> Важно: если используется самоподписанный сертификат, клиенты будут предупреждать о нем. Для продакшена настройте валидный сертификат.

## Безопасность и продакшен

- Сразу смените recovery-пароль (`STALWART_RECOVERY_ADMIN`) после первого входа.
- Отключите HTTP-порт 8080 на внешнем интерфейсе, когда настроите HTTPS через Nginx (`ADMIN_BIND_IP=127.0.0.1`).
- Для отправки почты в крупные почтовые сервисы настройте:
  - PTR-запись (rDNS) для IP сервера на `STALWART_HOSTNAME`;
  - SPF, DKIM, DMARC для каждого домена;
  - валидный TLS-сертификат для `STALWART_HOSTNAME`.

## Обновление

Поменяйте тег образа в `.env` (например, на новый `v0.16.x`) и нажмите **Pull and redeploy** в Portainer, либо локально:

```bash
docker compose pull
docker compose up -d
```

Перед обновлением всегда делайте бэкап volumes `stalwart-etc` и `stalwart-data`.

## Полезные ссылки

- Документация Stalwart: https://stalw.art/docs/
- Обратный прокси: https://stalw.art/docs/category/reverse-proxy/
- DNS-записи: https://stalw.art/docs/category/dns-records/
