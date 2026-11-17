# Feature: Study Tools (partial)

## Status: infrastructure + streaks live; routine builder & timer UI not shipped

Backend for `StudySession` tracking and the leaderboard/streak systems it
feeds is complete and deployed. The student-facing timer widget, the
`StudyRoutine` builder, and `TodoItem` UI were **not built** — routine
builder was built once, then deliberately shelved behind a "Coming soon"
placeholder before launch. Streak logic was reworked to decouple
entirely from `StudySession`, since the timer feature won't ship yet.

## Schema additions

- `TodoItem.sourceRoutineItemId` (`String?`, `onDelete: SetNull`) + reverse
  relation on `StudyRoutineItem` — lets the nightly routine→todo cron
  upsert idempotently via `@@unique([sourceRoutineItemId, dueDate])`
  instead of fragile text-matching. Currently unused in practice since the
  routine builder isn't live, but the constraint means it's safe the
  moment it is.

## What's live

### `StudySession` timer backend (removed)

The timer Server Actions (`actions/study-sessions.ts`) and the study-time
snapshot helper (`lib/study-time.ts`) were removed because no UI used
them. The `StudySession` model stays in the schema so the timer can be
rebuilt later without a migration.

### Abandon-session handling (Hobby-plan constraint)

Vercel's Hobby plan only allows once-daily cron schedules; a frequent
sweep (e.g. every 4 minutes) fails at deploy time.

- **Daily safety-net cron** (`app/api/cron/abandon-sessions/route.ts`,
  `0 20 * * *` UTC = 2 AM Dhaka): marks stale `ACTIVE` sessions
  (`lastHeartbeatAt` older than 8 minutes) as `ABANDONED`. **Change the
  schedule to `*/4 * * * *` once on Vercel Pro** — no code change needed,
  just the `vercel.json` cadence.
- The definition of "stale" lives in `lib/session-abandon.ts`
  (`isStale()`/`abandonSession()`).

### Streak system — reworked, decoupled from StudySession

**Original design** (streak day = completed `StudySession`) was replaced
mid-feature once the timer/routine features were deferred — a streak tied to
an unlaunched feature would never fire.

**Current design:** streak day = **visiting `/dashboard`**, once per
Dhaka-calendar day.

- `lib/streaks.ts` → `evaluateStreak(tx, studentId, now)` — idempotent per
  day via `StudentProfile.lastActiveAt` (compared via
  `lib/period-key.ts`'s `getDailyKey()`, so repeat visits the same day are
  a silent no-op: `{ awarded: false }`).
- Continuing yesterday's streak → `streakCount += 1`. Any gap → reset to
  `1`. Either way, the _first_ visit of the day awards flat `STREAK_BONUS`
  (1 point, locked in feature 6's `PointRule` seed) via the same
  `awardPoints()` choke point everything else uses.
- Called directly from `app/(student)/(app)/dashboard/page.tsx`, alongside
  the existing dashboard data fetches — no separate endpoint or cron.
- `StreakCelebrationModal` renders **only** when `streakResult.awarded` is
  true (i.e. genuinely the first visit that day) — shows streak count,
  points earned, and a rotating motivational line. Dismissable overlay.
- `StatsHeader` is fed `profile.totalPoints + streakResult.pointsAwarded`
  and `streakResult.streakCount` (not the raw `profile` values), so the
  header never shows a stale number for the render where the award just
  happened.

### `STUDY_TIME` leaderboard

Has a UI shell from feature 6 (empty-state placeholder) and is shown as
"Coming soon". It stays empty until the timer feature is rebuilt and
writes `STUDY_TIME` snapshots (same DAILY/WEEKLY/MONTHLY/ALL_TIME pattern
as `MASTER_SCORE`).

### Nightly routine→todo generation cron

`app/api/cron/generate-routine-todos/route.ts` (`0 18 * * *` UTC =
midnight Dhaka) — fully built, deployed, and **dormant**: since the
routine builder UI was shelved, no `StudyRoutine`/`StudyRoutineItem` rows
exist for any student, so this runs nightly and no-ops (0 candidates,
0 created). Reconnects automatically the moment the routine builder ships
— no code changes needed, just remove the placeholder page.

## What's shelved

- `app/(student)/(app)/routine/page.tsx` — full builder (create routine,
  add/edit/delete time blocks per day, activate/deactivate) was built,
  then replaced with a static "Coming soon" page ahead of launch. Backend
  (`actions/study-routine.ts`, `lib/study-routine-data.ts`,
  `schemas/study-routine.ts`, all routine components) remains in the
  codebase, untouched, ready to swap back in.
- Student-facing study timer widget — not built.
- `TodoItem` UI (manual creation + viewing generated todos) — not built.

## Bugs fixed this feature (unrelated, surfaced during this Feature work)

- `Youtube` icon import from `lucide-react` — not exported in the
  installed version (brand/logo icons generally aren't in this library's
  scope at all, not a version-specific gap). Replaced with a custom
  `YoutubeIcon` SVG component (`components/shared/icons/youtube-icon.tsx`)
  using `currentColor`, drop-in compatible with existing className usage.

## Open items carried forward

- Timer widget UI, `TodoItem` UI — whenever picked back up.
- `StudyRoutine` launch — swap placeholder page back for the real one;
  everything else (actions, cron, schema) is already live and waiting.
- Push notifications for abandoned sessions — explicitly scoped **out**
  of this feature; would need new infrastructure (Web Push + service
  worker, or a third-party push service). Backlog item, not started.
- `vercel.json` `abandon-sessions` cadence — currently once-daily
  (Hobby-plan constraint); tighten to `*/4 * * * *` once on Pro.
