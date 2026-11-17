-- CreateEnum
CREATE TYPE "TipCategory" AS ENUM ('LAW', 'FORMULA', 'CALCULATOR_HACK');

-- CreateTable
CREATE TABLE "ChapterTip" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "category" "TipCategory" NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "youtubeUrl" VARCHAR(255),
    "driveLink" VARCHAR(255),
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "addedByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChapterTip_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ChapterTip_chapterId_category_idx" ON "ChapterTip"("chapterId", "category");

-- AddForeignKey
ALTER TABLE "ChapterTip" ADD CONSTRAINT "ChapterTip_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;
