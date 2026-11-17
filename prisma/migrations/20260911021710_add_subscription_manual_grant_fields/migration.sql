-- AlterTable
ALTER TABLE "Subscription" ADD COLUMN     "grantedByUserId" TEXT,
ADD COLUMN     "paymentReference" VARCHAR(160);
