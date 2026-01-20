-- Add takeaway_number column for takeaway orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS takeaway_number TEXT;

-- Enable realtime for ingredients table (skip if already enabled)
-- ALTER PUBLICATION supabase_realtime ADD TABLE ingredients;
