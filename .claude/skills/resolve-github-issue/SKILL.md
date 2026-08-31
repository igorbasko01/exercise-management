---
name: resolve-github-issue
description: Resolve one open GitHub issue in this repo end to end — pick it (or take the number given), implement it on a branch, open a PR, and drive its checks green — without asking the user anything. Use when told to resolve, fix, handle, or take on an issue ("resolve #103", "fix the rest timer issue"), and for unattended runs that say only "resolve an open issue" or "handle a single issue up to a PR".
---
# Resolve GitHub Issue

Take one issue from open to an open PR, autonomously. Assume nobody is
available to answer questions: never ask, decide instead, and write the
decision down in the PR description.

Read `CLAUDE.md` before touching code — its commands, architecture notes and
key patterns are binding here.

## 1. Pick the issue

If an issue number was given, use it. Otherwise choose one:

- List open issues. Skip any that already have an open PR referencing them, an
  existing remote branch for them, or a label marking them blocked or still
  under discussion.
- Among the rest, take the one that is smallest and most fully specified — an
  explicit **Scope** or **Acceptance criteria** section counts for a lot.
  Tie-break by oldest.
- If nothing qualifies, report that and stop. Never invent work.

Read the issue body **and all of its comments** before planning anything; the
comments often carry the decisions the body is missing.

## 2. GitHub access

Use whatever exists in the environment, in this order:

1. The GitHub MCP tools (`list_issues`, `issue_read`, `create_pull_request`,
   `pull_request_read`, `actions_list`, `get_job_logs`, `add_issue_comment`, …).
2. The `gh` CLI, if it is installed.

Do not install either. Claude Code web sessions have MCP only — `gh` is absent
there — so never make `gh` the assumed path.

## 3. Branch

Fetch and branch off the latest `origin/main` as `issue-<N>-<short-slug>`.
Never commit to `main`.

## 4. Implement

- Do exactly the issue's stated scope. No drive-by refactors, no adjacent
  issues, nothing the issue lists as out of scope.
- Where the issue leaves a question open ("decisions worth making", "worth
  deciding while doing it"), pick the option that is smallest and most
  consistent with the existing code, and record the choice and the reasoning in
  the PR description.
- Follow the existing three-layer architecture: framework-agnostic logic in
  `lib/core`, models/repositories/schema in `lib/data`, pages, view models and
  widgets in `lib/presentation`, and dependency wiring in the `MultiProvider` in
  `lib/main.dart`. Depend on the abstract repository interfaces, never on a
  concrete `sqflite_*` implementation.
- Keep logic out of widgets. Business rules, progression algorithms, statistics
  and persistence belong in `core/`, `data/` or a view model, so they can be
  unit-tested without the widget tree.
- Honour the key patterns: `Result`/`Ok`/`Error` across boundaries with
  exhaustive `switch`, `Command0`/`Command1` fields for view-model actions
  (removing listeners and disposing them in `dispose()`), models with
  `copyWith`/`toMap`/`fromMap` and value equality, enums in `core/enums/` with
  behaviour in extensions.
- A new repository means both implementations: `sqflite_*` and `in_memory_*`.
- Schema changes go through migrations: bump `latestVersion` and add an entry to
  `upgradeSteps` in `data/database/exercise_database_migrations.dart`, keyed by
  the target version, and update
  `exercise_database_creation.dart` so fresh installs match. Never edit an
  existing migration step.
- Match surrounding style, and keep comments to what the code cannot say itself.
- Cover the acceptance criteria with tests, mirroring `lib/` under `test/`
  (`test/unit/...`, `test/widget/...`). Prefer the `in_memory_*` repositories
  or `mocktail` mocks over real stores; use `sqflite_common_ffi` for DB tests
  and `fake_async`/`clock` for time-dependent logic. Widget tests wrap the page
  in a `ChangeNotifierProvider` supplying a mocked view model.
- Once the change is written, run the **prune-comments** skill
  (`Skill(prune-comments)`) over the diff and apply its edits, so every comment
  you added or touched matches the repo's house style before you commit.

If the issue turns out to be far larger than it reads, already fixed on `main`,
or resting on a wrong premise: stop, comment on the issue with what you found,
and open no PR.

## 5. Verify without installing anything

- Flutter already on `PATH` → run `flutter pub get`, then `flutter analyze` and
  `flutter test`, fix what they catch, repeat until both are green.
- Flutter absent → **do not install it.** The toolchain is heavy and the
  download is unreliable in a sandbox. Keep the diff small and self-reviewed,
  and let the `flutter-checks.yml` checks on the PR do the verifying.

Either way, say which of the two happened in the PR description.

## 6. Commit and open the PR

This repo uses **Conventional Commits**, and release-please computes the next
version in `pubspec.yaml` and `CHANGELOG.md` from the squashed PR subject — so a
non-conforming title breaks versioning, and the prefix must reflect what the
change actually does (`fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`,
with optional scopes like `feat(timer):`). Never hand-edit the version or the
changelog.

- Commit as `<type>: <what changed> (#<N>)`.
- Push the branch and open a PR against `main` with the same `<type>:` prefix in
  the title.
- PR body: what changed, how each acceptance criterion is met, every assumption
  or decision made along the way, how it was verified (locally or deferred to
  CI), and `Closes #<N>`.

## 7. Drive the checks green

Subscribe to the PR's activity if a subscription mechanism exists
(`subscribe_pr_activity` or equivalent); skip silently if not.

While a check fails: read the failing job's logs, fix the cause, push, look
again. Never skip, disable or delete a test to get green, and never push an
empty commit to re-trigger CI. After 5 failed rounds, stop pushing and comment
on the PR with what still fails and why.

## 8. Hand the PR to a fresh reviewer

Once the checks are green, get a second pair of eyes on the PR before a human
sees it. You have just spent a whole session convincing yourself this code is
correct, which is exactly the wrong state of mind to review it from — so the
review goes to an agent that starts cold.

Spawn a subagent with the `Agent` tool and give it nothing but the target:

> Review pull request #`<PR>` in `igorbasko01/exercise-management` using the
> `code-review` skill. Post your findings as a comment on the PR. Do not push
> commits, approve, or merge.

Do not brief it on the issue, your reasoning, or which parts you think are
fine — the value of the review is that it re-derives all of that from the diff.

When it reports back: fix defects that are real and inside the issue's scope,
push, and let the checks re-run. Everything else — larger refactors, findings
about code the PR did not touch, suggestions you disagree with — stays as the
reviewer's comment for the human to weigh. Do not widen the PR to chase them,
and do not delete or resolve the comment.

If no subagent mechanism exists in the environment, run the `code-review` skill
yourself as a deliberate second read, and say in your final report that the
review was not independent.

## 9. Stop

One issue, one PR. Report the PR link, the issue it closes, a short summary of
the change and how it was verified, and what the review turned up. Leave the PR
for human review — never merge it, and never close the issue by hand
(`Closes #<N>` does that on merge).
