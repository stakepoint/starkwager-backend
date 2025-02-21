-- CreateTable
CREATE TABLE "_HashtagToWager" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL,

    CONSTRAINT "_HashtagToWager_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE INDEX "_HashtagToWager_B_index" ON "_HashtagToWager"("B");

-- AddForeignKey
ALTER TABLE "_HashtagToWager" ADD CONSTRAINT "_HashtagToWager_A_fkey" FOREIGN KEY ("A") REFERENCES "hashtags"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_HashtagToWager" ADD CONSTRAINT "_HashtagToWager_B_fkey" FOREIGN KEY ("B") REFERENCES "wagers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
