# Настройка Nginx Proxy Manager для Mailu

В NPM нужно добавить **Proxy Host**, который будет проксировать запросы в контейнер `mailu-front`.

## Вкладка Details

| Поле | Значение |
|---|---|
| Domain Names | `185.72.147.187` (или ваш домен, например `mail.winemaking-today.ru`) |
| Scheme | `http` |
| Forward Hostname / IP | `185.72.147.187` |
| Forward Port | `8880` |
| Cache Assets | выключить |
| Block Common Exploits | по желанию |
| Websockets Support | выключить |

> `185.72.147.187:8880` — это порт, на котором Mailu front слушает HTTP внутри Docker.

## Вкладка SSL

- Если используете **домен** (`mail.winemaking-today.ru`): запросите **Let's Encrypt** сертификат.
- Если используете **голый IP**: Let's Encrypt не выдаст сертификат. Можно оставить **SSL Certificate: None** (HTTP) или загрузить самоподписанный сертификат.

## Доступ после настройки

```text
https://185.72.147.187/admin      # админка Mailu
https://185.72.147.187/webmail    # Roundcube webmail
```

Логин: `admin@winemaking-today.ru` (или тот, что задан в `INITIAL_ADMIN_DOMAIN`).
Пароль: из переменной `INITIAL_ADMIN_PW`.
