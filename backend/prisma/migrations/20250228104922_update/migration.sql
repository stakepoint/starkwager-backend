-- DropForeignKey
ALTER TABLE "wager_claims" DROP CONSTRAINT "wager_claims_claimed_by_fkey";

-- DropForeignKey
ALTER TABLE "wager_claims" DROP CONSTRAINT "wager_claims_wager_id_fkey";

-- AlterTable
ALTER TABLE "wager_claims" ALTER COLUMN "wager_id" DROP NOT NULL,
ALTER COLUMN "claimed_by" DROP NOT NULL,
ALTER COLUMN "status" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "wager_claims" ADD CONSTRAINT "wager_claims_wager_id_fkey" FOREIGN KEY ("wager_id") REFERENCES "wagers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wager_claims" ADD CONSTRAINT "wager_claims_claimed_by_fkey" FOREIGN KEY ("claimed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
