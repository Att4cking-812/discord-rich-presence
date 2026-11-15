# Discord Rich Presence

Простой Rich Presence для Discord на PowerShell: без Node.js, без сторонних библиотек и без фоновых сервисов. Скрипт подключается к локальному Discord по IPC и показывает статус «играет в …» с таймером.

## Запуск

1. Создай приложение на https://discord.com/developers/applications (это бесплатно).
2. Скопируй **Application ID** в `client_id.txt` (только цифры).
3. Запусти `DiscordRP.cmd`.

Готово: в профиле Discord появится статус с названием приложения и таймером.

## Параметры

```powershell
.\drp.ps1 -Details "Рисует Пуджа" -State "в Paint"
.\drp.ps1 -Details "Вайбкодит" -State "Процесс : отрицательный" -LargeImage "banner" -LargeText "Brickyard"
```

- `-Details` — первая строка статуса.
- `-State` — вторая строка.
- `-LargeImage` — ключ картинки из Rich Presence → Art Assets.
- `-LargeText` — подпись к картинке.
- `-RefreshSeconds` — как часто обновлять статус (по умолчанию 60).

Остановить: `Ctrl+C` в окне.

## Если Discord показывает старое название

Строка «Играет в …» — это имя Discord-приложения, а не текст из скрипта. Discord кэширует его до перезапуска. Полностью закрой Discord (правый клик по иконке в трее → Quit Discord), запусти заново и снова запусти `DiscordRP.cmd`. Если хочется другое имя — переименуй приложение в Developer Portal.

## Файлы

- `drp.ps1` — сам скрипт.
- `DiscordRP.cmd` — запуск в один клик.
- `client_id.txt` — Application ID (публичный идентификатор, не секрет).
- `banner_512.png`, `poop.png` — картинки для статуса.
