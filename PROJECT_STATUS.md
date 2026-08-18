# TaskFlow — Current State (as of 2026-08-17)

A snapshot of what's actually built, so you can brainstorm what's next without re-deriving it from the code each time. This is a status report, not a spec — see `PROJECT.md` for the original build guide (note: the app has since diverged from it, see below).

---

## 1. What this app actually is

Flutter + BLoC + Supabase app, Clean Architecture (`domain` / `data` / `presentation`). Originally scoped as a **workspace → kanban board → tasks** app (per `PROJECT.md`), but the data model was refactored mid-build into a **project management** shape:

```
projects (was "tasks")
  └─ project_goals (sub-tasks/checklist items per project)
  └─ project_comments (chat/discussion per project)
  └─ project_invitations (invite people to a project, deep-linked)
```

In the Dart code the naming didn't follow the refactor — `Task`, `TaskBloc`, `TaskRepository` etc. still exist and are the primary abstraction, but under the hood they read/write the `projects` table. So conceptually: **a "Task" in this app is really a Project**, and "Goals" are what most task apps would just call tasks/sub-tasks. Worth deciding if you want to rename for clarity or keep it as-is.

No `workspaces`/`boards`/`columns` tables exist — `workspaceId` is a loose string field with one hardcoded default UUID. There's no multi-workspace switching UI, no workspace admin/member roles.

---

## 2. Feature inventory

| Feature | Status | Notes |
|---|---|---|
| Auth (login/signup) | ✅ Works | One combined screen, no password reset / email verification flow |
| Task(=Project) CRUD | ✅ Works | Create/edit/delete via bottom sheet |
| Kanban drag-and-drop | ✅ Works | Native `Draggable`/`DragTarget`, not a 3-fixed-column board — it's a single reorderable list styled like cards |
| Optimistic update + rollback | ✅ Works, tested | `TaskBloc._onTaskMoved` — verified with a real unit test |
| Realtime sync (Supabase `.stream()`) | ✅ Works | Tasks, goals, comments all live-stream |
| Goals (sub-tasks per project) | ✅ Works | Own bloc, optimistic toggle/delete, realtime |
| Comments (per project) | ✅ Works | Realtime chat-style thread |
| Invitations + deep linking | ✅ Works | `app_links` package (currently undeclared in `pubspec.yaml` — only transitive, fragile) |
| Statistics screen | ✅ Just fixed | Was showing fake numbers — `task.progress` column is never written by the app (stays 0.0 forever). Now derives progress from goal completion, and the weekly bar chart only counts items that are actually done *and* whose date has occurred (no more future-dated "activity") |
| Calendar | 🟡 Partial | Hand-rolled month view, due-date visualization only — no recurring events, no real meeting/scheduling backend |
| Dashboard | ✅ Works | Hero banner still reads the same dead `task.progress` field (same bug as statistics had — not yet fixed there) |
| Bottom nav / tab switching | ✅ Just fixed | Was instant/jarring — now has fade+slide animation; navbar was oversized/badly rounded — now a proper compact pill, responsive to screen width |
| Page transitions (task detail) | ✅ Just fixed | Custom fade+slide `PageRouteBuilder` |
| Dark/light theme | 🟡 Broken | `ThemeCubit` exists and toggles state, but `MaterialApp` in `main.dart` never reads it — toggling currently does nothing visible |
| Status bar icon color | ✅ Just fixed | Was flipping white on the task detail screen due to a transparent `AppBar` with no explicit `systemOverlayStyle` |
| Notifications (push/local) | ❌ Missing | No FCM, no local notifications, no in-app notification center |
| File/image attachments | ❌ Missing | No `image_picker`/`file_picker`, no Supabase Storage usage |
| Search | ❌ Missing | No search bar/index anywhere |
| Offline support | ❌ Missing | No local cache (`hive`/`sqflite`/`drift`), everything requires network |
| Profile/settings | 🟡 Partial | Basic profile display only, no avatar upload, no persisted settings |
| Widget/UI tests | ❌ Missing | Only bloc/usecase unit tests exist (72 passing); zero widget tests for any screen |

---

## 3. Known technical debt

- **`task.progress` is a ghost column.** Defaults to `0.0` in the DB, nothing ever writes to it except a manual edit form that just carries forward the old value. Statistics screen now works around this by deriving progress from goal completion client-side; dashboard hero banner and `task_card.dart` still read the raw dead field.
- **No `completed_at` timestamp** on tasks or goals. The stats bar chart approximates "when did this happen" using `dueDate ?? createdAt`, which is a proxy, not a true completion date. A task finished late still gets attributed to its (past) due date, which is directionally fine but not exact.
- **`TaskDetailBloc` from the original design doc was never built** — the task detail screen instead directly composes `GoalBloc` + `ChatBloc`, which works but isn't what `PROJECT.md` Step 4 called for.
- **`app_links` is imported but not declared in `pubspec.yaml`** — works today only because it's a transitive dependency of something else.
- **Mock data fallback is baked into the datasource layer** (`_mockTasks`, `_mockGoals` in `TaskRemoteDataSourceImpl`) — any Supabase error silently falls back to fake data instead of surfacing the error, which is fine for demos but risks masking real bugs.
- Leftover Flutter template boilerplate (`lib/presentation/counter/`) is still in the codebase, unused.

---

## 4. Recent session work (this conversation)

1. Fixed status bar icons flipping white on the task detail screen (missing `systemOverlayStyle`).
2. Redesigned the floating bottom nav bar — shorter, proper stadium radius, responsive margins.
3. Added animated transitions: fade+slide between bottom-nav tabs, fade+slide when opening task detail.
4. Fixed the calendar's goal-indicator dot rendering through the middle of day numbers (was `Positioned` overlapping the digit; now a reserved `Column` slot below it).
5. Made the statistics screen use real derived data instead of the dead `progress` column.
6. Fixed the weekly productivity bar chart counting future-dated (not-yet-happened) completions.

---

## 5. Things worth brainstorming

Some open forks in the road, not recommendations — just what's undecided:

- **Rename `Task` → `Project` throughout?** The DB already made this leap; the Dart code didn't. Living with the mismatch gets more confusing the bigger this gets.
- **Workspace/team model**: right now it's single-workspace, no membership roles. Is multi-workspace actually a goal, or was that scoped out on purpose when the schema pivoted to "project management"?
- **What is a "Goal" to the end user?** Is it a checklist item, a milestone, or a task-within-a-task? The name is generic enough to mean several things — worth pinning down before adding more features on top of it.
- **Completion tracking**: worth adding a real `completed_at` column if stats/analytics are going to be a focus area — the current date-proxy approach has a ceiling on accuracy.
- **Offline-first vs. always-online**: currently 100% dependent on a live Supabase connection. Is that acceptable for the target use case, or does this need local caching?
- **Notifications**: is this a "check the app" tool or a "the app should nudge me" tool? That decision drives whether push notifications are core or skippable.
