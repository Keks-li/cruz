-- Add registration_fee_paid column to customers table
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS registration_fee_paid DOUBLE PRECISION DEFAULT 0;

-- Migrate existing customers: set their registration fee to current global fee
UPDATE customers 
SET registration_fee_paid = COALESCE(
  (SELECT value::double precision FROM system_settings WHERE key = 'registration_fee'),
  0
)
WHERE registration_fee_paid = 0;

-- Add comment to document the column
COMMENT ON COLUMN customers.registration_fee_paid IS 'The registration fee that this customer paid at registration time';
