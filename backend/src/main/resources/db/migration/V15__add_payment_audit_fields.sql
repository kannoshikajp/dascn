-- =============================================================================
-- Migration V15: Audit trail & fraud protection for POS manual payment confirmation
-- =============================================================================

ALTER TABLE orders ADD COLUMN IF NOT EXISTS manual_payment_ref VARCHAR(100) NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_confirmed_by UUID NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_confirm_note TEXT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_orders_payment_confirmed_by'
    ) THEN
        ALTER TABLE orders ADD CONSTRAINT fk_orders_payment_confirmed_by
            FOREIGN KEY (payment_confirmed_by) REFERENCES users (id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_orders_payment_confirmed_by ON orders(payment_confirmed_by);
