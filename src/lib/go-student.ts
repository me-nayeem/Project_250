import "server-only";
import type { Board, EducationLevel, GroupType } from "@/generated/prisma/enums";
import { goFetch } from "@/lib/go-api";

export type OnboardingOutcome = { done: true } | { done: false; error: string };

export async function completeOnboardingViaGo(input: {
  userId: string;
  level: EducationLevel;
  group: GroupType;
  board?: Board;
  institutionName: string;
  phoneNumber: string;
}): Promise<OnboardingOutcome> {
  const { body } = await goFetch("/student/onboarding", { method: "POST", body: input });
  return body.success
    ? { done: true }
    : { done: false, error: body.error ?? "Something went wrong. Please try again." };
}
