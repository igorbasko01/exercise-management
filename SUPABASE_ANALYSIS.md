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
    - Every table needs to have a stable UUID identifier, which is mostly handled by the current design, though the ID type may need careful mapping (currently some IDs appear to be autoincrement integers which might complicate multi-device sync unless changed to UUID strings).

2.  **Sync Mechanism:**
    - **Writes (Local -> Remote):** When a repository writes to SQLite, it should either immediately attempt to push the change to Supabase (if online) or queue the operation locally to be synced later. A local "sync_queue" table or a boolean flag like `is_synced` on each record can track pending changes.
    - **Reads (Remote -> Local):** When the app comes online, it can poll Supabase for records where `last_updated_at` is greater than the last sync timestamp, pulling those changes into SQLite.

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
  // 1. Write to localDb
  // 2. Attempt to write to remoteDb (or queue it)
  // 3. Return localDb result
}
```

### Steps to Implement

1. **UUID Migration:** Migrate current integer IDs to string UUIDs in SQLite to prevent primary key collisions when syncing across multiple devices.
2. **Setup Supabase Project:** Create the project, setup tables mirroring SQLite, add `user_id` and `last_updated_at`, and configure Row Level Security (RLS).
3. **Add Dependencies:** Add `supabase_flutter` to `pubspec.yaml`.
4. **Implement Authentication:** Create login/signup flows and manage the user session.
5. **Update Local Schema:** Add `is_synced` (or similar tracking mechanism) to the SQLite schema and migrations.
6. **Create Sync Logic:** Develop the syncing engine or update the repositories to handle the dual-write and background sync processes.

### Conclusion

Connecting the current architecture to Supabase while maintaining a local-first approach is **highly feasible**. The existing use of the Repository pattern and Provider for dependency injection provides the perfect foundation. The primary complexities will not be refactoring the UI, but rather migrating the database primary keys to UUIDs and implementing a robust bidirectional sync engine.
