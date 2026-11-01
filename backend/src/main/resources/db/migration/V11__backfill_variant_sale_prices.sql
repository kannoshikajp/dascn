-- Migration: V11__backfill_variant_sale_prices.sql
-- Backfill sale_price from list_price for existing variants if sale_price is 0 or null

UPDATE product_variants
SET sale_price = list_price
WHERE (sale_price IS NULL OR sale_price = 0) AND list_price > 0;
