-- CreateTable
CREATE TABLE "StudentNoteLike" (
    "id" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StudentNoteLike_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentNoteRating" (
    "id" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudentNoteRating_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "StudentNoteLike_noteId_idx" ON "StudentNoteLike"("noteId");

-- CreateIndex
CREATE UNIQUE INDEX "StudentNoteLike_noteId_studentId_key" ON "StudentNoteLike"("noteId", "studentId");

-- CreateIndex
CREATE INDEX "StudentNoteRating_noteId_idx" ON "StudentNoteRating"("noteId");

-- CreateIndex
CREATE UNIQUE INDEX "StudentNoteRating_noteId_studentId_key" ON "StudentNoteRating"("noteId", "studentId");

-- AddForeignKey
ALTER TABLE "StudentNoteLike" ADD CONSTRAINT "StudentNoteLike_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "StudentNote"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNoteLike" ADD CONSTRAINT "StudentNoteLike_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNoteRating" ADD CONSTRAINT "StudentNoteRating_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "StudentNote"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNoteRating" ADD CONSTRAINT "StudentNoteRating_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
