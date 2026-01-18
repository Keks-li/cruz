-- Create system settings table
CREATE TABLE IF NOT EXISTS system_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default registration fee
INSERT INTO system_settings (key, value)
VALUES ('registration_fee', '0')
ON CONFLICT (key) DO NOTHING;
