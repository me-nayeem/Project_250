"use server";

import { redirect } from "next/navigation";
import { requireUser } from "@/lib/dal";
import { prisma } from "@/lib/prisma";
import { formValue } from "@/lib/form-data";
import { OnboardingSchema, type OnboardingInput } from "@/schemas/onboarding";
import { matchTrackForLevelGroup } from "@/lib/track-matching";
import { withGoFallback } from "@/lib/go-api";
import { completeOnboardingViaGo, type OnboardingOutcome } from "@/lib/go-student";
import { fieldErrorState, handlePrismaError, type ActionState } from "@/lib/prisma-errors";

export async function completeOnboarding(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const user = await requireUser();

  const parsed = OnboardingSchema.safeParse({
    level: formValue(formData, "level"),
    group: formValue(formData, "group"),
    board: formValue(formData, "board"),
    institutionName: formValue(formData, "institutionName"),
    phoneNumber: formValue(formData, "phoneNumber"),
  });

  if (!parsed.success) {
    const existing = await prisma.studentProfile.findUnique({
      where: { userId: user.id },
      select: { id: true },
    });
    if (existing) redirect("/dashboard");
    return fieldErrorState(parsed.error);
  }

  const outcome = await withGoFallback(
    "completeOnboarding",
    () => completeOnboardingViaGo({ userId: user.id, ...parsed.data }),
    () => completeOnboardingWithPrisma(user.id, parsed.data)
  );

  if (!outcome.done) {
    return { success: false, error: outcome.error };
  }
  redirect("/dashboard");
}

async function completeOnboardingWithPrisma(
  userId: string,
  data: OnboardingInput
): Promise<OnboardingOutcome> {
  const existing = await prisma.studentProfile.findUnique({
    where: { userId },
    select: { id: true },
  });
  if (existing) return { done: true };

  const { level, group, board, institutionName, phoneNumber } = data;

  const match = await matchTrackForLevelGroup(level, group);
  if (!match.found) {
    return {
      done: false,
      error: "No track is available yet for this level and group. Please contact support.",
    };
  }

  try {
    await prisma.studentProfile.create({
      data: {
        userId,
        trackId: match.trackId,
        board,
        institutionName,
        phoneNumber,
      },
    });
  } catch (err) {
    const state = handlePrismaError(err, "student profile");
    return { done: false, error: state.error ?? "Something went wrong. Please try again." };
  }

  return { done: true };
}
