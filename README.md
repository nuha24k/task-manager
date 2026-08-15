# 🚀 TaskManager — Task Manager App (Flutter + BLoC + Supabase)

TaskManager adalah aplikasi manajemen tugas Kanban modern yang dibangun menggunakan **Flutter**, **BLoC (Business Logic Component)**, **Clean Architecture**, dan **Supabase (PostgreSQL, Auth, Realtime Engine)**. 

Aplikasi ini menyajikan antarmuka visual modern (berdasarkan referensi UI Kanban), lengkap dengan fitur autentikasi, drag & drop tugas, sub-task management, kalender pertemuan, serta penanganan error dan sinkronisasi real-time yang tangguh.

---

## 🎨 Tampilan & Fitur Utama

- **Splash Screen**: Layar selamat datang dengan animasi *Smooth Fade & Scale* dan auto-check sesi login.
- **Auth (Login & Sign Up)**: Layar autentikasi modern dengan validasi input, toggle password, dan penanganan status error.
- **Dashboard Kanban Board**:
  - Banner proyek "Mastering projects with management" & timer task.
  - Kartu tugas dengan indikator *progress bar*, *avatar bertumpuk*, *priority tag* (High, Medium, Low), & *due date*.
  - **Drag & Drop Interaktif**: Memindahkan tugas antar status (*To Do*, *In Progress*, *Done*) dengan pembaharuan posisi dan *optimistic update & rollback*.
  - **Floating Bottom Navigation Bar**: Navigasi melayang dengan akses cepat ke menu utama, kalender, statistik, profil, dan tombol modal `+` untuk membuat task baru.
- **Task Detail & Sub-Task Screen**: Detail proyek lengkap dengan penanggung jawab (*Created by*), *Deadline*, *Assignees*, serta tab switcher *Goals (Checklist Sub-tasks)* & *Chat*.
- **Calendar & Meeting Schedule Screen**: Tampilan kalender bulanan interaktif dengan highlight tanggal aktif, daftar pertemuan *Today's meeting* beserta tombol *"Join meet"*, dan kartu progres UI Kit.

---

## 🏗️ Arsitektur Proyek (Clean Architecture + MVVM + BLoC)

Proyek ini menerapkan **Clean Architecture** yang terisolasi secara ketat menjadi 3 lapisan (Layers):

```
lib/
├── domain/                      # Pure Dart (No External Dependencies)
│   ├── entities/               # Data Model Bisnis (Task, TaskComment, Enums)
│   ├── repositories/           # Abstract Contract/Interface Repository
│   └── usecases/               # Logika Bisnis Spesifik (Get, Watch, Create, Reorder)
├── data/                        # Infrastruktur & Data Provider
│   ├── models/                 # Model JSON Mappers (TaskModel, TaskCommentModel)
│   ├── datasources/            # Supabase Client & Realtime Stream Mappers
│   └── repositories/           # Implementasi Repository + Functional Error Handling
├── presentation/                # Layer UI & State Management
│   ├── blocs/                  # BLoC (TaskBloc - Events, States & Stream Handler)
│   ├── pages/                  # Screen Views (Splash, Login, Dashboard, Detail, Calendar)
│   ├── widgets/                # UI Components (TaskCard, FloatingNavBar, BottomSheet)
│   └── theme/                  # Design Tokens & Palette Colors (AppColors)
├── injection.dart               # Dependency Injection (GetIt Service Locator)
├── main.dart                    # Entry Point Application
```

---

## 🗄️ Supabase Backend & Database Schema

Skema database PostgreSQL Supabase lengkap tersedia pada file [`schema.sql`](schema.sql).

### Tabel Utama:
1. **`tasks`**: Menyimpan data utama task (`id`, `workspace_id`, `title`, `description`, `status`, `priority`, `assignee_ids`, `due_date`, `position`, `progress`, `created_by`).
2. **`task_comments`**: Menyimpan komentar per tugas (`id`, `task_id`, `user_id`, `content`, `created_at`).

### Fitur Keamanan & Real-time Engine:
- **Row Level Security (RLS)**: Mencegah pengguna yang tidak terautentikasi mengakses atau mengubah data task workspace lain.
- **Realtime Publications**: Mengaktifkan penerbitan data otomatis Supabase (`ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks`).

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat
- **Flutter SDK**: Versi `^3.11.0` atau yang lebih baru.
- **Supabase Account**: Proyek Supabase aktif.
- **Xcode / Android Studio**: Untuk menjalankan di iOS Simulator atau Android Emulator.

### 2. Konfigurasi Backend Supabase
1. Buka Supabase Dashboard Anda ➔ pilih menu **SQL Editor**.
2. Buat query baru, lalu salin dan jalankan seluruh isi script dari file [`schema.sql`](schema.sql).
3. Buka **Project Settings ➔ API**, lalu catat **Project URL** dan **`anon` `public` Key**.

### 3. Masukkan Credentials ke Flutter Project
Buka file [`lib/main.dart`](lib/main.dart), lalu masukkan URL & Anon Key Supabase Anda:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  await initInjection();
  runApp(const TaskManagerApp());
}
```

### 4. Install Dependencies & Run Project
Buka Terminal di root direktori proyek, lalu jalankan:

```bash
# 1. Unduh paket dependency
flutter pub get

# 2. Jalankan analisis statis untuk memastikan zero error
flutter analyze

# 3. Jalankan aplikasi pada simulator / device
flutter run
```

---

## 🧪 Testing

Jalankan pengujian unit test BLoC & UseCases:

```bash
flutter test
```

---

## 📄 Kredensial Demo Default
Jika Anda menggunakan Seed SQL bawaan:
- **Email**: `demo@taskflow.com`
- **Password**: `password123`
