-- CreateTable
CREATE TABLE "invitations" (
    "id" TEXT NOT NULL,
    "wager_id" TEXT NOT NULL,
    "invited_by_id" TEXT NOT NULL,
    "invited_username" CITEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "invitations_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_wager_id_fkey" FOREIGN KEY ("wager_id") REFERENCES "wagers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_invited_by_id_fkey" FOREIGN KEY ("invited_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_invited_username_fkey" FOREIGN KEY ("invited_username") REFERENCES "users"("username") ON DELETE RESTRICT ON UPDATE CASCADE;
