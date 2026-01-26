-- Junction table for multi-product customer assignment
-- Run this migration in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS customer_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  is_active BOOLEAN DEFAULT true,
  boxes_assigned INTEGER NOT NULL,
  boxes_paid INTEGER DEFAULT 0,
  balance_due DECIMAL(10,2) NOT NULL,
  registration_fee_paid DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(customer_id, product_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_customer_products_customer_id ON customer_products(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_products_product_id ON customer_products(product_id);

-- Enable RLS
ALTER TABLE customer_products ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users
CREATE POLICY "Enable all access for authenticated users" ON customer_products
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Migrate existing customers to customer_products table
-- This inserts records for existing customers who have a product_id
INSERT INTO customer_products (customer_id, product_id, is_active, boxes_assigned, boxes_paid, balance_due, registration_fee_paid)
SELECT 
  id AS customer_id,
  product_id,
  is_active,
  total_boxes_assigned AS boxes_assigned,
  boxes_paid,
  balance_due,
  registration_fee_paid
FROM customers
WHERE product_id IS NOT NULL
ON CONFLICT (customer_id, product_id) DO NOTHING;
