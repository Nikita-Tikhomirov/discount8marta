# Production Deployment 2026-06-08

Site: `https://discount8marta.ru/`

## Changes Applied

- Patched legacy premium/plugin PHP 8.5 compatibility issues in production:
  - `mega_main_menu`
  - `essential-grid`
  - `revslider`
  - `js_composer`
  - `testimonials-by-woothemes`
  - `woocommerce-products-filter`
  - `shortcodes-ultimate`
- Applied the Caden carousel layout fix from local production copy.
- Updated WooCommerce files to `10.8.1`.
- Updated Yoast SEO files to `27.7`.
- Uploaded current Russian language files for WooCommerce and Yoast SEO.

## Verification

- Production PHP: `8.5.0`.
- WordPress: `7.0`.
- WooCommerce: `10.8.1`.
- WooCommerce DB version: `10.8.1`.
- Yoast SEO: `27.7`.
- Locale: `ru_RU`.
- WooCommerce product data label: `Данные Товара`.
- Test product `35081` has regular price, sale price, Yoast title, and Yoast meta description.
- Home page and shop page return HTTP `200`.
- Browser check confirmed carousel item width matches owl item width on the home page.

## Server Cleanup

- Temporary `codex-*` PHP files and plugin ZIP files were removed from production.
- The aborted direct FTP temp folder `woocommerce.codex-new-20260608-195950` was removed.
- Rollback folders intentionally remain on production outside `wp-content/plugins`, so WordPress does not count them as inactive outdated plugins:
  - `wp-content/codex-rollbacks/woocommerce.pre-codex-20260608-201000`
  - `wp-content/codex-rollbacks/wordpress-seo.pre-codex-20260608-201209`

No production credentials or database dumps are stored in git.
