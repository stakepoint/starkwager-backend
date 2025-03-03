-- CreateTable
CREATE TABLE "IndexerCursor" (
    "id" SERIAL NOT NULL,
    "orderKey" INTEGER NOT NULL,
    "uniqueKey" TEXT NOT NULL,

    CONSTRAINT "IndexerCursor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IndexerEvent" (
    "id" SERIAL NOT NULL,
    "fromAddress" TEXT NOT NULL,
    "keys" TEXT[],
    "data" TEXT[],
    "cursorId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IndexerEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IndexerMessage" (
    "id" SERIAL NOT NULL,
    "cursorId" INTEGER NOT NULL,
    "endCursorId" INTEGER NOT NULL,
    "finality" TEXT NOT NULL,
    "batch" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IndexerMessage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "IndexerCursor_orderKey_key" ON "IndexerCursor"("orderKey");

-- CreateIndex
CREATE UNIQUE INDEX "IndexerCursor_uniqueKey_key" ON "IndexerCursor"("uniqueKey");

-- AddForeignKey
ALTER TABLE "IndexerEvent" ADD CONSTRAINT "IndexerEvent_cursorId_fkey" FOREIGN KEY ("cursorId") REFERENCES "IndexerCursor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IndexerMessage" ADD CONSTRAINT "IndexerMessage_cursorId_fkey" FOREIGN KEY ("cursorId") REFERENCES "IndexerCursor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IndexerMessage" ADD CONSTRAINT "IndexerMessage_endCursorId_fkey" FOREIGN KEY ("endCursorId") REFERENCES "IndexerCursor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
