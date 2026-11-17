-- CreateTable
CREATE TABLE "StudentNoteComment" (
    "id" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "body" VARCHAR(500) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudentNoteComment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "StudentNoteComment_noteId_createdAt_idx" ON "StudentNoteComment"("noteId", "createdAt");

-- AddForeignKey
ALTER TABLE "StudentNoteComment" ADD CONSTRAINT "StudentNoteComment_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "StudentNote"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNoteComment" ADD CONSTRAINT "StudentNoteComment_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
