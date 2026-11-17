-- CreateEnum
CREATE TYPE "FeedbackCategory" AS ENUM ('BUG', 'SUGGESTION', 'GENERAL');

-- CreateTable
CREATE TABLE "Feedback" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "category" "FeedbackCategory" NOT NULL,
    "message" TEXT NOT NULL,
    "isReviewed" BOOLEAN NOT NULL DEFAULT false,
    "reviewedByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Feedback_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Feedback_isReviewed_createdAt_idx" ON "Feedback"("isReviewed", "createdAt");

-- AddForeignKey
ALTER TABLE "Feedback" ADD CONSTRAINT "Feedback_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
