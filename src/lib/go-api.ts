import "server-only";

const BASE_URL = (process.env.GO_API_BASE_URL ?? "").trim().replace(/\/+$/, "");
const TOKEN = (process.env.GO_INTERNAL_TOKEN ?? "").trim();

export function isGoApiEnabled(): boolean {
  return BASE_URL.length > 0 && TOKEN.length > 0;
}

export class GoUnavailableError extends Error {
  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = "GoUnavailableError";
  }
}

export type GoBody = { success: boolean; error?: string; [key: string]: unknown };

type GoRequest = {
  method?: "GET" | "POST";
  body?: unknown;
  query?: Record<string, string | number | null | undefined>;
  timeoutMs?: number;
};

export async function goFetch<T extends object = Record<string, never>>(
  path: string,
  { method = "GET", body, query, timeoutMs = 8_000 }: GoRequest = {}
): Promise<{ status: number; body: GoBody & T }> {
  if (!isGoApiEnabled()) {
    throw new GoUnavailableError("Go API is not configured");
  }

  const url = new URL(path, `${BASE_URL}/`);
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value !== null && value !== undefined && value !== "") {
      url.searchParams.set(key, String(value));
    }
  }

  let response: Response;
  try {
    response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${TOKEN}`,
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      cache: "no-store",
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (err) {
    throw new GoUnavailableError(`Go API request to ${path} failed`, { cause: err });
  }

  const payload: unknown = await response.json().catch(() => null);
  const isGoBody =
    typeof payload === "object" &&
    payload !== null &&
    typeof (payload as { success?: unknown }).success === "boolean";

  if (!isGoBody) {
    throw new GoUnavailableError(
      `Go API ${path} returned an unusable response (${response.status})`
    );
  }
  if (response.status >= 500) {
    const message = (payload as GoBody).error ?? "unknown error";
    throw new GoUnavailableError(`Go API ${path} failed (${response.status}): ${message}`);
  }

  return { status: response.status, body: payload as GoBody & T };
}

export async function withGoFallback<T>(
  label: string,
  viaGo: () => Promise<T>,
  legacy: () => Promise<T>
): Promise<T> {
  if (!isGoApiEnabled()) return legacy();
  try {
    return await viaGo();
  } catch (err) {
    if (!(err instanceof GoUnavailableError)) throw err;
    console.warn(`[go-api] ${label}: falling back to Prisma — ${err.message}`);
    return legacy();
  }
}

export function toDate(value: string): Date;
export function toDate(value: string | null | undefined): Date | null;
export function toDate(value: string | null | undefined): Date | null {
  return value ? new Date(value) : null;
}
