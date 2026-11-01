-- Migration: V10__product_parent_sku_and_remove_codes.sql
-- Refactor products to flat self-referential structure with parent_sku, removing version_code and variant_code

-- 1. Add sku and parent_sku columns to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS sku VARCHAR(100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS parent_sku VARCHAR(100);

-- 2. Backfill products.sku from primary product_variants without data loss
UPDATE products p
SET sku = pv.sku
FROM (
    SELECT DISTINCT ON (product_id) product_id, sku
    FROM product_variants
    ORDER BY product_id, created_at ASC
) pv
WHERE p.id = pv.product_id AND p.sku IS NULL;

-- 3. For any product without existing variants, generate SKU from slug
UPDATE products
SET sku = UPPER(REPLACE(slug, '-', ''))
WHERE sku IS NULL OR sku = '';

-- 4. Migrate secondary variants into separate products referencing father via parent_sku
INSERT INTO products (id, category_id, brand_id, product_name, slug, sku, parent_sku, is_active, created_at, updated_at)
SELECT
    pv.id,
    p.category_id,
    p.brand_id,
    p.product_name || ' (' || pv.variant_name || ')',
    p.slug || '-' || LOWER(REPLACE(pv.sku, ' ', '-')),
    pv.sku,
    p.sku,
    pv.is_active,
    pv.created_at,
    pv.updated_at
FROM product_variants pv
JOIN products p ON pv.product_id = p.id
WHERE pv.sku != p.sku
ON CONFLICT (id) DO NOTHING;

-- 5. Ensure products.sku is NOT NULL and UNIQUE
ALTER TABLE products ALTER COLUMN sku SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_parent_sku ON products(parent_sku);

-- 6. Remove legacy version_code and variant_code columns
ALTER TABLE products DROP COLUMN IF EXISTS version_code;
ALTER TABLE product_variants DROP COLUMN IF EXISTS version_code;
ALTER TABLE product_variants DROP COLUMN IF EXISTS variant_code;
