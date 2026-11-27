import "server-only";
import type { EducationLevel, GroupType, MasteryStatus } from "@/generated/prisma/enums";
import { goFetch, GoUnavailableError, toDate } from "@/lib/go-api";
import { buildTopicProgressMap } from "@/lib/progress";
import type { ChapterMasteryLite, StudentDashboardData } from "@/lib/student-data";

type GoChapter = {
  id: string;
  paperId: string;
  name: string;
  order: number;
  examWeight: number;
  masteryPassPercent: number;
  isFreePreview: boolean;
  isArchived: boolean;
  topics: { id: string }[];
};

type GoTrack = {
  id: string;
  name: string;
  level: EducationLevel;
  group: GroupType;
  batchYear: number;
  examDate: string | null;
  isArchived: boolean;
  createdAt: string;
  subjects: {
    id: string;
    trackId: string;
    name: string;
    order: number;
    isArchived: boolean;
    papers: {
      id: string;
      subjectId: string;
      name: string;
      order: number;
      isArchived: boolean;
      chapters: GoChapter[];
    }[];
  }[];
};

type GoDashboardBody = {
  track: GoTrack | null;
  topicProgress: {
    topicId: string;
    readDone: boolean;
    lectureDone: boolean;
    solvedDone: boolean;
  }[];
  chapterMasteries: {
    chapterId: string;
    status: MasteryStatus;
    markedCompleteAt: string | null;
    masteredAt: string | null;
  }[];
};

export async function getStudentDashboardDataViaGo(
  trackId: string,
  studentId: string | null
): Promise<StudentDashboardData> {
  const { body } = await goFetch<GoDashboardBody>("/student/dashboard", {
    query: { trackId, studentId },
  });

  if (!body.success) {
    throw new GoUnavailableError(`dashboard read failed: ${body.error ?? "unknown error"}`);
  }

  const track = body.track
    ? {
        ...body.track,
        examDate: toDate(body.track.examDate),
        createdAt: toDate(body.track.createdAt),
      }
    : null;

  const chapterMasteryByChapterId = new Map<string, ChapterMasteryLite>();
  for (const row of body.chapterMasteries ?? []) {
    chapterMasteryByChapterId.set(row.chapterId, {
      status: row.status,
      markedCompleteAt: toDate(row.markedCompleteAt),
      masteredAt: toDate(row.masteredAt),
    });
  }

  return {
    track,
    topicProgressByTopicId: buildTopicProgressMap(body.topicProgress ?? []),
    chapterMasteryByChapterId,
  };
}
