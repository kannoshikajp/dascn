-- =============================================================================
-- Migration V14: Add Payment TTL / Expiration for Stock Reservation
-- =============================================================================

ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_expires_at TIMESTAMP WITH TIME ZONE NULL;

CREATE INDEX IF NOT EXISTS idx_orders_payment_ttl ON orders(payment_status, payment_expires_at);
