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
- Fixed the post-update production fatal error on uncached home page requests:
  - root cause: `wp-content/themes/caden/functions.php` called `$wp_filesystem->exists()` while `$wp_filesystem` was `null`;
  - fix: Caden now falls back to `file_exists()`, `file_get_contents()`, and `file_put_contents()` for generated theme CSS/JS files when WP Filesystem is not initialized.
- Reset the product edit screen metabox order for user `discount8marta` / `Юлия`:
  - root cause: WordPress user meta `meta-box-order_product` had `woocommerce-product-data` saved in the `side` column;
  - fix: moved `woocommerce-product-data` to the `normal` column before `wpseo_meta`.
- Updated remaining WordPress.org plugins available through official packages:
  - Bot for Telegram on WooCommerce `1.2.6` -> `1.3.0`
  - Checkout Field Editor for WooCommerce `1.4.5` -> `2.1.8`
  - Classic Editor `1.6.3` -> `1.7.0`
  - Contact Form 7 `5.3.2` -> `6.1.6`
  - Cyr to Lat enhanced `3.5` -> `3.7.4`
  - Easy HTTPS (SSL) Redirection `1.9.1` -> `2.0.0`
  - HTTP / HTTPS Removal `3.1` -> `3.2.8`
  - Index WP MySQL For Speed `1.4.4` -> `1.5.7`
  - Loco Translate `2.5.0` -> `2.8.5`
  - Market Exporter `2.0.17` -> `2.0.23`
  - MC4WP: Mailchimp for WordPress `4.8.3` -> `4.13.0`
  - Optimize Database after Deleting Revisions `5.0.3` -> `5.3.0`
  - Popup Maker `1.15.0` -> `1.22.0`
  - Product Feed Manager for WooCommerce `7.2.25` -> `7.5.4`
  - Redux `4.1.24` -> `4.5.11`
  - Saphali Woocommerce Russian `1.8.10` -> `2.0.1`
  - Shortcodes Ultimate `5.9.6` -> `7.7.0`
  - Simple Local Avatars `2.2.0` -> `2.8.6`
  - Smush `3.8.2` -> `4.1.0`
  - TinyMCE Advanced `5.4.0` -> `5.9.2`
  - WP File Manager `7.1.7` -> `8.0.4`
  - WP-Optimize `3.2.6` -> `4.5.5`
  - YITH WooCommerce Compare `2.4.4` -> `3.10.0`
  - YITH WooCommerce Wishlist `3.0.18` -> `4.15.0`
  - YITH WooCommerce Zoom Magnifier `1.3.22` -> `2.50.0`
  - YML for Yandx Market `5.5.0` -> `5.5.1`

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
- Uncached home page URLs return HTTP `200` with no WordPress critical error.
- Product edit screen user meta now keeps `woocommerce-product-data` in the normal column for user `discount8marta` / `Юлия`.
- Browser check confirmed carousel item width matches owl item width on the home page.
- After updating all WordPress.org plugins, the only remaining plugin updates shown by WordPress are paid/no-package updates:
  - active `WPBakery Page Builder` `5.4.5` -> `8.7.3`;
  - inactive `WPML Multilingual CMS` `3.9.0` -> `4.9.4`.

## Server Cleanup

- Temporary `codex-*` PHP files and plugin ZIP files were removed from production.
- Temporary plugin updater scripts were removed from production.
- The aborted direct FTP temp folder `woocommerce.codex-new-20260608-195950` was removed.
- One-file local rollback for the Caden fatal fix was stored outside git under `local-runtime/prod-backups/`.
- Rollback folders intentionally remain on production outside `wp-content/plugins`, so WordPress does not count them as inactive outdated plugins:
  - `wp-content/codex-rollbacks/woocommerce.pre-codex-20260608-201000`
  - `wp-content/codex-rollbacks/wordpress-seo.pre-codex-20260608-201209`

No production credentials or database dumps are stored in git.
