CREATE EXTENSION IF NOT EXISTS citext;

-- Update the username column to use citext
ALTER TABLE "users" ALTER COLUMN "username" TYPE citext;