# discount8marta local restore

Локальная копия сайта WordPress/WooCommerce разворачивается без OpenServer.

## Запуск

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-local.ps1
```

Сайт откроется на `http://127.0.0.1:8088/`.

Локальный администратор создан отдельно от продакшен-доступов. Данные лежат в `local-runtime/local-admin.txt`.

Остановка:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\stop-local.ps1
```

## Что внутри

- `local-runtime/php74` - PHP 7.4.33 для запуска текущей копии старого сайта.
- `local-runtime/php` - PHP 8.5.7 для проверки совместимости с актуальным PHP.
- `local-runtime/mariadb` - MariaDB 12.3.2 на `127.0.0.1:3307`.
- `local-runtime/mariadb-data` - локальная БД из свежего дампа `a0868706_discount8marta.sql`.

`local-runtime`, SQL-дампы, `wp-config.php` и файлы сайта исключены из git.

## Почему PHP 7.4

Текущая копия содержит старые коммерческие плагины (`Essential Grid`, `Slider Revolution`, `WPBakery`), которые падают на PHP 8.5 из-за удалённых функций PHP и старого синтаксиса. PHP 7.4 используется только как базовый режим для безопасного локального запуска. PHP 8.5 оставлен для отдельного этапа обновления и проверки совместимости.

Подробный отчёт по восстановлению, обновлениям и оставшимся рискам: `docs/local-restore-report.md`.
