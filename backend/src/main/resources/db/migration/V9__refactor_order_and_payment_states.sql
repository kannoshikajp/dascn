-- Migration: V9__refactor_order_and_payment_states.sql
-- Refactor order and payment statuses to sequential business flow with showroom purchase & refund constraints

-- 1. Add order_channel, paid_at, and delivered_at columns
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_channel VARCHAR(30) NOT NULL DEFAULT 'ONLINE';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

-- 2. Migrate existing historical order_status values without data loss
UPDATE orders SET order_status = 'ACCEPTED' WHERE UPPER(order_status) IN ('PENDING', 'CONFIRMED');
UPDATE orders SET order_status = 'PACKAGING' WHERE UPPER(order_status) = 'PACKING';
UPDATE orders SET order_status = 'DELIVERY' WHERE UPPER(order_status) = 'SHIPPED';
UPDATE orders SET order_status = 'SHIPPED' WHERE UPPER(order_status) = 'DELIVERED';
UPDATE orders SET order_status = 'REFUND' WHERE UPPER(order_status) IN ('CANCELLED', 'REFUNDED');

-- 3. Migrate existing payment_status values
UPDATE orders SET payment_status = 'REFUND' WHERE UPPER(payment_status) = 'REFUNDED';

-- 4. Backfill paid_at and delivered_at for historical records
UPDATE orders SET paid_at = created_at WHERE UPPER(payment_status) = 'PAID' AND paid_at IS NULL;
UPDATE orders SET delivered_at = updated_at WHERE UPPER(order_status) IN ('SHIPPED', 'SHOWROOM_BUY') AND delivered_at IS NULL;

-- 5. Update column defaults to match online flow
ALTER TABLE orders ALTER COLUMN order_status SET DEFAULT 'ACCEPTED';
ALTER TABLE orders ALTER COLUMN payment_status SET DEFAULT 'PAID';
