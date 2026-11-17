-- CreateTable
CREATE TABLE "PlaylistVideoProgress" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "completedAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlaylistVideoProgress_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PlaylistVideoProgress_videoId_idx" ON "PlaylistVideoProgress"("videoId");

-- CreateIndex
CREATE UNIQUE INDEX "PlaylistVideoProgress_studentId_videoId_key" ON "PlaylistVideoProgress"("studentId", "videoId");

-- AddForeignKey
ALTER TABLE "PlaylistVideoProgress" ADD CONSTRAINT "PlaylistVideoProgress_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaylistVideoProgress" ADD CONSTRAINT "PlaylistVideoProgress_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "ChapterPlaylistVideo"("id") ON DELETE CASCADE ON UPDATE CASCADE;
