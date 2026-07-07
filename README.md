# Mailu Mail Server — деплой через Portainer

Готовый репозиторий для развертывания почтового сервера [Mailu](https://mailu.io/) через Docker Compose / Portainer Stack.

## Что внутри

- `docker-compose.yml` — стек Mailu (front, admin, postfix, dovecot, rspamd, roundcube webmail).
- `mailu.env` — основная конфигурация (домены, пароль админа, TLS).
- `nginx/npm-proxy-notes.md` — как настроить ваш Nginx Proxy Manager.

## Особенности

- Почтовые службы (SMTP/IMAP/POP3/Sieve) слушают на IP сервера напрямую.
- Веб-админка и Roundcube webmail доступны через ваш Nginx Proxy Manager.
- Админка Mailu поддерживает **русский язык**.
- Внутри админки создаёте домены и почтовые ящики.

## Подготовка

1. В Portainer удалите старый стек Stalwart и его volumes.
2. Отредактируйте `mailu.env` в этом репозитории (или задайте переменные в Portainer):

   ```env
   DOMAIN=winemaking-today.ru
   HOSTNAMES=mail.winemaking-today.ru
   INITIAL_ADMIN_PW=ВашСложныйПароль
   SECRET_KEY=...        # openssl rand -hex 16
   ```

3. Убедитесь, что DNS-запись `mail.winemaking-today.ru` указывает на IP сервера.

> По умолчанию в `mailu.env` установлено `SESSION_COOKIE_SECURE=False`, чтобы вход в админку работал по HTTP через ваш Nginx Proxy Manager. Для публичного HTTPS-доступа измените на `True`.

## Деплой в Portainer

1. **Stacks → Add stack → Repository**.
2. URL репозитория: `https://github.com/k1racle/smtp.git`.
3. Compose path: `docker-compose.yml`.
4. В разделе **Environment variables** можно вставить содержимое `mailu.env` (или оставить как есть — compose подхватит файл из репо).
5. **Deploy the stack**.

При первом запуске сервис `cert-init` сгенерирует самоподписанный сертификат для почтовых портов.

## Настройка Nginx Proxy Manager

См. `nginx/npm-proxy-notes.md`.

Кратко:

- Domain Names: `185.72.147.187` (или `mail.winemaking-today.ru`).
- Forward Hostname / IP: `185.72.147.187`.
- Forward Port: `8880`.
- Scheme: `http`.

Если используете домен — запросите Let's Encrypt в NPM. Если голый IP — оставьте HTTP.

## Первый вход

```text
https://185.72.147.187/admin
```

- Логин: `admin@winemaking-today.ru` (или ваш `INITIAL_ADMIN_ACCOUNT@INITIAL_ADMIN_DOMAIN`).
- Пароль: тот, что задан в `INITIAL_ADMIN_PW`.

## Смена языка на русский

В админке Mailu в правом верхнем углу нажмите на язык → выберите **Русский**.

## Создание доменов и ящиков

- **Управление → Домены → Создать** — добавьте все свои домены.
- Для каждого домена откройте **Подробности** и скопируйте DNS-записи (MX, SPF, DKIM, DMARC, TLSA) в панель управления DNS.
- **Управление → Пользователи → Создать** — добавляйте почтовые ящики.

## Webmail

Roundcube доступен по:

```text
https://185.72.147.187/webmail
```

Пользователь логинится полным email-адресом и своим паролем.

## TLS-сертификат для почты

По умолчанию используется самоподписанный сертификат. Почтовые клиенты будут предупреждать о нём.

Для продакшена рекомендуется получить валидный сертификат для `mail.winemaking-today.ru` и положить файлы в volume `mailu-certs` как:

- `cert.pem` — сертификат (или цепочка).
- `key.pem` — приватный ключ.

Или загрузите сертификат через админку Mailu: **Администрирование → Сертификаты**.

## rDNS / PTR

Обязательно настройте обратную DNS-запись для IP сервера на `mail.winemaking-today.ru` в панели хостинг-провайдера.

## Подключение почтовых клиентов

Для ящика `user@winemaking-today.ru`:

| Протокол | Сервер | Порт | Шифрование |
|---|---|---|---|
| IMAP | `mail.winemaking-today.ru` | 993 | SSL/TLS |
| SMTP | `mail.winemaking-today.ru` | 587 | STARTTLS |
| POP3 | `mail.winemaking-today.ru` | 995 | SSL/TLS |

## Обновление

Поменяйте `MAILU_VERSION` в `mailu.env` на новый релиз и нажмите **Pull and redeploy** в Portainer.
