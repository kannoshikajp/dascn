-- =============================================================================
-- Migration V12: Add Outbound support and Order linkage to Good Receipts
-- =============================================================================

-- Allow supplier_id to be nullable for OUTBOUND receipts (which link to orders, not suppliers)
ALTER TABLE good_receipts ALTER COLUMN supplier_id DROP NOT NULL;

-- Add receipt_type column: 'INBOUND' or 'OUTBOUND'
ALTER TABLE good_receipts ADD COLUMN IF NOT EXISTS receipt_type VARCHAR(20) NOT NULL DEFAULT 'INBOUND';

-- Add order_id column referencing orders(id)
ALTER TABLE good_receipts ADD COLUMN IF NOT EXISTS order_id UUID NULL;
ALTER TABLE good_receipts ADD CONSTRAINT fk_good_receipts_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_good_receipts_order_id ON good_receipts(order_id);
CREATE INDEX IF NOT EXISTS idx_good_receipts_receipt_type ON good_receipts(receipt_type);

-- Add optional note/reason column
ALTER TABLE good_receipts ADD COLUMN IF NOT EXISTS note VARCHAR(255) NULL;
