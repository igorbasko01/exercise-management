# Supabase Integration Feasibility Analysis

This document outlines the feasibility and steps required to integrate Supabase into the Exercise Management app. The goal is to transition from a purely local, single-user application to a cloud-backed, multi-user application while retaining the "local-first" architecture using SQLite as the primary data source.

## 1. Authentication (Prerequisite)

Before syncing data to a cloud backend for multiple users, user authentication is a strict requirement. Without it, Supabase cannot distinguish between different users' data, meaning row-level security (RLS) cannot be enforced, and data privacy cannot be maintained.

### Proposed Approach
- **Supabase Auth:** Integrate the `supabase_flutter` package to handle authentication (email/password, OAuth, etc.).
- **Offline Access:** Since the app is local-first, users should not be blocked from using the app if they are offline.
    - If a user has previously logged in, their session token can be cached locally.
    - If they open the app offline, they continue using the local SQLite database.
    - A "Guest Mode" could be retained for users who do not want to create an account, keeping their data strictly on the device.

## 2. Local-First Architecture with Supabase

The core philosophy is that the app reads from and writes to the local SQLite database *first*, ensuring immediate UI updates and offline availability. Supabase acts as a secondary backup and sync layer.

### Implementation Strategy

1.  **Database Schema Alignment:**
    - The Supabase schema must mirror the SQLite schema (e.g., `exercise_templates`, `exercise_sets`, `exercise_programs`, etc.).
    - Every table in Supabase needs a `user_id` column to associate records with the authenticated user.
    - Every table needs a `last_updated_at` timestamp column to handle conflict resolution.
    - Every table needs a stable string UUID identifier. We should use UUID v4 (using the Dart `uuid` package) generated on the client device when a record is created. Because UUID v4 is highly random, it guarantees that an ID generated offline on Device A will not collide with an ID generated on Device B.
    - Every table needs a `deleted_at` timestamp or `is_deleted` boolean column to support "soft deletes" (see below).

2.  **Sync Mechanism & Status:**
    - **Writes (Local -> Remote):** When a repository writes to SQLite, it updates the local record. To track sync state, we should add a `sync_status` column (e.g., 'synced', 'pending_insert', 'pending_update', 'pending_delete') to the SQLite tables. A background worker will look for 'pending' records and push them to Supabase, updating the status to 'synced' upon success.
    - **Deletes:** In an offline-first app, you cannot permanently delete a row locally if it hasn't synced yet, otherwise the sync engine won't know to tell Supabase to delete it. Instead, we perform a "soft delete" by setting `deleted_at = NOW()` locally and marking `sync_status = 'pending_delete'`. The sync engine pushes this soft delete to Supabase. Local queries must be updated to filter out records where `deleted_at IS NOT NULL`.
    - **Reads (Remote -> Local):** When the app comes online, it can poll Supabase for records where `last_updated_at` is greater than the last local sync timestamp, pulling those changes into SQLite.

3.  **Conflict Resolution:**
    - In an offline-first app, a user might edit the same record on two different devices while offline. When both connect, a conflict occurs.
    - A simple and effective strategy is "Last Write Wins" (LWW), relying on the `last_updated_at` timestamp.

## 3. Feasibility & Complexity

### Current Architecture Assessment
The current app architecture makes this integration highly feasible and relatively clean.
- **Repository Pattern:** The app already uses the Repository pattern (e.g., `ExerciseTemplateRepository`, `ExerciseSetRepository`) with explicit interfaces. Currently, these are implemented by SQLite-specific classes (e.g., `SqfliteExerciseTemplateRepository`).
- **Dependency Injection:** The use of `Provider` for dependency injection means we can swap out or augment the repository implementations without changing the UI or ViewModels.

### How to adapt the Repositories
Instead of replacing the SQLite repositories, we can use the **Decorator Pattern** or create a **Syncing Repository** that wraps both local and remote data sources.

Example structure:
```dart
class SyncingExerciseTemplateRepository implements ExerciseTemplateRepository {
  final SqfliteExerciseTemplateRepository localDb;
  final SupabaseClient remoteDb;

  // Implementation overrides:
  // 1. Write to localDb and set sync_status to pending
  // 2. Attempt to write to remoteDb (or let a background worker do it)
  // 3. Return localDb result
}
```

### Steps to Implement

1. **UUID Migration:** Create a database migration script within the app (e.g., in `DatabaseMigrations`). The script will: add new string columns for IDs, generate a v4 UUID for every existing record, update all foreign key references to use the new UUIDs, and finally drop the old integer ID columns.
2. **Setup Supabase Project:** This happens outside the app. You will use the Supabase web dashboard or Supabase CLI to create the project, define the tables mirroring SQLite, add `user_id`, and configure Row Level Security (RLS).
3. **Add Dependencies:** Add `supabase_flutter` and `uuid` to `pubspec.yaml`.
4. **Implement Authentication:** Create login/signup flows and manage the user session.
5. **Update Local Schema:** Update the SQLite schema via a migration script to add `sync_status`, `last_updated_at`, and `deleted_at`. Update all repository read queries to ignore soft-deleted records.
6. **Create Sync Logic:** Develop the background syncing engine to push pending changes and pull remote updates.

### Conclusion

Connecting the current architecture to Supabase while maintaining a local-first approach is **highly feasible**. The existing use of the Repository pattern provides the perfect foundation. The primary complexities will be migrating the database primary keys to UUIDs, implementing soft deletes, and building the bidirectional sync engine. A `user_id` is absolutely crucial for this to work, as Supabase requires it to enforce Row Level Security and ensure users only sync and access their own data.
