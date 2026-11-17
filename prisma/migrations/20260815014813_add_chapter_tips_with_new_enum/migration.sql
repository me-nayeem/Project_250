/*
  Warnings:

  - The values [FORMULA] on the enum `TipCategory` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "TipCategory_new" AS ENUM ('LAW', 'SHORTCUT', 'CALCULATOR_HACK');
ALTER TABLE "ChapterTip" ALTER COLUMN "category" TYPE "TipCategory_new" USING ("category"::text::"TipCategory_new");
ALTER TYPE "TipCategory" RENAME TO "TipCategory_old";
ALTER TYPE "TipCategory_new" RENAME TO "TipCategory";
DROP TYPE "public"."TipCategory_old";
COMMIT;
