-- CreateTable
CREATE TABLE "reject_wager_claims" (
    "id" TEXT NOT NULL,
    "wager_claim_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'rejected',
    "reason" TEXT NOT NULL,
    "proof_link" TEXT,
    "proof_file" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reject_wager_claims_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "reject_wager_claims_wager_claim_id_key" ON "reject_wager_claims"("wager_claim_id");

-- AddForeignKey
ALTER TABLE "reject_wager_claims" ADD CONSTRAINT "reject_wager_claims_wager_claim_id_fkey" FOREIGN KEY ("wager_claim_id") REFERENCES "wager_claims"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
