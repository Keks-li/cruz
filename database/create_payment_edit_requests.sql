-- Payment edit request tracking table
-- Run this migration in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS payment_edit_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id),
  agent_id UUID NOT NULL REFERENCES profiles(id),
  original_amount DECIMAL(10,2) NOT NULL,
  new_amount DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_payment_edit_requests_payment_id ON payment_edit_requests(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_edit_requests_agent_id ON payment_edit_requests(agent_id);
CREATE INDEX IF NOT EXISTS idx_payment_edit_requests_status ON payment_edit_requests(status);

-- Enable RLS
ALTER TABLE payment_edit_requests ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users
CREATE POLICY "Enable all access for authenticated users" ON payment_edit_requests
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
