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

## ✅ Status Pengerjaan (Sprint 1 & Sprint 2 — SELESAI 100%)

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

### 3. Epic Dashboard (DSH)
- [x] **PB-011 (Navigasi Bawah 5 Menu):** Menu navigasi bawah 5 tab (Dashboard, Tiket, Pesan Makanan, Profil, Logout) dengan `IndexedStack` agar state tiap tab tidak ter-reset. Mengimplementasikan native `Navigator` bawaan Flutter SDK dan passing data antar halaman.
- [x] **PB-012 (Banner, Now Playing, & Coming Soon):** `MovieModel`, `MovieService` terintegrasi TMDB API `/movie/now_playing` & `/movie/upcoming`, Carousel Banner otomatis, Horizontal List poster film, dan Shimmer/Skeleton loading.
- [x] **PB-013 (Cache Film Offline):** Caching data katalog film TMDB ke Hive box `movies_cache` dengan penanda waktu (*TTL 6 jam*). Menampilkan banner indikator "Mode Offline" saat memuat dari cache lokal / tanpa koneksi.
- [x] **PB-014 (Halaman Detail Film):** Halaman `MovieDetailView` lengkap dibuka via `Get.toNamed(Routes.movieDetail, arguments: movie)` menampilkan backdrop, poster, sinopsis, genre chips, estimasi durasi, rating bintang, dan tombol sticky "Beli Tiket".
- [x] **PB-015 (Bioskop Terdekat di Dashboard):** Ringkasan 3 bioskop terdekat di bawah section film pada dashboard dengan kalkulasi jarak akurat (*Haversine Formula*), pengambilan data dari tabel Supabase `cinemas`, cache Hive `cinemas_cache`, skeleton loading, dan fitur ganti titik lokasi acuan LBS interaktif.

### 4. Epic Tiket (TKT)
- [x] **PB-018 (Alur Booked by Cinema):** Alur pemesanan tiket dari pemilihan bioskop (`BookByCinemaView`) -> film yang sedang tayang -> tanggal penayangan (7 hari ke depan) -> kelas studio (Regular 2D, IMAX with Laser, The Premiere) & jam tayang lengkap dengan indikator sisa kursi dan harga tiket.
- [x] **PB-019 (Alur Booked by Movie):** Alur pemesanan tiket langsung dari film di dashboard/detail (`BookByMovieView`) -> filter otomatis bioskop terdekat yang menayangkan film tersebut -> pilih bioskop, tanggal, studio & jam tayang -> navigasi ke pemilihan kursi (`SelectSeatView`).
- [x] **PB-020 (Ringkasan Pesanan / Order Summary):** Layar `OrderSummaryView` menampilkan informasi pesanan lengkap: poster & judul film, bioskop, tanggal, studio, jam, chip kursi yang dipilih, rincian biaya (tiket x jumlah + biaya layanan aplikasi Rp 3.000), dan total pembayaran.
- [x] **PB-021 (Simulasi Pembayaran):** Layar `PaymentView` dengan pilihan metode (BCA VA, Mandiri VA, BRI VA, GoPay, OVO, Dana, QRIS Dinamis), countdown timer batas bayar 10 menit, serta integrasi tombol "Bayar Sekarang" yang memproses tiket.
- [x] **PB-022 & PB-023 (E-Ticket QR Code & Persistensi Cloud/Local):** `TicketModel` dengan QR code dinamis (`qr_flutter`), kode booking unik (`CNM-XXXXX`), penyimpanan ke Supabase (`bookings` & `booking_seats`) serta persistensi offline ke Hive box `tickets_cache`. Dilengkapi dialog sukses & navigasi instan ke E-Ticket.
- [x] **PB-024 (Akses E-Ticket Offline):** Tiket dapat dibuka secara instan tanpa koneksi internet langsung dari Hive cache. Terdapat indikator visual "Mode Offline (Hive Cache)" dan QR code tetap dapat di-scan oleh petugas bioskop.
- [x] **PB-025 (Daftar Tiket Aktif, Riwayat, & Simulasi Check-in):** Tab `TicketsTab` dengan pemisahan otomatis tiket aktif (jadwal belum lewat) dan riwayat tiket (sudah ditonton / lewat), pencarian live (*search by title, booking code, cinema*), countdown waktu tayang ("Dimulai dalam X jam/menit"), serta tombol simulasi check-in petugas yang memperbarui status tiket secara real-time di Supabase dan Hive.

---

## 🚀 Panduan Setup untuk Anggota Tim

1. **Clone repository:**
   ```bash
   git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git
   cd Cinemate
   ```
2. **Switch ke branch terbaru atau tarik update dari main:**
   ```bash
   git checkout feat/pb-024-025-offline-tickets-history
   # Atau setelah merge: git pull origin main
   ```
3. **Siapkan berkas `.env`:**
   Salin `assets/.env.example` menjadi `assets/.env`:
   ```bash
   cp assets/.env.example assets/.env
   ```
   Isi nilai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `TMDB_API_KEY` milik tim.
4. **Unduh dependensi:**
   ```bash
   flutter pub get
   ```
5. **Jalankan pengujian unit (Semua 28 Unit Test Wajib Passed):**
   ```bash
   flutter test
   ```
6. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

## 🎯 TUGAS SELANJUTNYA (UNTUK ANGGOTA TIM)

Sesuai Roadmap Pengembangan Aplikasi Cinemate untuk **Sprint 3** dan **Sprint 4**, berikut adalah pembagian tugas, panduan branching, dan rincian *Product Backlog* yang siap dikerjakan oleh anggota tim:

---

### 👥 Rekomendasi Pembagian Tugas Anggota Tim

| Anggota Tim | Peran & Fokus Modul | Backlog Item | File Utama yang Dibuat / Dimodifikasi |
| :--- | :--- | :---: | :--- |
| **Developer A** | **Frontend F&B & State Keranjang (Cart)** | **PB-026, PB-027** | `lib/models/fnb_item_model.dart`<br>`lib/controllers/fnb_controller.dart`<br>`lib/views/dashboard/tabs/fnb_tab.dart` |
| **Developer B** | **Backend Service F&B, Supabase & E-Voucher QR** | **PB-028, PB-029, PB-030** | `lib/services/fnb_service.dart`<br>`lib/models/fnb_order_model.dart`<br>`docs/supabase_schema.sql`<br>`lib/views/fnb/fnb_order_detail_view.dart` |
| **Developer C** | **AI Mood Recommendations Engine & TMDB Discovery** | **PB-031, PB-032, PB-033** | `lib/views/dashboard/tabs/home_tab.dart`<br>`lib/views/mood/mood_picker_view.dart`<br>`lib/services/mood_service.dart`<br>`lib/controllers/mood_controller.dart` |
| **Developer D** | **Profil Pengguna, Konversi Mata Uang, Timezone & Notifikasi** | **PB-048, PB-049, PB-050, PB-058** | `lib/views/dashboard/tabs/profile_tab.dart`<br>`lib/utils/currency_helper.dart`<br>`lib/views/profile/edit_profile_view.dart`<br>`lib/services/notification_service.dart` |

---

### 🌿 Panduan Branching Git untuk Anggota Tim

Setiap anggota tim disarankan membuat cabang (*branch*) baru dari update terbaru:
```bash
# Developer A & B (Epic F&B):
git checkout -b feat/pb-026-030-fnb-ordering

# Developer C (Epic Mood AI):
git checkout -b feat/pb-031-033-mood-ai-recommendations

# Developer D (Epic Profil, Preferensi & Notifikasi):
git checkout -b feat/pb-048-058-profile-preferences-notifications
```

---

### 📌 SPRINT 3: EPIC PESAN MAKANAN & MINUMAN (FNB) & REKOMENDASI MOOD AI (MOD)

#### 🍿 Epic 3.1: Pesan Makanan & Minuman / F&B (FNB)
Tujuan: Memungkinkan penonton memesan camilan & minuman bioskop secara online, memilih metode pengambilan (*counter pick-up* atau antar ke kursi studio), membayar secara simulasi, dan memperoleh E-Voucher QR Code F&B.

1. **PB-026 (Katalog F&B Supabase & Hive Offline Cache):**
   - **Tabel Basis Data:** `public.fnb_items` (Kolom: `id`, `name`, `description`, `price`, `category`, `image_url`, `is_available`).
   - **Seed Data Siap Pakai:** Popcorn Regular/Large, Nachos, Coca-Cola Regular/Large, Air Mineral, Combo 1, Combo 2, Hot Dog, Pretzel.
   - **Model:** Buat `FnbItemModel` di `lib/models/fnb_item_model.dart` (`fromJson`, `toJson`, `copyWith`, format harga Rupiah).
   - **Service:** Buat `FnbService` di `lib/services/fnb_service.dart` untuk membaca data dari tabel `public.fnb_items` Supabase dan menyimpannya ke Hive box `fnb_cache` (TTL 12 jam).
   - **UI:** Perbarui `lib/views/dashboard/tabs/fnb_tab.dart` dengan filter chip kategori (*Semua*, *Snack*, *Drink*, *Combo*, *Food*) serta shimmer skeleton loading.

2. **PB-027 (Keranjang Pesanan F&B / Cart Management):**
   - **Controller:** Buat `FnbController` di `lib/controllers/fnb_controller.dart` mengelola state reaktif `cartItems = <FnbItemModel, int>{}.obs`.
   - **Fitur Cart:** Tambah quantity (+), kurangi quantity (-), kosongkan cart, kalkulasi subtotal, pajak/biaya layanan, dan grand total.
   - **UI:** Tampilkan floating summary bar di bagian bawah `FnbTab` saat cart tidak kosong (menampilkan jumlah item, total harga, dan tombol *"Lihat Keranjang / Checkout"*).

3. **PB-028 (Pilihan Bioskop & Metode Pengambilan):**
   - **Alur Pemesanan:** Pengguna memilih bioskop tempat pengambilan (dropdown/picker bioskop dari `CinemaController`).
   - **Metode Pengambilan:**
     - *Pick-up di Counter Concession* (Antre mandiri di counter bioskop dengan kode pengambilan).
     - *Delivery ke Studio & Kursi* (Hanya aktif jika user memiliki tiket aktif di bioskop tersebut, otomatis mengaitkan nomor studio dan kursi).

4. **PB-029 (Simulasi Pembayaran F&B & E-Voucher QR Code):**
   - Integrasikan dengan modul `PaymentView` atau layar checkout pesanan F&B.
   - Simpan pesanan ke tabel `public.fnb_orders` dan `public.fnb_order_items` di Supabase.
   - Terbitkan kode pengambilan unik (format: `FNB-XXXXX`) dan E-Voucher QR Code (`qr_flutter`) untuk di-scan petugas bioskop.

5. **PB-030 (Riwayat & Pelacakan Status Pesanan F&B):**
   - Tampilkan daftar pesanan F&B pengguna di sub-tab *"Pesanan Saya"* pada `FnbTab`.
   - Status pesanan: `processing` (sedang disiapkan), `ready` (siap diambil di counter), `completed` (sudah diambil).
   - Sediakan tombol simulasi untuk petugas: ubah status dari `processing` -> `ready` -> `completed`.
   - Simpan cache riwayat pesanan ke Hive box `fnb_orders_cache` agar bisa dibuka offline di bioskop.

---

#### 🎭 Epic 3.2: Rekomendasi Film Berbasis Mood AI (MOD)
Tujuan: Mewujudkan slogan utama Cinemate (*"Temukan film sesuai mood-mu"*) melalui fitur rekomendasi film berdasarkan suasana hati/emosi pengguna yang terhubung langsung ke katalog TMDB dan alur booking.

1. **PB-031 (Layar Pemilih Mood Interaktif):**
   - Buat tombol akses banner/widget di `HomeTab` (*"Bingung mau nonton apa? Coba Mood AI ✨"*).
   - Layar `MoodPickerView` menampilkan 6 emosi utama dengan visual estetik:
     - 😃 **Happy / Gembira:** Film ceria, komedi keluarga, dan animasi.
     - 😢 **Sad / Haru:** Film drama emosional, biografi mengharukan.
     - ❤️ **Romantic / Jatuh Cinta:** Film romansa, percintaan manis, dan rom-com.
     - ⚡ **Thrilled / Butuh Adrenalin:** Action menegangkan, horror, suspense thriller.
     - 🧘 **Chill / Rileks:** Petualangan visual santai, dokumenter, fiksi ilmiah ringan.
     - 🥱 **Bored / Bosan & Butuh Hiburan Seru:** Film misteri dengan *plot twist* mengejutkan.

2. **PB-032 (Mood-to-Genre Engine & Filter TMDB Discovery):**
   - Buat `MoodRecommendationService` di `lib/services/mood_service.dart`.
   - Petakan setiap mood ke kombinasi `genre_id` TMDB:
     - `Happy` $\rightarrow$ Comedy (35), Animation (16), Family (10751).
     - `Sad` $\rightarrow$ Drama (18).
     - `Romantic` $\rightarrow$ Romance (10749), Comedy (35).
     - `Thrilled` $\rightarrow$ Action (28), Horror (27), Thriller (53).
     - `Chill` $\rightarrow$ Adventure (12), Sci-Fi (878), Fantasy (14).
     - `Bored` $\rightarrow$ Mystery (9648), Crime (80).
   - Panggil TMDB endpoint `/discover/movie` via `HttpService` dengan query parameter `with_genres`, `sort_by=popularity.desc`, dan `vote_average.gte=7.0`.

3. **PB-033 (Hasil Rekomendasi AI & Aksi Direct Booking):**
   - Tampilkan kartu rekomendasi film dengan:
     - Badge persentase kecocokan mood (misal: *98% Cocok untuk Mood Bahagia*).
     - Alasan rekomendasi dari AI Cinemate.
     - Tombol sticky **"Pesan Tiket Film Ini"** yang langsung memicu alur **PB-019** ([`BookByMovieView`](file:///C:/Users/Pongo/Documents/Praktikkum_Pemrogramman_Mobile/project/Cinemate/lib/views/booking/book_by_movie_view.dart)) untuk film tersebut.

---

### 📌 SPRINT 4: EPIC PROFIL, PREFERENSI & PENGINGAT NOTIFIKASI (PRF & NOT)

1. **PB-048 (Konversi Mata Uang Dinamis - Currency Preference):**
   - Opsi mata uang di `ProfileTab`: **IDR (Rp)**, **USD ($)**, **SGD (S$)**, **EUR (€)**.
   - Simpan preferensi di `GetStorage` via `StorageService`.
   - Buat `CurrencyHelper` yang otomatis memformat semua harga tiket dan F&B di seluruh aplikasi secara reaktif.

2. **PB-049 (Zona Waktu Penayangan - Timezone Preference):**
   - Opsi zona waktu di `ProfileTab`: **WIB (UTC+7)**, **WITA (UTC+8)**, **WIT (UTC+9)**, **GMT/UTC**.
   - Jadwal tayang bioskop otomatis disesuaikan dan menampilkan penanda zona (contoh: `14:30 WIB` -> `15:30 WITA`).

3. **PB-050 (Edit Profil Pengguna & Ubah Sandi):**
   - Layar `EditProfileView`: Ubah nama lengkap dan nomor telepon, simpan perubahan ke Supabase `users`.
   - Layar `ChangePasswordView`: Verifikasi sandi lama, hashing sandi baru (*salt + SHA-256*), lalu update kolom `users.password_hash`.

4. **PB-058 (Local Push Notification Pengingat Tiket - H-1 Jam & H-30 Menit):**
   - Dependensi: `flutter_local_notifications` (mengacu pada materi praktikum modul 8).
   - Penanganan permission Android 13+ (`POST_NOTIFICATIONS`).
   - Jadwalkan pengingat otomatis saat status tiket menjadi `paid`:
     - *Notifikasi 1:* 1 jam sebelum film tayang (*"Film Anda dimulai 1 jam lagi!"*).
     - *Notifikasi 2:* 30 menit sebelum film tayang (*"Studio segera dibuka! Siapkan E-Ticket offline Anda"*).

---

## 📌 Standar Koding & Pengujian Sebelum Pull Request (PR)

1. **Arsitektur GetX OOP:**
   - Pisahkan logika ke `Controller`, data/API ke `Service`, dan antarmuka ke `View`.
   - Gunakan warna dari `AppColors` (*Dark Cinema Palette: `#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`*).
2. **Offline-First & Graceful Fallback:**
   - Setiap pengambilan data online wajib memiliki fallback ke Hive box jika jaringan mati atau API gagal.
3. **Checklist Wajib Sebelum Commit & Push:**
   ```bash
   # 1. Pastikan tidak ada error atau warning:
   dart analyze lib test

   # 2. Jalankan seluruh unit test (wajib 100% passed):
   flutter test

   # 3. Format kode:
   dart format lib test
   ```
4. **Keamanan Kredensial:**
   - Jangan pernah melakukan commit berkas `assets/.env`.
