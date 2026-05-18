ALTER TABLE flights
ADD COLUMN IF NOT EXISTS is_delivery_enabled BOOLEAN DEFAULT false;
