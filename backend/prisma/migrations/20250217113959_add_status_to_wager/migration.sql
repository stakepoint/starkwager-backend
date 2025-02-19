-- AlterTable
ALTER TABLE "wagers" ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'pending';

UPDATE wagers
SET status = 'pending'
WHERE status IS NULL;