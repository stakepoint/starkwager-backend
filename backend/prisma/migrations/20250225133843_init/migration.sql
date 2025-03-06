-- CreateTable
CREATE TABLE "wager_claims" (
    "id" TEXT NOT NULL,
    "wager_id" TEXT NOT NULL,
    "claimed_by" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "wager_claims_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "wager_claims_wager_id_key" ON "wager_claims"("wager_id");

-- AddForeignKey
ALTER TABLE "wager_claims" ADD CONSTRAINT "wager_claims_wager_id_fkey" FOREIGN KEY ("wager_id") REFERENCES "wagers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wager_claims" ADD CONSTRAINT "wager_claims_claimed_by_fkey" FOREIGN KEY ("claimed_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
