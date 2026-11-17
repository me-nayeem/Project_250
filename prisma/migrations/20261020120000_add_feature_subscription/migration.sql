-- CreateTable
CREATE TABLE "FeatureSubscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "featureKey" VARCHAR(80) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeatureSubscription_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "FeatureSubscription_featureKey_idx" ON "FeatureSubscription"("featureKey");

-- CreateIndex
CREATE UNIQUE INDEX "FeatureSubscription_userId_featureKey_key" ON "FeatureSubscription"("userId", "featureKey");

-- AddForeignKey
ALTER TABLE "FeatureSubscription" ADD CONSTRAINT "FeatureSubscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
