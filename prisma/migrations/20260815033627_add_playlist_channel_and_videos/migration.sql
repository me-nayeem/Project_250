-- AlterTable
ALTER TABLE "ChapterPlaylist" ADD COLUMN     "channelUrl" VARCHAR(255);

-- CreateTable
CREATE TABLE "ChapterPlaylistVideo" (
    "id" TEXT NOT NULL,
    "playlistId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "youtubeUrl" VARCHAR(255) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "addedByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChapterPlaylistVideo_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ChapterPlaylistVideo_playlistId_idx" ON "ChapterPlaylistVideo"("playlistId");

-- AddForeignKey
ALTER TABLE "ChapterPlaylistVideo" ADD CONSTRAINT "ChapterPlaylistVideo_playlistId_fkey" FOREIGN KEY ("playlistId") REFERENCES "ChapterPlaylist"("id") ON DELETE CASCADE ON UPDATE CASCADE;
