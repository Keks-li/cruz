-- ============================================================
-- CYCLE SEPARATION — STEP 1: Create cycles table
-- Run this FIRST in Supabase SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS cycles (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,
  is_active  BOOLEAN DEFAULT false,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at   TIMESTAMPTZ,
  notes      TEXT
);

-- Enable RLS
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all access for authenticated users" ON cycles
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- Insert Cycle 1 — historical / existing data (inactive)
-- ============================================================
INSERT INTO cycles (name, is_active, notes)
VALUES (
  'Cycle 1',
  false,
  'Initial business cycle — all data that existed before the fresh start'
)
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- Insert Cycle 2 — the new active cycle for fresh entries
-- ============================================================
INSERT INTO cycles (name, is_active, notes)
VALUES (
  'Cycle 2',
  true,
  'Current active cycle — fresh entries from August 2026 onward'
)
ON CONFLICT (name) DO NOTHING;

-- Verify
SELECT id, name, is_active, started_at FROM cycles ORDER BY id;
