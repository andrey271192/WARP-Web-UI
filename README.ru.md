# WARP Web UI

Веб-панель для управления **Cloudflare WARP** на Linux: подключение/отключение, ключ WARP+, порт SOCKS-прокси и пресеты для **3x-ui** и **Amnezia Xray**.

## Возможности

- **WARP**: Connect / Disconnect, перезапуск `warp-svc`, статус и логи
- **Аккаунт**: тип регистрации (Free / WARP+), применение лицензионного ключа
- **Установка и удаление** пакета `cloudflare-warp` из браузера
- **SOCKS**: смена порта `warp-cli proxy` (например `40000` или `1024`)
- **3x-ui**: outbound `warp-socks` → `127.0.0.1:ПОРТ`, маршрут `geosite:google`
- **Amnezia**: мост Docker `172.17.0.1:11025` → SOCKS на хосте, WARP только для выбранных клиентов, понятные имена

## Требования

- Linux (рекомендуется Debian/Ubuntu)
- `python3` (только стандартная библиотека)
- `systemd`
- По желанию: `cloudflare-warp` (ставится из UI или `scripts/warp-install-cf.sh`)
- Для пресетов: `docker`, `socat`, `x-ui` / Amnezia

## Быстрый старт

### Установка одной командой

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/install.sh | sudo bash
```

Скрипт **спрашивает**:

| Вопрос | По умолчанию | Пояснение |
|--------|--------------|-----------|
| Порт SOCKS | `40000` | Часто также `1024` у официального пакета |
| Порт веб-UI | `3030` | Откройте в firewall при необходимости |
| Логин админа | `warpadmin` | HTTP Basic Auth |
| Пароль админа | *(обязательно, ≥ 8 символов)* | Файл `/etc/default/warp-webui` |

### Клонирование

```bash
git clone https://github.com/andrey271192/WARP-Web-UI.git
cd WARP-Web-UI
sudo bash install.sh
```

Откройте `http://ВАШ_СЕРВЕР:3030/`. Если WARP ещё не установлен — кнопка **Install WARP** в интерфейсе.

### Удаление

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/uninstall.sh | sudo bash
```

Или `sudo bash uninstall.sh` из клонированного репозитория. Можно удалить только панель или также пакет `cloudflare-warp` (подтверждение в конце).

## Структура репозитория

- `app.py` — веб-интерфейс и API
- `scripts/warp-install-cf.sh`, `warp-uninstall-cf.sh` — установка/удаление WARP
- `systemd/warp-webui.service` — шаблон unit
- `install.sh`, `uninstall.sh` — установка и снятие «в одну кнопку»

После установки: `/opt/warp-webui/`, настройки `/etc/default/warp-webui`.

## Настройка

См. [`.env.example`](.env.example). Имена клиентов Amnezia: `/etc/warp-webui/client-aliases.json`.

## Безопасность

- Только **Basic Auth по HTTP** — для продакшена используйте **HTTPS** (nginx/Caddy).
- **Firewall**: открывайте порт панели только для доверенных IP.
- Сервис работает от **root** (нужен для `warp-cli`, systemd, Docker). Не выставляйте панель в открытый интернет без защиты.
- Не публикуйте `/etc/default/warp-webui` и смените пароль после установки.

## English documentation

See [README.md](README.md).

## Лицензия

MIT — [LICENSE](LICENSE).
