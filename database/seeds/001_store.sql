INSERT INTO stores (shop_domain, display_name, currency_code, timezone, active)
VALUES (
  :'shopify_store_domain',
  :'shopify_store_name',
  'USD',
  'America/Los_Angeles',
  true
)
ON CONFLICT (shop_domain) DO UPDATE
SET display_name = EXCLUDED.display_name,
    updated_at = now();

INSERT INTO suppliers (store_id, supplier_type, external_account_id, name, status)
SELECT id, 'CJ_DROPSHIPPING', 'CJ5748386', 'CJdropshipping', 'ACTIVE'
FROM stores
WHERE shop_domain = :'shopify_store_domain'
ON CONFLICT (store_id, supplier_type, external_account_id) DO UPDATE
SET name = EXCLUDED.name,
    status = EXCLUDED.status,
    updated_at = now();
