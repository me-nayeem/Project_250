-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'CHAPTER_NEEDS_REVIEW';

-- AlterTable
ALTER TABLE "QuizQuestion" ADD COLUMN     "topicId" TEXT;

-- AddForeignKey
ALTER TABLE "QuizQuestion" ADD CONSTRAINT "QuizQuestion_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE SET NULL ON UPDATE CASCADE;
