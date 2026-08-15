# TaskFlow — Build Guide: Task Manager (Kanban) Feature

Stack: **Flutter + BLoC + Supabase (Postgres, Auth, Realtime)**
Scope: Minggu 3–4 dari roadmap — CRUD task, drag-drop kanban, real-time sync.

Setiap step punya (1) penjelasan, (2) apa yang harus kamu buat sendiri secara manual biar paham, dan (3) **prompt siap pakai** untuk AI (Claude Code / Claude.ai) supaya generate boilerplate-nya. Pakai prompt itu apa adanya, atau sesuaikan nama package/folder kamu.

---

## Step 0 — Prasyarat

Pastikan sudah ada sebelum mulai:
- Project Flutter kosong dengan struktur MVVM
- Supabase project sudah dibuat, `SUPABASE_URL` dan `SUPABASE_ANON_KEY` sudah ada
- Auth (login/register) sudah jalan, `AuthBloc` sudah ada
- Tabel `workspaces` dan `workspace_members` sudah ada di Supabase

Kalau belum ada auth/workspace, selesaikan dulu itu — task manager butuh `workspace_id` dan `user_id` yang valid.

---

## Step 1 — Desain Skema Database (Supabase / Postgres)

### Yang perlu kamu pikirkan sendiri
Sebelum minta AI generate SQL, tentukan dulu relasi datanya di kertas/notes:
- `boards` (1 board per workspace, atau bisa multiple)
- `columns` (To Do / In Progress / Done — bisa fixed atau dinamis)
- `tasks` (belongs to column, punya assignee, due date, position untuk urutan drag)
- `task_comments`

Pertanyaan penting yang harus kamu jawab dulu: **kolom kanban itu fixed 3 status, atau user bisa custom nama kolom?** Ini menentukan apakah `status` cukup jadi enum di tabel `tasks`, atau perlu tabel `columns` terpisah. Untuk versi awal, sarankan **fixed status (enum)** dulu — lebih simpel, custom column bisa jadi fitur v2.

### Prompt untuk AI
```
Saya membangun task manager kanban dengan Supabase (Postgres) sebagai backend
untuk aplikasi Flutter. Konteks:
- Sudah ada tabel `workspaces` (id, name, owner_id) dan `workspace_members`
  (workspace_id, user_id, role: 'admin'|'member')
- Saya butuh tabel `tasks` dengan kolom kanban FIXED: 'todo', 'in_progress', 'done'
- Setiap task punya: title, description, assignee (nullable, referensi ke user),
  due_date (nullable), position (untuk urutan drag-drop dalam satu kolom),
  created_by, created_at, updated_at
- Butuh juga tabel `task_comments` (task_id, user_id, content, created_at)

Tolong buatkan:
1. SQL migration lengkap (CREATE TABLE) dengan foreign key yang benar
2. Index yang diperlukan untuk query yang sering dipakai (list task per
   workspace+status, list comment per task)
3. Row Level Security (RLS) policy: user hanya boleh SELECT/INSERT/UPDATE task
   kalau dia member di workspace yang sama. Untuk DELETE, hanya admin workspace
   atau pembuat task yang boleh.
4. Enable Realtime untuk tabel `tasks` dan `task_comments`

Jelaskan juga di komentar SQL kenapa tiap RLS policy ditulis seperti itu.
```

**Cek manual setelah AI generate**: jalankan query test — login sebagai 2 user berbeda di workspace berbeda, pastikan user A tidak bisa lihat task workspace B. Ini paling penting, jangan skip.

---

## Step 2 — Domain Layer (Entities, Repository Interface, UseCases)

Domain layer harus **pure Dart**, tidak boleh import Supabase atau apapun dari luar. Ini yang bikin logic-nya gampang di-test.

### Prompt untuk AI
```
Saya pakai Clean Architecture di Flutter (folder domain/data/presentation).
Buatkan domain layer untuk fitur task manager, HARUS pure Dart tanpa
dependency eksternal (tidak boleh import Supabase/Firebase apapun):

1. Entity `Task` (immutable, pakai `equatable` atau manual override
   `==`/`hashCode`): id, boardId/workspaceId, title, description, status
   (enum: todo/inProgress/done), assigneeId, dueDate, position, createdBy,
   createdAt, updatedAt
2. Entity `TaskComment`: id, taskId, userId, content, createdAt
3. Abstract class `TaskRepository` dengan method:
   - Future<List<Task>> getTasks(String workspaceId)
   - Stream<List<Task>> watchTasks(String workspaceId)
   - Future<Task> createTask(Task task)
   - Future<void> updateTask(Task task)
   - Future<void> deleteTask(String taskId)
   - Future<void> reorderTask(String taskId, TaskStatus newStatus, int newPosition)
   - Stream<List<TaskComment>> watchComments(String taskId)
   - Future<void> addComment(TaskComment comment)
4. UseCase classes (satu class per aksi, dengan method `call()`):
   GetTasksUseCase, WatchTasksUseCase, CreateTaskUseCase, UpdateTaskUseCase,
   DeleteTaskUseCase, ReorderTaskUseCase

Ikuti pola: setiap UseCase menerima TaskRepository lewat constructor,
dan punya method `call(...)` supaya bisa dipanggil seperti fungsi biasa.
```

### Yang perlu kamu pahami (jangan cuma copy-paste)
Setelah AI generate, baca ulang `ReorderTaskUseCase`-nya. Ini bagian paling gampang salah — pastikan logic-nya menerima `taskId`, `newStatus` (kolom tujuan), dan `newPosition` (urutan di kolom tujuan), bukan cuma "pindah status" tanpa urutan.

---

## Step 3 — Data Layer (Model, DataSource, Repository Implementation)

### Prompt untuk AI
```
Lanjutan project Flutter Clean Architecture dengan Supabase. Domain layer
sudah ada (Task entity, TaskRepository abstract, TaskStatus enum).
Sekarang buatkan data layer:

1. `TaskModel extends Task` dengan `fromJson`/`toJson` yang cocok dengan
   skema tabel `tasks` di Supabase (snake_case di JSON, camelCase di Dart)
2. `TaskRemoteDataSource` (abstract + implementation pakai Supabase client)
   dengan method: getTasks, watchTasks (pakai
   `supabase.from('tasks').stream(primaryKey: ['id'])` yang di-filter
   workspace_id), createTask, updateTask, deleteTask, reorderTask
3. `TaskRepositoryImpl implements TaskRepository` yang memanggil
   TaskRemoteDataSource, dan handle error dengan try-catch, lempar custom
   exception `ServerException` kalau gagal
4. Registrasi semua ini ke `get_it` (service locator) di file `injection.dart`

Supabase client sudah tersedia sebagai singleton `Supabase.instance.client`.
Untuk stream, pastikan pakai `.eq('workspace_id', workspaceId)` sebagai filter
dan urutkan berdasarkan `position`.
```

### Catatan penting
Supabase `.stream()` punya keterbatasan: filter kompleks (misal gabungan `workspace_id` + `status`) kadang perlu ditangani manual di client side (`.map()` setelah stream, bukan di query). Kalau AI generate kode yang filter-nya aneh atau error, minta dia jelasin dulu keterbatasan `.stream()` sebelum lanjut — jangan langsung terima.

---

## Step 4 — Presentation Layer: BLoC

Pisahkan jadi 2 Bloc: `TaskBloc` (list task per board, termasuk real-time) dan `TaskDetailBloc` (single task + comments) — supaya rebuild UI lebih terkontrol.

### Prompt untuk AI
```
Buatkan TaskBloc menggunakan flutter_bloc, dengan pola berikut:

Events (pakai sealed class atau freezed):
- SubscribeToBoard(workspaceId)
- TaskListUpdated(List<Task> tasks)  -- internal, dipicu dari stream
- CreateTaskRequested(Task task)
- TaskMoved(taskId, newStatus, newPosition)  -- untuk drag-drop
- DeleteTaskRequested(taskId)

States:
- TaskInitial
- TaskLoading
- TaskLoaded(List<Task> tasks)
- TaskError(String message)

Requirement penting:
1. Saat SubscribeToBoard, subscribe ke WatchTasksUseCase, setiap data baru
   dari stream di-`add(TaskListUpdated(...))` supaya tetap lewat event flow
   BLoC (jangan emit langsung dari listener)
2. Saat TaskMoved di-dispatch: emit state OPTIMISTIC dulu (list task sudah
   di-reorder di memory, sebelum backend confirm), baru panggil
   ReorderTaskUseCase di background. Kalau gagal, emit ulang state sebelumnya
   dan tampilkan error
3. Override `close()` untuk cancel StreamSubscription
4. Gunakan `Equatable` di semua Event dan State

Constructor TaskBloc menerima: WatchTasksUseCase, CreateTaskUseCase,
ReorderTaskUseCase, DeleteTaskUseCase (lewat get_it, bukan langsung
instansiasi).
```

### Yang wajib kamu review manual
**Optimistic update rollback logic** — ini bagian paling sering jadi bug. Setelah AI generate, trace manual: kalau `ReorderTaskUseCase` gagal di tengah, apakah state benar-benar balik ke posisi semula? Coba simulasikan dengan mematikan wifi pas drag task, lihat apakah UI "loncat balik" dengan benar.

---

## Step 5 — UI: Kanban Board dengan Drag & Drop

### Prompt untuk AI
```
Buatkan widget KanbanBoardScreen di Flutter yang:
1. Konsumsi TaskBloc lewat BlocBuilder, listen ke TaskLoaded state
2. Render 3 kolom horizontal-scrollable (To Do, In Progress, Done),
   masing-masing kolom adalah DragTarget<Task>
3. Setiap task card adalah Draggable<Task> (dengan feedback widget saat
   di-drag, dan childWhenDragging yang semi-transparent)
4. Saat task di-drop ke kolom lain, hitung newPosition berdasarkan posisi
   drop (akhir kolom kalau drop di area kosong), lalu dispatch
   TaskMoved(taskId, newStatus, newPosition) ke TaskBloc
5. Tampilkan loading skeleton (bukan cuma CircularProgressIndicator) saat
   TaskLoading, dan error state dengan tombol retry saat TaskError
6. Task card menampilkan: title, assignee avatar (kalau ada), due date badge
   (merah kalau overdue)

Style: clean, minimal, mirip Trello. Gunakan Material 3.
```

### Alternatif kalau drag-drop native Flutter terasa kaku
Kalau `Draggable`/`DragTarget` bawaan Flutter terasa kurang smooth (sering begitu untuk kanban), minta AI coba pakai package `appflowy_board` atau `flutter_boardview` — tapi pahami dulu trade-off-nya (custom vs package: package lebih cepat tapi kamu belajar lebih sedikit soal gesture handling).

---

## Step 6 — Real-time Multi-User Sync

Ini yang bikin project ini "advance". Testing-nya beda dari fitur biasa — butuh **2 instance app berjalan bersamaan**.

### Cara test manual (lakukan ini, bukan cuma baca kode)
1. Jalankan app di 2 device/emulator dengan 2 akun user berbeda, tapi 1 workspace yang sama
2. Di device A, pindahkan task antar kolom
3. Device B harus update otomatis dalam 1-2 detik tanpa refresh manual

### Prompt untuk AI (kalau real-time belum jalan mulus)
```
TaskBloc saya subscribe ke WatchTasksUseCase yang membungkus
Supabase .stream(). Masalahnya: [jelaskan gejala spesifik, misal
"update dari device lain butuh 5+ detik" atau "kadang task muncul dobel"].

Ini kode TaskBloc dan TaskRemoteDataSource saya: [paste kode]

Tolong diagnosa kemungkinan penyebab (misal: stream filter yang salah,
tidak ada dedup di state, Realtime belum di-enable di tabel Supabase),
dan jelaskan cara verifikasi masing-masing kemungkinan sebelum kita
langsung ubah kode.
```

Prompt ini sengaja diminta "diagnosa dulu sebelum ubah kode" — supaya kamu paham akar masalahnya, bukan cuma dapat tempelan fix yang kamu nggak ngerti.

---

## Step 7 — Testing

### Prompt untuk AI
```
Buatkan unit test untuk ReorderTaskUseCase dan TaskBloc menggunakan
package `bloc_test` dan `mocktail`.

Untuk ReorderTaskUseCase: test bahwa dia memanggil
repository.reorderTask dengan parameter yang benar.

Untuk TaskBloc, test skenario:
1. Saat TaskMoved di-dispatch dan berhasil, state akhir adalah TaskLoaded
   dengan urutan task yang sudah benar
2. Saat TaskMoved di-dispatch tapi repository throw exception, state
   kembali ke urutan semula (rollback) dan ada TaskError sementara

Mock TaskRepository, jangan pakai Supabase asli di test ini.
```

---

## Ringkasan Urutan Kerja

| Step | Fokus | Output |
|---|---|---|
| 1 | Skema DB + RLS | Tabel Supabase siap, security teruji |
| 2 | Domain layer | Entity, interface, usecase (pure Dart) |
| 3 | Data layer | Model, datasource, repo impl (Supabase) |
| 4 | BLoC | State management + optimistic update |
| 5 | UI | Kanban board + drag-drop |
| 6 | Real-time | Sync antar user teruji dengan 2 device |
| 7 | Testing | Unit test usecase + bloc |

## Prinsip pakai prompt-prompt di atas
Jangan copy-paste output AI langsung ke project tanpa baca. Di setiap step ada bagian **"yang perlu kamu pahami/review manual"** — itu bagian yang justru paling penting buat goal belajar arsitektur kamu. AI bagus untuk generate boilerplate cepat, tapi keputusan arsitektur (kenapa optimistic update, kenapa RLS ditulis begitu, kenapa pisah TaskBloc dan TaskDetailBloc) harus kamu pahami sendiri — itu yang ditanyakan kalau nanti dipakai buat interview atau portfolio review.