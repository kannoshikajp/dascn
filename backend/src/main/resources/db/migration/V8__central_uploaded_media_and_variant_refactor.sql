-- =============================================================================
-- Migration V8: Central Uploaded Media & Variant-Level Media/Description Refactor
-- =============================================================================

-- 1. Create central uploaded_media repository table
CREATE TABLE uploaded_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_url VARCHAR(500) NOT NULL UNIQUE,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    folder VARCHAR(50) NOT NULL DEFAULT 'general',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_uploaded_media_created_at ON uploaded_media(created_at DESC);
CREATE INDEX idx_uploaded_media_folder ON uploaded_media(folder);

-- 2. Drop legacy product_images table if present
DROP TABLE IF EXISTS product_images CASCADE;

-- 3. Create variant_media junction table for variant multi-image album
CREATE TABLE variant_media (
    variant_id UUID NOT NULL REFERENCES product_variants (id) ON DELETE CASCADE,
    media_id UUID NOT NULL REFERENCES uploaded_media (id) ON DELETE CASCADE,
    display_order INT NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_variant_media PRIMARY KEY (variant_id, media_id)
);

CREATE INDEX idx_variant_media_variant_id ON variant_media(variant_id, display_order ASC);
CREATE INDEX idx_variant_media_media_id ON variant_media(media_id);

-- 4. Alter product_variants to add version_code, variant_code, thumbnail_url, description
ALTER TABLE product_variants
    ADD COLUMN IF NOT EXISTS version_code VARCHAR(100),
    ADD COLUMN IF NOT EXISTS variant_code VARCHAR(100),
    ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT;

-- Backfill default version_code and variant_code for existing rows
UPDATE product_variants
SET version_code = COALESCE(version_code, 'V1'),
    variant_code = COALESCE(variant_code, sku)
WHERE version_code IS NULL OR variant_code IS NULL;

-- 5. Alter products table: add version_code and drop obsolete descriptive columns
ALTER TABLE products
    ADD COLUMN IF NOT EXISTS version_code VARCHAR(100),
    DROP COLUMN IF EXISTS short_description,
    DROP COLUMN IF EXISTS description,
    DROP COLUMN IF EXISTS specifications,
    DROP COLUMN IF EXISTS warranty_months,
    DROP COLUMN IF EXISTS thumbnail_url;
