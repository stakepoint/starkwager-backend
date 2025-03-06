/*
  Warnings:

  - You are about to drop the `reject_wager_claims` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "reject_wager_claims" DROP CONSTRAINT "reject_wager_claims_wager_claim_id_fkey";

-- AlterTable
ALTER TABLE "wager_claims" ADD COLUMN     "proof_file" TEXT,
ADD COLUMN     "proof_link" TEXT,
ADD COLUMN     "reason" TEXT;

-- AlterTable
ALTER TABLE "wagers" ADD COLUMN     "tags" TEXT[];

-- DropTable
DROP TABLE "reject_wager_claims";
