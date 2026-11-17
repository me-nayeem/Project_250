-- CreateEnum
CREATE TYPE "Role" AS ENUM ('STUDENT', 'MANAGER', 'ADMIN');

-- CreateEnum
CREATE TYPE "GroupType" AS ENUM ('SCIENCE', 'ARTS', 'COMMERCE');

-- CreateEnum
CREATE TYPE "EducationLevel" AS ENUM ('SSC', 'HSC');

-- CreateEnum
CREATE TYPE "Board" AS ENUM ('DHAKA', 'RAJSHAHI', 'CUMILLA', 'JASHORE', 'CHATTOGRAM', 'BARISHAL', 'SYLHET', 'DINAJPUR', 'MYMENSINGH', 'MADRASAH', 'TECHNICAL');

-- CreateEnum
CREATE TYPE "MasteryStatus" AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'AWAITING_QUIZ', 'MASTERED', 'NEEDS_REVIEW');

-- CreateEnum
CREATE TYPE "ResourceKind" AS ENUM ('VIDEO', 'PAID_ITEM');

-- CreateEnum
CREATE TYPE "VideoType" AS ENUM ('ONESHOT', 'FULL_LECTURE', 'PAID_BATCH');

-- CreateEnum
CREATE TYPE "AccessType" AS ENUM ('FREE', 'SUBSCRIPTION', 'BATCH_PURCHASE');

-- CreateEnum
CREATE TYPE "QuizContext" AS ENUM ('AUTO_VALIDATION', 'PRACTICE');

-- CreateEnum
CREATE TYPE "SessionType" AS ENUM ('POMODORO', 'FREE_STUDY');

-- CreateEnum
CREATE TYPE "StudySessionStatus" AS ENUM ('ACTIVE', 'PAUSED', 'ENDED', 'ABANDONED');

-- CreateEnum
CREATE TYPE "PointReason" AS ENUM ('CHAPTER_MASTERED', 'QUIZ_ATTEMPT', 'STREAK_BONUS', 'MANUAL_ADJUSTMENT', 'EXTERNAL_EXAM_RESULT', 'NOTE_UPLOADED', 'PLAYLIST_REVIEWED');

-- CreateEnum
CREATE TYPE "ScoringMode" AS ENUM ('FLAT', 'PER_MARK', 'PER_WEIGHT');

-- CreateEnum
CREATE TYPE "LeaderboardMetric" AS ENUM ('STUDY_TIME', 'MASTER_SCORE');

-- CreateEnum
CREATE TYPE "LeaderboardPeriod" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'ALL_TIME');

-- CreateEnum
CREATE TYPE "TodoSourceType" AS ENUM ('MANUAL', 'ROUTINE_GENERATED', 'EXAM_REMINDER');

-- CreateEnum
CREATE TYPE "SpecialVideoTag" AS ENUM ('ONE_SHOT', 'ADMISSION', 'MOTIVATION', 'TRICK', 'OTHER');

-- CreateEnum
CREATE TYPE "NoteModerationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "ExamResultStatus" AS ENUM ('PENDING', 'MATCHED', 'UNMATCHED', 'DISPUTED');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('DAILY_REMINDER', 'STREAK_RISK', 'RECOMMENDATION', 'PACE_ALERT', 'SYSTEM');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELED');

-- CreateEnum
CREATE TYPE "OtpPurpose" AS ENUM ('EMAIL_VERIFICATION', 'PASSWORD_RESET');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(120),
    "email" VARCHAR(255),
    "emailVerified" TIMESTAMP(3),
    "passwordHash" VARCHAR(255),
    "image" VARCHAR(255),
    "role" "Role" NOT NULL DEFAULT 'STUDENT',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "sessionToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "EmailOtp" (
    "id" TEXT NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "codeHash" VARCHAR(255) NOT NULL,
    "purpose" "OtpPurpose" NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "consumedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EmailOtp_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "trackId" TEXT NOT NULL,
    "board" "Board",
    "institutionName" VARCHAR(160),
    "phoneNumber" VARCHAR(20),
    "streakCount" INTEGER NOT NULL DEFAULT 0,
    "lastActiveAt" TIMESTAMP(3),
    "totalPoints" INTEGER NOT NULL DEFAULT 0,
    "level" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StudentProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Track" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "level" "EducationLevel" NOT NULL,
    "group" "GroupType" NOT NULL,
    "batchYear" INTEGER NOT NULL,
    "examDate" TIMESTAMP(3),
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Track_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subject" (
    "id" TEXT NOT NULL,
    "trackId" TEXT NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Subject_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Paper" (
    "id" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "name" VARCHAR(40) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Paper_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Chapter" (
    "id" TEXT NOT NULL,
    "paperId" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "examWeight" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "masteryPassPercent" INTEGER NOT NULL DEFAULT 70,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Chapter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Topic" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Topic_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TopicProgress" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "topicId" TEXT NOT NULL,
    "readDone" BOOLEAN NOT NULL DEFAULT false,
    "lectureDone" BOOLEAN NOT NULL DEFAULT false,
    "solvedDone" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "clientUpdatedAt" TIMESTAMP(3),

    CONSTRAINT "TopicProgress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChapterMastery" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "status" "MasteryStatus" NOT NULL DEFAULT 'NOT_STARTED',
    "markedCompleteAt" TIMESTAMP(3),
    "masteredAt" TIMESTAMP(3),

    CONSTRAINT "ChapterMastery_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Quiz" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL DEFAULT 'Validation quiz',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Quiz_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "QuizQuestion" (
    "id" TEXT NOT NULL,
    "quizId" TEXT NOT NULL,
    "questionText" TEXT NOT NULL,
    "options" JSONB NOT NULL,
    "correctIndex" INTEGER NOT NULL,
    "explanation" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "QuizQuestion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "QuizAttempt" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "quizId" TEXT NOT NULL,
    "chapterMasteryId" TEXT,
    "context" "QuizContext" NOT NULL DEFAULT 'AUTO_VALIDATION',
    "score" INTEGER NOT NULL,
    "totalQuestions" INTEGER NOT NULL,
    "answers" JSONB NOT NULL,
    "attemptedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "QuizAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChapterPlaylist" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "youtubeUrl" VARCHAR(255) NOT NULL,
    "addedByUserId" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChapterPlaylist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlaylistReview" (
    "id" TEXT NOT NULL,
    "playlistId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlaylistReview_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChapterSpecialVideo" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "tag" "SpecialVideoTag" NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "url" VARCHAR(255) NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "addedByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChapterSpecialVideo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentNote" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "fileUrl" VARCHAR(255) NOT NULL,
    "isPublic" BOOLEAN NOT NULL DEFAULT false,
    "moderationStatus" "NoteModerationStatus" NOT NULL DEFAULT 'PENDING',
    "moderatedByUserId" TEXT,
    "pointsAwarded" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudentNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OfficialNote" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "fileUrl" VARCHAR(255) NOT NULL,
    "accessType" "AccessType" NOT NULL DEFAULT 'SUBSCRIPTION',
    "order" INTEGER NOT NULL DEFAULT 0,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "createdByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OfficialNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Resource" (
    "id" TEXT NOT NULL,
    "topicId" TEXT NOT NULL,
    "kind" "ResourceKind" NOT NULL,
    "videoType" "VideoType",
    "title" VARCHAR(160) NOT NULL,
    "url" VARCHAR(255),
    "body" TEXT,
    "instructorName" VARCHAR(120),
    "durationMinutes" INTEGER,
    "accessType" "AccessType" NOT NULL DEFAULT 'FREE',
    "paidBatchId" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "addedByAdminId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Resource_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaidBatch" (
    "id" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "description" TEXT,
    "priceCents" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaidBatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Purchase" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "paidBatchId" TEXT NOT NULL,
    "amountPaidCents" INTEGER NOT NULL,
    "paymentReference" VARCHAR(160),
    "purchasedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Purchase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Plan" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "priceCents" INTEGER NOT NULL,
    "interval" VARCHAR(20) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Plan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "planId" TEXT,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'TRIALING',
    "currentPeriodEnd" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExternalExam" (
    "id" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "topicId" TEXT,
    "title" VARCHAR(160) NOT NULL,
    "externalUrl" VARCHAR(255) NOT NULL,
    "provider" VARCHAR(80) NOT NULL,
    "accessType" "AccessType" NOT NULL DEFAULT 'FREE',
    "scheduledAt" TIMESTAMP(3) NOT NULL,
    "maxMarks" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExternalExam_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExamResult" (
    "id" TEXT NOT NULL,
    "examId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "phoneNumberUsed" VARCHAR(20) NOT NULL,
    "marksObtained" DOUBLE PRECISION,
    "breakdown" JSONB,
    "status" "ExamResultStatus" NOT NULL DEFAULT 'PENDING',
    "rawPayload" JSONB,
    "fetchedAt" TIMESTAMP(3),
    "reconciledByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExamResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudySession" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "subjectId" TEXT,
    "chapterId" TEXT,
    "type" "SessionType" NOT NULL DEFAULT 'POMODORO',
    "status" "StudySessionStatus" NOT NULL DEFAULT 'ACTIVE',
    "startedAt" TIMESTAMP(3) NOT NULL,
    "lastHeartbeatAt" TIMESTAMP(3),
    "endedAt" TIMESTAMP(3),
    "durationSeconds" INTEGER,

    CONSTRAINT "StudySession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudyRoutine" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "title" VARCHAR(120) NOT NULL DEFAULT 'My routine',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudyRoutine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudyRoutineItem" (
    "id" TEXT NOT NULL,
    "routineId" TEXT NOT NULL,
    "dayOfWeek" INTEGER NOT NULL,
    "startMinute" INTEGER NOT NULL,
    "endMinute" INTEGER NOT NULL,
    "subjectId" TEXT,
    "label" VARCHAR(160),

    CONSTRAINT "StudyRoutineItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TodoItem" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "dueDate" TIMESTAMP(3),
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "sourceType" "TodoSourceType" NOT NULL DEFAULT 'MANUAL',
    "linkedChapterId" TEXT,
    "linkedExamId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TodoItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PointTransaction" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "points" INTEGER NOT NULL,
    "reason" "PointReason" NOT NULL,
    "referenceId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PointTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LevelThreshold" (
    "level" INTEGER NOT NULL,
    "minPoints" INTEGER NOT NULL,
    "title" VARCHAR(60),

    CONSTRAINT "LevelThreshold_pkey" PRIMARY KEY ("level")
);

-- CreateTable
CREATE TABLE "PointRule" (
    "id" TEXT NOT NULL,
    "reason" "PointReason" NOT NULL,
    "scoringMode" "ScoringMode" NOT NULL DEFAULT 'FLAT',
    "value" DOUBLE PRECISION NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PointRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LeaderboardSnapshot" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "trackId" TEXT NOT NULL,
    "metric" "LeaderboardMetric" NOT NULL,
    "period" "LeaderboardPeriod" NOT NULL,
    "periodKey" TEXT NOT NULL,
    "value" INTEGER NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LeaderboardSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "body" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "scheduledFor" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "adminId" TEXT NOT NULL,
    "action" VARCHAR(80) NOT NULL,
    "entityType" VARCHAR(40) NOT NULL,
    "entityId" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_sessionToken_key" ON "Session"("sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON "VerificationToken"("identifier", "token");

-- CreateIndex
CREATE INDEX "EmailOtp_email_purpose_idx" ON "EmailOtp"("email", "purpose");

-- CreateIndex
CREATE UNIQUE INDEX "StudentProfile_userId_key" ON "StudentProfile"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "StudentProfile_phoneNumber_key" ON "StudentProfile"("phoneNumber");

-- CreateIndex
CREATE INDEX "StudentProfile_trackId_totalPoints_idx" ON "StudentProfile"("trackId", "totalPoints");

-- CreateIndex
CREATE UNIQUE INDEX "Track_level_group_batchYear_key" ON "Track"("level", "group", "batchYear");

-- CreateIndex
CREATE UNIQUE INDEX "Subject_trackId_name_key" ON "Subject"("trackId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Paper_subjectId_name_key" ON "Paper"("subjectId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Chapter_paperId_name_key" ON "Chapter"("paperId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Topic_chapterId_name_key" ON "Topic"("chapterId", "name");

-- CreateIndex
CREATE INDEX "TopicProgress_topicId_idx" ON "TopicProgress"("topicId");

-- CreateIndex
CREATE UNIQUE INDEX "TopicProgress_studentId_topicId_key" ON "TopicProgress"("studentId", "topicId");

-- CreateIndex
CREATE INDEX "ChapterMastery_chapterId_status_idx" ON "ChapterMastery"("chapterId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "ChapterMastery_studentId_chapterId_key" ON "ChapterMastery"("studentId", "chapterId");

-- CreateIndex
CREATE INDEX "QuizAttempt_studentId_idx" ON "QuizAttempt"("studentId");

-- CreateIndex
CREATE INDEX "QuizAttempt_quizId_idx" ON "QuizAttempt"("quizId");

-- CreateIndex
CREATE INDEX "ChapterPlaylist_chapterId_idx" ON "ChapterPlaylist"("chapterId");

-- CreateIndex
CREATE INDEX "PlaylistReview_playlistId_idx" ON "PlaylistReview"("playlistId");

-- CreateIndex
CREATE UNIQUE INDEX "PlaylistReview_playlistId_studentId_key" ON "PlaylistReview"("playlistId", "studentId");

-- CreateIndex
CREATE INDEX "ChapterSpecialVideo_chapterId_tag_idx" ON "ChapterSpecialVideo"("chapterId", "tag");

-- CreateIndex
CREATE INDEX "StudentNote_chapterId_isPublic_moderationStatus_idx" ON "StudentNote"("chapterId", "isPublic", "moderationStatus");

-- CreateIndex
CREATE INDEX "StudentNote_studentId_idx" ON "StudentNote"("studentId");

-- CreateIndex
CREATE INDEX "OfficialNote_chapterId_idx" ON "OfficialNote"("chapterId");

-- CreateIndex
CREATE INDEX "Resource_topicId_kind_idx" ON "Resource"("topicId", "kind");

-- CreateIndex
CREATE INDEX "Resource_paidBatchId_idx" ON "Resource"("paidBatchId");

-- CreateIndex
CREATE INDEX "Purchase_paidBatchId_idx" ON "Purchase"("paidBatchId");

-- CreateIndex
CREATE UNIQUE INDEX "Purchase_userId_paidBatchId_key" ON "Purchase"("userId", "paidBatchId");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_userId_key" ON "Subscription"("userId");

-- CreateIndex
CREATE INDEX "ExternalExam_chapterId_idx" ON "ExternalExam"("chapterId");

-- CreateIndex
CREATE INDEX "ExternalExam_topicId_idx" ON "ExternalExam"("topicId");

-- CreateIndex
CREATE INDEX "ExamResult_studentId_idx" ON "ExamResult"("studentId");

-- CreateIndex
CREATE INDEX "ExamResult_status_idx" ON "ExamResult"("status");

-- CreateIndex
CREATE UNIQUE INDEX "ExamResult_examId_studentId_key" ON "ExamResult"("examId", "studentId");

-- CreateIndex
CREATE INDEX "StudySession_studentId_startedAt_idx" ON "StudySession"("studentId", "startedAt");

-- CreateIndex
CREATE INDEX "StudySession_status_lastHeartbeatAt_idx" ON "StudySession"("status", "lastHeartbeatAt");

-- CreateIndex
CREATE INDEX "StudyRoutine_studentId_isActive_idx" ON "StudyRoutine"("studentId", "isActive");

-- CreateIndex
CREATE INDEX "StudyRoutineItem_routineId_dayOfWeek_idx" ON "StudyRoutineItem"("routineId", "dayOfWeek");

-- CreateIndex
CREATE INDEX "TodoItem_studentId_completed_idx" ON "TodoItem"("studentId", "completed");

-- CreateIndex
CREATE INDEX "PointTransaction_studentId_createdAt_idx" ON "PointTransaction"("studentId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "LevelThreshold_minPoints_key" ON "LevelThreshold"("minPoints");

-- CreateIndex
CREATE UNIQUE INDEX "PointRule_reason_key" ON "PointRule"("reason");

-- CreateIndex
CREATE INDEX "LeaderboardSnapshot_trackId_metric_period_periodKey_value_idx" ON "LeaderboardSnapshot"("trackId", "metric", "period", "periodKey", "value");

-- CreateIndex
CREATE UNIQUE INDEX "LeaderboardSnapshot_studentId_metric_period_periodKey_key" ON "LeaderboardSnapshot"("studentId", "metric", "period", "periodKey");

-- CreateIndex
CREATE INDEX "Notification_userId_isRead_idx" ON "Notification"("userId", "isRead");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "AuditLog"("entityType", "entityId");

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_trackId_fkey" FOREIGN KEY ("trackId") REFERENCES "Track"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_trackId_fkey" FOREIGN KEY ("trackId") REFERENCES "Track"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Paper" ADD CONSTRAINT "Paper_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Chapter" ADD CONSTRAINT "Chapter_paperId_fkey" FOREIGN KEY ("paperId") REFERENCES "Paper"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Topic" ADD CONSTRAINT "Topic_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TopicProgress" ADD CONSTRAINT "TopicProgress_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TopicProgress" ADD CONSTRAINT "TopicProgress_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChapterMastery" ADD CONSTRAINT "ChapterMastery_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChapterMastery" ADD CONSTRAINT "ChapterMastery_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Quiz" ADD CONSTRAINT "Quiz_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuizQuestion" ADD CONSTRAINT "QuizQuestion_quizId_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuizAttempt" ADD CONSTRAINT "QuizAttempt_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuizAttempt" ADD CONSTRAINT "QuizAttempt_quizId_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuizAttempt" ADD CONSTRAINT "QuizAttempt_chapterMasteryId_fkey" FOREIGN KEY ("chapterMasteryId") REFERENCES "ChapterMastery"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChapterPlaylist" ADD CONSTRAINT "ChapterPlaylist_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaylistReview" ADD CONSTRAINT "PlaylistReview_playlistId_fkey" FOREIGN KEY ("playlistId") REFERENCES "ChapterPlaylist"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaylistReview" ADD CONSTRAINT "PlaylistReview_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChapterSpecialVideo" ADD CONSTRAINT "ChapterSpecialVideo_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNote" ADD CONSTRAINT "StudentNote_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentNote" ADD CONSTRAINT "StudentNote_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OfficialNote" ADD CONSTRAINT "OfficialNote_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Resource" ADD CONSTRAINT "Resource_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Resource" ADD CONSTRAINT "Resource_paidBatchId_fkey" FOREIGN KEY ("paidBatchId") REFERENCES "PaidBatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_paidBatchId_fkey" FOREIGN KEY ("paidBatchId") REFERENCES "PaidBatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_planId_fkey" FOREIGN KEY ("planId") REFERENCES "Plan"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExternalExam" ADD CONSTRAINT "ExternalExam_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExternalExam" ADD CONSTRAINT "ExternalExam_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExamResult" ADD CONSTRAINT "ExamResult_examId_fkey" FOREIGN KEY ("examId") REFERENCES "ExternalExam"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExamResult" ADD CONSTRAINT "ExamResult_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudySession" ADD CONSTRAINT "StudySession_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudyRoutine" ADD CONSTRAINT "StudyRoutine_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudyRoutineItem" ADD CONSTRAINT "StudyRoutineItem_routineId_fkey" FOREIGN KEY ("routineId") REFERENCES "StudyRoutine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudyRoutineItem" ADD CONSTRAINT "StudyRoutineItem_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_linkedChapterId_fkey" FOREIGN KEY ("linkedChapterId") REFERENCES "Chapter"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_linkedExamId_fkey" FOREIGN KEY ("linkedExamId") REFERENCES "ExternalExam"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointTransaction" ADD CONSTRAINT "PointTransaction_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeaderboardSnapshot" ADD CONSTRAINT "LeaderboardSnapshot_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
