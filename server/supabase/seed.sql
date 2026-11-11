-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- Gak ada
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'users';