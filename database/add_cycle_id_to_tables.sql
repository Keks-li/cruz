-- ============================================================
-- CYCLE SEPARATION — STEP 2: Add cycle_id to transactional tables
-- Run this AFTER create_cycles.sql in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PART A: customers table
-- ============================================================
ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS cycle_id INTEGER REFERENCES cycles(id);

-- Tag all existing customers as Cycle 1
UPDATE customers
SET cycle_id = (SELECT id FROM cycles WHERE name = 'Cycle 1')
WHERE cycle_id IS NULL;

-- Make required going forward
ALTER TABLE customers ALTER COLUMN cycle_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_customers_cycle_id ON customers(cycle_id);

-- ============================================================
-- PART B: customer_products table
-- ============================================================
ALTER TABLE customer_products
  ADD COLUMN IF NOT EXISTS cycle_id INTEGER REFERENCES cycles(id);

UPDATE customer_products
SET cycle_id = (SELECT id FROM cycles WHERE name = 'Cycle 1')
WHERE cycle_id IS NULL;

ALTER TABLE customer_products ALTER COLUMN cycle_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_customer_products_cycle_id ON customer_products(cycle_id);

-- ============================================================
-- PART C: payments table
-- ============================================================
ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS cycle_id INTEGER REFERENCES cycles(id);

UPDATE payments
SET cycle_id = (SELECT id FROM cycles WHERE name = 'Cycle 1')
WHERE cycle_id IS NULL;

ALTER TABLE payments ALTER COLUMN cycle_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_payments_cycle_id ON payments(cycle_id);

-- ============================================================
-- VERIFICATION — run these after to confirm all rows are tagged
-- ============================================================
SELECT 'customers' AS tbl, COUNT(*) AS untagged FROM customers WHERE cycle_id IS NULL
UNION ALL
SELECT 'customer_products', COUNT(*) FROM customer_products WHERE cycle_id IS NULL
UNION ALL
SELECT 'payments', COUNT(*) FROM payments WHERE cycle_id IS NULL;
-- All rows should return 0
