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

- `local-runtime/php` - PHP 8.5.7, текущий рабочий режим локальной копии.
- `local-runtime/php74` - PHP 7.4.33, запасной режим для сравнения.
- `local-runtime/mariadb` - MariaDB 12.3.2 на `127.0.0.1:3307`.
- `local-runtime/mariadb-data` - локальная БД из свежего дампа `a0868706_discount8marta.sql`.

`local-runtime`, SQL-дампы, `wp-config.php` и файлы сайта исключены из git.

## PHP 8.5 и старые плагины

Локальная копия сейчас запускается на PHP 8.5.7. Для старых коммерческих/бандловых плагинов и темы добавлены минимальные совместимые патчи в локальных файлах сайта. Это не заменяет лицензионные обновления, но позволяет проверять сайт на актуальном PHP.

Запасной запуск на PHP 7.4:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-local.ps1 -Php 7.4
```

Подробный отчёт по восстановлению, обновлениям и оставшимся рискам: `docs/local-restore-report.md`.
