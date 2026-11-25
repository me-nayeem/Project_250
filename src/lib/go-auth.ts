import "server-only";
import type { Role } from "@/generated/prisma/enums";
import { goFetch } from "@/lib/go-api";

export async function requestOtpViaGo(
  email: string
): Promise<{ success: boolean; message: string }> {
  const { body } = await goFetch<{ message?: string }>("/auth/request-otp", {
    method: "POST",
    body: { email },
    timeoutMs: 20_000,
  });

  if (body.success) {
    return { success: true, message: body.message ?? "Check your email for the code." };
  }
  return { success: false, message: body.error ?? "Something went wrong. Please try again." };
}

export type GoAuthUser = { id: string; email?: string; name?: string; role: Role };

export async function verifyOtpViaGo(email: string, code: string): Promise<GoAuthUser | null> {
  const { body } = await goFetch<{
    user?: { id: string; email: string | null; name: string | null; role: Role } | null;
  }>("/auth/verify-otp", {
    method: "POST",
    body: { email, code },
    timeoutMs: 15_000,
  });

  if (!body.success || !body.user) return null;
  return {
    id: body.user.id,
    email: body.user.email ?? undefined,
    name: body.user.name ?? undefined,
    role: body.user.role,
  };
}
