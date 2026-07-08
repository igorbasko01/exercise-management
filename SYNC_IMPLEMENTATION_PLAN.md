# Supabase Sync — Implementation Plan

**Status:** planning only. This document captures the design decisions and the
incremental roadmap for adding cloud sync. Implementation will land later as a
series of small, focused PRs (one step at a time).

**First-pass reference (code to mine, not the plan):** an earlier all-in-one
attempt was built and then set aside for being too large (~3,000 lines in one
PR). Its code is preserved in git history at commit `99bde79` (and its
ancestors), reachable via the commit list of PR #78. Useful for lifting
interface shapes and tests; the plan below supersedes its structure.

Companion analysis: [`SUPABASE_ANALYSIS.md`](SUPABASE_ANALYSIS.md).

---

## Design decisions (agreed)

1. **Local-first.** The app always reads/writes local SQLite first and stays
   fully usable offline and **unauthenticated**. Supabase is a secondary
   backup/sync layer.

2. **Timestamp-only, Last-Write-Wins.** Each synced row carries two UTC columns,
   `updated_at` and `deleted_at`, plus `user_id`. There is **no** per-record
   `sync_status` enum and **no** server sequence.
   - "Needs pushing" is derived: `updated_at` newer than the table's last-synced
     watermark ⇒ push it.
   - Conflicts resolve by whichever `updated_at` is greater.
   - This keeps the local and remote schemas **identical** and makes updates
     first-class (an update is just a bumped `updated_at`, same as an insert).

3. **Soft deletes.** Delete = set `deleted_at` (+ bump `updated_at`); reads
   filter `deleted_at IS NULL`. Required so a deletion made offline still
   propagates instead of vanishing. (`clearAll`, used by data import, stays a
   hard delete — it's a local reset.)

4. **Client-generated UUID identity.** Records are identified by a UUID v4
   generated on-device, so rows created offline on different devices never
   collide. See step 2 of the roadmap.

5. **One watermark per synced table.** A single `lastSyncedAt` per table drives
   both push and pull (stored locally, e.g. a `sync_state` table). It is not
   needed for correctness (you could full-sync every time) — it's the
   incremental-sync optimisation so you don't re-transfer the whole history.

6. **Auth is a prerequisite for sync, but optional for the app.** Sync only runs
   when a user is signed in AND the sync toggle is on. The toggle defaults to
   **off** — even a signed-in user opts in explicitly.

7. **Programs are deferred.** When tackled, model `exercise_programs` as an
   **aggregate root** that carries its sessions and each session's *ordered list
   of exercise-template UUID references* inside its own sync payload.
   `exercise_program_sessions` and `session_exercises` are **not** synced tables
   of their own (the join table's positional key makes row-level LWW ambiguous).

8. **First synced slice = `exercise_templates` + `exercise_sets`.** A
   self-contained subgraph: sets reference templates; nothing references
   programs.

---

## Roadmap (small, ordered, each its own PR)

### Step 1 — Auth + Auth UI
Login / register / sign-out screens, session handling, an optional "Sign in"
entry point in Settings. The app must remain fully usable when signed out.
- Built against an `AuthService` interface, backed by an in-memory
  implementation for now (swap in a `SupabaseAuthService` later).
- **Caveat:** *real* accounts need Supabase Auth (`supabase_flutter` package +
  a Supabase project created via dashboard/CLI). Until that exists, the flow can
  only be proven against the local fake, not the cloud. Only the backend class
  swaps.

### Step 2 — Local UUID primary keys (no sync yet)
Migrate `exercise_templates` and `exercise_sets` from integer autoincrement PKs
to client-generated UUID (TEXT) PKs; remap the foreign keys in `exercise_sets`
and `session_exercises`. App behaviour is unchanged — "ids are just UUIDs now."
- Doing this in isolation removes the need for any uuid↔integer translation in
  the later sync layer (the local id *is* the portable id).
- Known ripples to handle here: `SqfliteExerciseStatisticsRepository` casts
  `exercise_template_id as int`; `SqfliteExerciseSetPresentationRepository`
  orders by `es.id` for recency (switch to `date_time`).
- Mechanics: SQLite can't change a PK in place — rebuild the tables
  (create-new / copy-with-generated-uuids / drop-old / rename), mindful that
  `PRAGMA foreign_keys` can't be toggled inside sqflite's migration transaction.

### Step 3 — Sync engine + local store
The timestamp/LWW engine over the real tables (add `user_id` / `updated_at` /
`deleted_at` columns + a `sync_state` watermark table; soft-delete in repos).
With step 2 done, the SQLite store needs no FK translation. Remote is still an
in-memory fake. Suggested seams (interfaces): `RemoteDataSource`,
`LocalSyncStore`, `ConflictResolver`, `SyncService`.

### Step 4 — Turn it on
The Settings toggle actually drives `synchronize`. Then, as separate work: a
concrete `SupabaseRemoteDataSource`, the Supabase project + mirrored schema +
Row Level Security, and background scheduling.

---

## Deferred / requires external setup
- Concrete `SupabaseRemoteDataSource` / `SupabaseAuthService` on
  `supabase_flutter`; the Supabase project, mirrored tables and RLS policies.
- On Postgres, stamp `updated_at` in the database (`default now()` + an update
  trigger) so the sync cursor is immune to client clock skew.
- Background scheduling of sync (e.g. `workmanager`).
- Program sync (see decision 7).
