# Local restore report

Дата: 2026-06-07

## Локальный стенд

- URL: `http://127.0.0.1:8088/`
- Админка: `http://127.0.0.1:8088/wp-admin/`
- Локальный runtime: `local-runtime/` (не коммитится)
- БД: MariaDB 12.3.2, `127.0.0.1:3307`
- Рабочий PHP для текущего сайта: PHP 7.4.33
- Целевой PHP для проверки совместимости: PHP 8.5.7

Локальный пользователь администратора создан отдельно, данные лежат в `local-runtime/local-admin.txt`.

## Что было найдено

1. WordPress уже версии `7.0`, но ключевые плагины были сильно старее:
   - WooCommerce `4.9.2`
   - Yoast SEO `15.3`
2. Русский WooCommerce не загружался на уровне PHP: `__('Product data', 'woocommerce')` возвращал английский текст.
3. Причина русского WooCommerce до обновления: рабочий файл был в `wp-content/languages/plugins/woocommerce-ru_RU.mo`, а старый WooCommerce сначала искал `wp-content/languages/woocommerce/woocommerce-ru_RU.mo`. На новом ядре неудачная первая загрузка оставляла NOOP textdomain.
4. На карточке товара до обновления:
   - WooCommerce metabox был смешанным/английским.
   - Поля `_regular_price` и `_sale_price` фактически присутствовали и были видимы.
   - Yoast metabox существовал, но React UI с SEO-полями не отрисовывался.
5. Локальная админка сначала не пускала по HTTP, потому что HTTPS-плагины принудительно меняли form action на `https://127.0.0.1:8088/`.

## Что сделано локально

- Поднят локальный сайт без OpenServer через portable PHP + MariaDB.
- Импортирован свежий дамп `a0868706_discount8marta.sql`.
- Отключены только локально HTTPS-плагины:
  - `http-https-remover`
  - `https-redirection`
- Обновлены бесплатные плагины через WP-CLI, включая:
  - WooCommerce `4.9.2 -> 10.8.1`
  - Yoast SEO `15.3 -> 27.7`
- Обновлены 13 языковых пакетов плагинов.
- Выполнен `wp wc update`: WooCommerce DB version `10.8.1`.
- Обновлены стандартные неактивные темы WordPress.
- Проверена карточка товара `ID=35081`:
  - интерфейс WooCommerce на русском;
  - цена и цена распродажи видимы;
  - Yoast SEO-поля видимы.

## Осталось / риски

- WPBakery Page Builder (`js_composer`) остался `5.4.5`; обновление до `8.7.3` требует активации лицензии.
- `woocommerce-products-filter` сообщает `version higher than expected`, автоматическое обновление не применялось.
- Активная тема `caden` версии `1.2` не имеет обновления через WordPress.org.
- WooCommerce показывает предупреждение: в теме `Caden` есть устаревшие шаблоны WooCommerce.
- PHP 8.5 пока не является рабочим режимом для всего сайта: старые коммерческие/неподдерживаемые плагины всё ещё дают fatal/warning. Последний подтверждённый fatal на PHP 8.5: `mega_main_menu/framework/options_generator.php`.

## Rollback

Перед обновлением создана локальная rollback-точка:

- `local-runtime/backups/pre-plugin-update-20260607-1745/discount8marta_local.sql`
- `local-runtime/backups/pre-plugin-update-20260607-1745/plugins.zip`
