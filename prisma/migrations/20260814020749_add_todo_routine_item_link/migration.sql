/*
  Warnings:

  - A unique constraint covering the columns `[sourceRoutineItemId,dueDate]` on the table `TodoItem` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "TodoItem" ADD COLUMN     "sourceRoutineItemId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "TodoItem_sourceRoutineItemId_dueDate_key" ON "TodoItem"("sourceRoutineItemId", "dueDate");

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_sourceRoutineItemId_fkey" FOREIGN KEY ("sourceRoutineItemId") REFERENCES "StudyRoutineItem"("id") ON DELETE SET NULL ON UPDATE CASCADE;
