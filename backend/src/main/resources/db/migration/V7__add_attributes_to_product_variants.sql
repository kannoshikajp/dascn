-- =============================================================================
-- Migration V7: Add structured attributes JSONB column to product_variants
-- =============================================================================

ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS attributes JSONB NULL;

CREATE INDEX IF NOT EXISTS idx_product_variants_attributes ON product_variants USING gin (attributes);
