-- =============================================================================
-- Migration V13: Unit-level tracking via Serial Numbers (SN / IMEI)
-- =============================================================================

CREATE TABLE IF NOT EXISTS product_serials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    variant_id UUID NOT NULL,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    order_item_id UUID NULL,
    sold_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_serials_variant FOREIGN KEY (variant_id) REFERENCES product_variants (id) ON DELETE CASCADE,
    CONSTRAINT fk_product_serials_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_product_serials_variant ON product_serials(variant_id, status);
CREATE INDEX IF NOT EXISTS idx_product_serials_sn ON product_serials(serial_number);
CREATE INDEX IF NOT EXISTS idx_product_serials_order_item ON product_serials(order_item_id);
