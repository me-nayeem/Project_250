-- AlterTable
ALTER TABLE "StudentProfile" ADD COLUMN     "pwaInstallDismissedAt" TIMESTAMP(3),
ADD COLUMN     "pwaInstalled" BOOLEAN NOT NULL DEFAULT false;
