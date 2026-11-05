# 🎬 Cinemate

**Cinemate** adalah aplikasi pemesanan tiket bioskop multi-cinema berbasis AI untuk rekomendasi film sesuai *mood* dan penemuan lokasi bioskop terdekat (*Location-Based Services*), dilengkapi pemesanan tiket & F&B, simulasi pembayaran, serta *e-ticket QR code* yang dapat diakses secara *offline*.

Proyek ini dibangun menggunakan **Dart** & framework **Flutter** dengan arsitektur **GetX OOP**, serta mengacu pada **SRS-CNM-001** dan **PB-CNM-001**.

---

## 🛠️ Tech Stack & Konvensi
- **Framework & SDK:** Flutter (Dart 3.x, Android API 26+)
- **State Management & Routing:** GetX (`GetxController`, `GetPage`, `Bindings`, `Obx`)
- **Desain UI:** Material Design 3 — *Dark Cinema Palette* (`#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`)
- **Backend Online:** Supabase (PostgreSQL Database & Storage) — *Bukan Firebase*
- **HTTP Client:** Dio (Interceptor token, retry 2x, timeout 15s/30s)
- **Local Storage:**
  - `flutter_secure_storage`: Token sesi & user ID (terenkripsi)
  - `hive` & `hive_flutter`: Cache data film, bioskop, dan e-ticket offline (NoSQL)
  - `get_storage`: Preferensi tema, mata uang, zona waktu, dan login attempt lockout
- **Referensi Modul Praktikum:**
  - Modul 6/7 (Local Storage & Hive): [pertemuan_7_mobile](https://github.com/TheBinKingVII/pertemuan_7_mobile)
  - Modul 7/8 (Notification & LBS): [pertemuan_8_mobile_2026](https://github.com/TheBinKingVII/pertemuan_8_mobile_2026)

---

## 📁 Struktur Folder Proyek
```text
lib/
├── app.dart                    # GetMaterialApp konfigurasi tema & initial route
├── main.dart                   # Inisialisasi binding, dotenv, GetStorage, Hive, Supabase
├── bindings/                   # GetX Bindings (InitialBinding, AuthBinding)
├── controllers/                # GetxController untuk state management
├── models/                     # Data class/model (UserModel, SessionModel, dll.)
├── repositories/               # Repository pattern (Interface & Implementation)
├── routes/                     # AppRoutes & AppPages
├── services/                   # Service layer (SupabaseService, HttpService, StorageService, AuthService)
├── utils/                      # AppColors, AppTheme, AppConstants, Validators
└── views/                      # Antarmuka UI (splash, auth, dashboard)
assets/
├── .env.example                # Template variabel lingkungan
└── .env                        # Kredensial API (diabaikan oleh git)
docs/
└── supabase_schema.sql         # Skema database & RLS Supabase
```

---

## ✅ Status Pengerjaan (Sprint 1 — Selesai)

### 1. Epic Fondasi Teknis (TEK)
- [x] **PB-001 (Kerangka Proyek & OOP):** Struktur folder GetX OOP lengkap (`models`, `services`, `repositories`, `controllers`, `bindings`, `views`, `routes`, `utils`). Lolos uji `dart analyze` (0 error).
- [x] **PB-002 (Skema Supabase):** Skema SQL di `docs/supabase_schema.sql` (tabel `users`, `sessions`, `cinemas`, `movies`, `showtimes`, `seat_locks`, `bookings`, `fnb_items`, `fnb_orders`, aturan RLS, dan seed data). Skema telah aktif dan terhubung ke database cloud Supabase.
- [x] **PB-003 (Lapisan HTTP Dio):** `HttpService` berbasis Dio dengan auth interceptor, auto-retry 2x, penanganan error terstandar, dan integrasi `.env`.
- [x] **PB-004 (Lapisan Penyimpanan Lokal):** `StorageService` mengabstraksi Hive (cache data), `flutter_secure_storage` (token sesi), dan `GetStorage` (preferensi).

### 2. Epic Autentikasi (AUT)
- [x] **PB-005 (Registrasi Akun):** Halaman register (`register_view.dart`) dengan validasi form lengkap, hashing password aman (*salt + SHA-256*), dan deteksi email duplikat.
- [x] **PB-006 (Login Email & Password):** Halaman login (`login_view.dart`) dengan verifikasi kredensial, pesan error aman, serta fitur **lockout 5 menit setelah 5x gagal** lengkap dengan *countdown timer*.
- [x] **PB-007 (Sesi Persisten):** `splash_view.dart` otomatis memverifikasi token sesi (< 7 hari) dan mengarahkan pengguna ke Dashboard atau Login.
- [x] **PB-008 (Logout):** Tombol logout dengan dialog konfirmasi, menghapus sesi di storage lokal dan tabel `sessions` Supabase.

---

## 🚀 Panduan Setup untuk Anggota Tim

1. **Clone repository:**
   ```bash
   git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git
   cd Cinemate
   ```
2. **Siapkan berkas `.env`:**
   Salin `assets/.env.example` menjadi `assets/.env`:
   ```bash
   cp assets/.env.example assets/.env
   ```
   Isi nilai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `TMDB_API_KEY` milik tim.
3. **Unduh dependensi:**
   ```bash
   flutter pub get
   ```
4. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

## 🎯 TUGAS SELANJUTNYA (UNTUK ANGGOTA TIM)

Sesuai urutan Product Backlog, giliran pengerjaan berikutnya adalah **2 Epic (Product Backlog)** berikut:

---

### 📌 Epic 1: PB 2.3 — Epic Dashboard (DSH)

Tujuan: Menampilkan layar utama dengan navigasi 5 menu, katalog film dari TMDB, dan integrasi cache lokal.

#### User Stories yang Harus Dikerjakan:
1. **PB-011 (Navigasi Bawah 5 Menu):**
   - Buat menu navigasi bawah 5 tab: **Dashboard**, **Tiket**, **Pesan Makanan**, **Profil**, dan **Logout**.
   - Gunakan `IndexedStack` atau `PageView` agar state masing-masing tab tidak ter-reset saat berpindah.
   - Tab Logout memunculkan dialog konfirmasi (sudah ada helper-nya di `dashboard_view.dart`).
2. **PB-012 (Banner, Now Playing, & Coming Soon):**
   - Buat `MovieModel` di `lib/models/movie_model.dart`.
   - Buat `MovieService` di `lib/services/movie_service.dart` untuk memanggil API TMDB via `HttpService`:
     - Endpoint Now Playing: `/movie/now_playing`
     - Endpoint Coming Soon: `/movie/upcoming`
   - Tampilkan carousel/banner di bagian atas, diikuti section horizontal list *Now Playing* dan *Coming Soon*.
   - Sediakan shimmer/skeleton loading saat memuat data.
3. **PB-013 (Cache Film Offline):**
   - Simpan data film TMDB ke Hive box `movies_cache` dengan penanda waktu (*TTL 6 jam*).
   - Jika internet mati atau API gagal, muat film dari Hive cache dan tampilkan indikator "Mode Offline" (mengacu pada contoh Hive di [pertemuan_7_mobile](https://github.com/TheBinKingVII/pertemuan_7_mobile)).
4. **PB-014 (Halaman Detail Film):**
   - Saat poster film diklik, navigasikan ke `MovieDetailView` menggunakan `Get.toNamed(Routes.movieDetail, arguments: movie)`.
   - Tampilkan backdrop, poster, sinopsis, genre chips, durasi, rating bintang, dan tombol **"Beli Tiket"**.
5. **PB-015 (Bioskop Terdekat di Dashboard):**
   - Tampilkan ringkasan 3 bioskop terdekat di bawah section film pada dashboard dengan jarak dalam kilometer.

---

### 📌 Epic 2: PB 2.4 — Epic Tiket (TKT)

Tujuan: Membangun alur pemesanan tiket bioskop dari pemilihan jadwal hingga penerbitan *e-ticket* dengan QR code yang bisa dibuka offline.

#### User Stories yang Harus Dikerjakan:
1. **PB-018 (Alur Booked by Cinema):**
   - Pengguna memilih bioskop terlebih dahulu -> memilih film yang tayang di bioskop tersebut -> memilih tanggal & jam tayang.
2. **PB-019 (Alur Booked by Movie):**
   - Pengguna memilih film dari dashboard/detail -> sistem memfilter hanya bioskop yang menayangkan film tersebut -> memilih bioskop, tanggal, & jam.
3. **PB-020 (Ringkasan Pesanan / Order Summary):**
   - Menampilkan detail pesanan: judul film, nama bioskop, tanggal, studio, jam, label kursi yang dipilih, rincian harga tiket, biaya layanan, dan total tagihan.
4. **PB-021 (Simulasi Pembayaran):**
   - Menyediakan pilihan metode pembayaran simulasi (Virtual Account, E-Wallet dummy, QRIS).
   - Terdapat batas waktu bayar (countdown timer 10 menit).
   - Tombol "Bayar Sekarang" yang mengubah status pesanan menjadi *Paid*.
5. **PB-022 & PB-023 (E-Ticket dengan QR Code & Persistensi):**
   - Buat model `TicketModel` di `lib/models/ticket_model.dart`.
   - Generate kode booking unik (misal: `CNM-XXXXX`) dan tampilkan QR code menggunakan package `qr_flutter`.
   - Simpan data transaksi ke tabel `bookings` & `booking_seats` Supabase, serta simpan salinannya ke Hive box `tickets_cache`.
6. **PB-024 (Akses E-Ticket Offline):**
   - Saat perangkat tidak memiliki koneksi internet, pengguna tetap dapat membuka tab Tiket dan menampilkan QR code e-ticket langsung dari Hive cache.
7. **PB-025 (Daftar Tiket Aktif & Riwayat):**
   - Pada tab "Tiket", sediakan tab/filter: **Tiket Aktif** (jadwal tayang belum lewat) dan **Riwayat** (sudah selesai/kedaluwarsa).

---

## 📌 Standar Koding & Pengujian Sebelum Commit
1. Ikuti pola OOP GetX: letakkan logika bisnis di `Controller`, akses data di `Repository`/`Service`, dan UI hanya di `View`.
2. Selalu jalankan analisis statis sebelum commit:
   ```bash
   dart analyze lib
   ```
   Pastikan tidak ada error maupun warning yang tertinggal.
3. Jangan pernah melakukan commit berkas `assets/.env`.
