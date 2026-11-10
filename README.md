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
  - `hive` & `hive_flutter`: Cache data film, bioskop, F&B, dan e-ticket offline (NoSQL)
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
├── bindings/                   # GetX Bindings (InitialBinding, AuthBinding, DashboardBinding, dll.)
├── controllers/                # GetxController untuk state management (FnbController, MoodController, dll.)
├── models/                     # Data class/model (FnbItemModel, FnbOrderModel, MoodModel, TicketModel, dll.)
├── repositories/               # Repository pattern (Interface & Implementation)
├── routes/                     # AppRoutes & AppPages
├── services/                   # Service layer (SupabaseService, FnbService, MoodService, HttpService, dll.)
├── utils/                      # AppColors, AppTheme, AppConstants, Validators
└── views/                      # Antarmuka UI (splash, auth, dashboard, booking, fnb, mood, ticket)
assets/
├── .env.example                # Template variabel lingkungan
└── .env                        # Kredensial API (diabaikan oleh git)
docs/
└── supabase_schema.sql         # Skema database & RLS Supabase
```

---

## ✅ Status Pengerjaan (Sprint 1 s/d Sprint 3 — SELESAI 100%)

### 1. Epic Fondasi Teknis (TEK — PB 1)
- [x] **PB-001 (Kerangka Proyek & OOP):** Struktur folder GetX OOP lengkap (`models`, `services`, `repositories`, `controllers`, `bindings`, `views`, `routes`, `utils`). Lolos uji `dart analyze` (0 error).
- [x] **PB-002 (Skema Supabase):** Skema SQL di `docs/supabase_schema.sql` (tabel `users`, `sessions`, `cinemas`, `movies`, `showtimes`, `seat_locks`, `bookings`, `fnb_items`, `fnb_orders`, aturan RLS, dan seed data). Skema telah aktif dan terhubung ke database cloud Supabase.
- [x] **PB-003 (Lapisan HTTP Dio):** `HttpService` berbasis Dio dengan auth interceptor, auto-retry 2x, penanganan error terstandar, dan integrasi `.env`.
- [x] **PB-004 (Lapisan Penyimpanan Lokal):** `StorageService` mengabstraksi Hive (cache data), `flutter_secure_storage` (token sesi), dan `GetStorage` (preferensi).

### 2. Epic Autentikasi (AUT — PB 2)
- [x] **PB-005 (Registrasi Akun):** Halaman register (`register_view.dart`) dengan validasi form lengkap, hashing password aman (*salt + SHA-256*), dan deteksi email duplikat.
- [x] **PB-006 (Login Email & Password):** Halaman login (`login_view.dart`) dengan verifikasi kredensial, pesan error aman, serta fitur **lockout 5 menit setelah 5x gagal** lengkap dengan *countdown timer*.
- [x] **PB-007 (Sesi Persisten):** `splash_view.dart` otomatis memverifikasi token sesi (< 7 hari) dan mengarahkan pengguna ke Dashboard atau Login.
- [x] **PB-008 (Logout):** Tombol logout dengan dialog konfirmasi, menghapus sesi di storage lokal dan tabel `sessions` Supabase.

### 3. Epic Dashboard & Katalog (DSH — PB 3)
- [x] **PB-011 (Navigasi Bawah 5 Menu):** Menu navigasi bawah 5 tab (Dashboard, Tiket, Pesan Makanan, Profil, Logout) dengan `IndexedStack` agar state tiap tab tidak ter-reset. Mengimplementasikan native `Navigator` bawaan Flutter SDK dan passing data antar halaman.
- [x] **PB-012 (Banner, Now Playing, & Coming Soon):** `MovieModel`, `MovieService` terintegrasi TMDB API `/movie/now_playing` & `/movie/upcoming`, Carousel Banner otomatis, Horizontal List poster film, dan Shimmer/Skeleton loading.
- [x] **PB-013 (Cache Film Offline):** Caching data katalog film TMDB ke Hive box `movies_cache` dengan penanda waktu (*TTL 6 jam*). Menampilkan banner indikator "Mode Offline" saat memuat dari cache lokal / tanpa koneksi.
- [x] **PB-014 (Halaman Detail Film):** Halaman `MovieDetailView` lengkap dibuka via `Get.toNamed(Routes.movieDetail, arguments: movie)` menampilkan backdrop, poster, sinopsis, genre chips, estimasi durasi, rating bintang, dan tombol sticky "Beli Tiket".
- [x] **PB-015 (Bioskop Terdekat di Dashboard):** Ringkasan 3 bioskop terdekat di bawah section film pada dashboard dengan kalkulasi jarak akurat (*Haversine Formula*), pengambilan data dari tabel Supabase `cinemas`, cache Hive `cinemas_cache`, skeleton loading, dan fitur ganti titik lokasi acuan LBS interaktif.

### 4. Epic Pemesanan Tiket Bioskop (TKT — PB 4)
- [x] **PB-018 (Alur Booked by Cinema):** Alur pemesanan tiket dari pemilihan bioskop (`BookByCinemaView`) -> film yang sedang tayang -> tanggal penayangan (7 hari ke depan) -> kelas studio (Regular 2D, IMAX with Laser, The Premiere) & jam tayang lengkap dengan indikator sisa kursi dan harga tiket.
- [x] **PB-019 (Alur Booked by Movie):** Alur pemesanan tiket langsung dari film di dashboard/detail (`BookByMovieView`) -> filter otomatis bioskop terdekat yang menayangkan film tersebut -> pilih bioskop, tanggal, studio & jam tayang -> navigasi ke pemilihan kursi (`SelectSeatView`).
- [x] **PB-020 (Ringkasan Pesanan / Order Summary):** Layar `OrderSummaryView` menampilkan informasi pesanan lengkap: poster & judul film, bioskop, tanggal, studio, jam, chip kursi yang dipilih, rincian biaya (tiket x jumlah + biaya layanan aplikasi Rp 3.000), dan total pembayaran.
- [x] **PB-021 (Simulasi Pembayaran):** Layar `PaymentView` dengan pilihan metode (BCA VA, Mandiri VA, BRI VA, GoPay, OVO, Dana, QRIS Dinamis), countdown timer batas bayar 10 menit, serta integrasi tombol "Bayar Sekarang" yang memproses tiket.
- [x] **PB-022 & PB-023 (E-Ticket QR Code & Persistensi Cloud/Local):** `TicketModel` dengan QR code dinamis (`qr_flutter`), kode booking unik (`CNM-XXXXX`), penyimpanan ke Supabase (`bookings` & `booking_seats`) serta persistensi offline ke Hive box `tickets_cache`. Dilengkapi dialog sukses & navigasi instan ke E-Ticket.
- [x] **PB-024 (Akses E-Ticket Offline):** Tiket dapat dibuka secara instan tanpa koneksi internet langsung dari Hive cache. Terdapat indikator visual "Mode Offline (Hive Cache)" dan QR code tetap dapat di-scan oleh petugas bioskop.
- [x] **PB-025 (Daftar Tiket Aktif, Riwayat, & Simulasi Check-in):** Tab `TicketsTab` dengan pemisahan otomatis tiket aktif (jadwal belum lewat) dan riwayat tiket (sudah ditonton / lewat), pencarian live (*search by title, booking code, cinema*), countdown waktu tayang ("Dimulai dalam X jam/menit"), serta tombol simulasi check-in petugas yang memperbarui status tiket secara real-time di Supabase dan Hive.

### 5. Epic Pesan Makanan & Minuman / F&B (FNB — PB 5)
- [x] **PB-026 (Katalog F&B Offline-First & Hive Cache — Tanpa Supabase):** Model `FnbItemModel` dengan 12 varian menu lengkap, `FnbService` berbasis Hive box `fnb_cache` (100% offline-first murni tanpa ketergantungan Supabase), banner indikator status Hive cache & timestamp sinkronisasi, filter chip kategori dinamis (*Semua*, *Snack*, *Minuman*, *Paket Combo*, *Makanan Berat*) dengan counter kuantitas menu, pencarian real-time dengan tombol clear, shimmer skeleton loading (`FnbListSkeleton`), dan penanganan empty state saat pencarian tidak ditemukan.
- [x] **PB-027 (Keranjang Pesanan F&B / Reactive Cart Management — Tanpa Supabase):** `FnbController` mengelola keranjang belanja reaktif (`cart`), penambahan/pengurangan item, persistensi otomatis ke Hive box `fnb_cache` (`active_cart` & `cart_notes`), instruksi/catatan khusus per menu (`itemNotes`), kalkulasi subtotal, biaya layanan aplikasi Rp 2.000, grand total, floating summary bar interaktif, badge keranjang di AppBar, modal bottom sheet detail keranjang (`FnbCartBottomSheet`), serta dialog konfirmasi pengosongan keranjang.
- [x] **PB-028 (Pilihan Bioskop & Metode Pengambilan F&B — Tanpa Supabase):** Layar `FnbCheckoutView` mendukung pemilihan lokasi bioskop penjualan (`availableCinemas`) dari seed/cache lokal tanpa Supabase, 2 metode pengambilan (*Ambil di Counter Concession* dengan QR voucher mandiri vs *Antar Langsung ke Studio & Kursi* oleh staf bioskop), auto-detection tiket aktif (`detectedActiveTicket`) dari Hive `tickets_cache` / `TicketsController` untuk pre-fill otomatis nama studio & nomor kursi lengkap dengan banner visual informasi tiket, text controller persisten tersinkronisasi, serta validasi form pengantaran studio & kursi sebelum checkout.
- [x] **PB-029 (Simulasi Pembayaran & E-Voucher QR Code F&B):** Integrasi transaksi ke tabel Supabase `fnb_orders` & `fnb_order_items`, penerbitan kode pickup 5 digit (`FNB-XXXXX`), serta QR Code E-Voucher (`qr_flutter`) untuk verifikasi staf bioskop.
- [x] **PB-030 (Riwayat & Pelacakan Status Pesanan F&B):** Sub-tab *"Pesanan Saya"* dengan status stepper dinamis (*Sedang Disiapkan* ⏳ $\rightarrow$ *Siap Diambil* ✨ $\rightarrow$ *Selesai Diambil* ✅), persistensi offline ke Hive (`fnb_orders_cache`), dan tombol simulasi staf bioskop.

### 6. Epic Rekomendasi Film Berbasis Mood AI (MOD / AIL — PB 6)
- [x] **PB-031 (Layar Pemilih Mood Interaktif — Tanpa Supabase):** Banner pengantar Mood AI di `HomeTab`, navigasi ke `MoodPickerView` dengan 6 kategori emosi (*Gembira*, *Haru*, *Romantis*, *Tegang*, *Santai*, *Bosan*), visualisasi gradien estetik dinamis, highlight kartu emosi terpilih, `MoodController` reaktif, integrasi binding rute, fallback kurasi offline tanpa Supabase, dan penyimpanan Hive cache lokal.
- [x] **PB-032 (Mood-to-Genre Engine & Filter TMDB Discovery — Tanpa Supabase):** Engine rekomendasi `MoodRecommendationService` memetakan genre ID TMDB dengan filter penemuan discovery cerdas (rating $\ge 7.0$, sorting dinamis *Terpopuler* & *Rating Tertinggi*), fallback kurasi offline berkualitas tinggi dengan TTL di Hive cache tanpa Supabase, serta didukung langkah opsional Tambah Makanan F&B sebelum ringkasan pesanan tiket bioskop (FR-028 / PB-032).
- [x] **PB-033 (Hasil Rekomendasi AI & Aksi Direct Booking — Tanpa Supabase):** Kartu rekomendasi film interaktif dengan persentase kecocokan AI (*88% - 99% MATCH*), badge gradien dinamis, analisis personalisasi berbasis mood emosi pengguna, tombol *"Lihat Sinopsis"* untuk detail lengkap, tombol *"Pesan Tiket"* langsung ke alur *Book by Movie* (`Routes.bookByMovie`), serta didukung alur pemesanan F&B mandiri tanpa tiket dengan kode ambil unik 5 digit `FNB-XXXXX` dan status processing (FR-036 / PB-033).

---

## 🚀 Panduan Setup untuk Anggota Tim

1. **Clone repository:**
   ```bash
   git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git
   cd Cinemate
   ```
2. **Switch ke branch terbaru atau tarik update dari main:**
   ```bash
   git pull origin main
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
5. **Jalankan pengujian unit (Semua 60 Unit Test Wajib Passed):**
   ```bash
   flutter test
   ```
6. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

## 🎯 Rekomendasi & Panduan Tugas untuk Developer Selanjutnya

> **Pesan untuk Rekan Tim:**  
> Halo developer! Seluruh pengerjaan **Epic 1 s.d. Epic 6 (PB-001 s.d. PB-033)** telah selesai **100%** dengan implementasi *clean architecture GetX*, dukungan *100% offline-first* via Hive cache lokal, serta **60/60 unit tests passed**.  
> Untuk giliran kamu selanjutnya, berikut adalah **pilihan paket backlog terstruktur** yang siap dikerjakan beserta spesifikasi teknis dan berkas targetnya:

---

### 🌿 Panduan Branching Git
Tarik update terbaru dari `main` dan buat branch baru sesuai paket fitur yang kamu pilih:
```bash
git checkout main
git pull origin main

# Pilihan 1: Jika mengerjakan LBS & Peta Bioskop (PB 7)
git checkout -b feat/pb-7-lbs-cinema-map

# Pilihan 2: Jika mengerjakan Konversi Kurs & Zona Waktu (PB 8)
git checkout -b feat/pb-8-currency-timezone

# Pilihan 3: Jika menyempurnakan Alur Pintasan F&B & Stepper Status
git checkout -b feat/pb-fnb-shortcuts-and-status

# Pilihan 4: Jika mengerjakan AI Profiling & Chatbot
git checkout -b feat/pb-ai-profiling-chat
```

---

### 📍 Pilihan 1: PB 7 — Location-Based Services & Peta Bioskop (Epic LBS)
*Rujukan Backlog: PB-042 s.d. PB-047, SRS §3.8 FR-046 s.d. FR-051*

- **Tujuan Modul:** Menampilkan bioskop terdekat berdasarkan koordinat GPS pengguna secara akurat, visualisasi penanda pin di peta interaktif OSM, filter radius jangkauan, dan navigasi rute ke lokasi bioskop.
- **Rincian Fitur:**
  1. **Deteksi Lokasi & Izin GPS (`PB-042` / FR-046):**
     - Menggunakan `geolocator` untuk membaca koordinat `latitude` dan `longitude` pengguna.
     - Penanganan izin (*permission request*): jika izin lokasi ditolak atau GPS nonaktif, berikan fallback ramah dengan dialog pilihan manual kota/bioskop acuan (`PB-047` / FR-051).
  2. **Daftar Bioskop Terurut Berdasarkan Jarak (`PB-043` / FR-047):**
     - Tampilkan daftar seluruh bioskop yang diurutkan secara realtime dari jarak paling dekat ke paling jauh (km) menggunakan *Haversine formula*.
  3. **Peta Bioskop Interaktif (`PB-044` / FR-048):**
     - Menggunakan `flutter_map` dengan tile OpenStreetMap (OSM) (bebas kuota / tanpa kartu kredit).
     - Menampilkan marker posisi pengguna (*user pin*) dan marker lokasi bioskop (*cinema pin*). Mengetuk pin bioskop memunculkan modal ringkasan bioskop.
  4. **Filter Radius Bioskop (`PB-045` / FR-049):**
     - Filter chip radius dinamis: `1 km`, `3 km`, `5 km`, `10 km`, dan `Semua Jarak`.
     - Marker pada peta dan daftar bioskop otomatis tersaring sesuai radius aktif.
  5. **Buka Rute Navigasi Eksternal (`PB-046` / FR-050):**
     - Tombol *"Petunjuk Arah / Rute"* yang membuka Google Maps via `url_launcher` dengan koordinat tujuan.
- **Target File yang Dikerjakan:**
  - `lib/services/location_service.dart` (Service pembaca GPS, izin perizinan, & fallback acuan)
  - `lib/views/cinema/cinema_map_view.dart` (Layar peta bioskop interaktif `flutter_map`)
  - `lib/controllers/cinema_controller.dart` (Filter radius & reaktif koordinat pengguna)
  - `test/lbs_cinema_test.dart` (Unit test radius filtering, haversine accuracy, & distance sorting)

---

### 🌐 Pilihan 2: PB 8 — Konversi Mata Uang & Penyesuaian Zona Waktu (Epic KNV)
*Rujukan Backlog: PB-048 s.d. PB-050, SRS §3.9 FR-052 s.d. FR-056*

- **Tujuan Modul:** Mempermudah pengguna wisatawan dalam memahami biaya tiket/F&B serta jam penayangan bioskop sesuai preferensi mata uang dan zona waktu mereka.
- **Rincian Fitur:**
  1. **Konversi Mata Uang Dinamis (`PB-048` / FR-052, FR-053):**
     - Mata uang yang didukung:
       - **IDR (Rp)** — Rupiah Indonesia *(Default kurs: 1.0)*
       - **USD ($)** — Dollar AS *(Kurs: 1 USD = Rp 16.000)*
       - **SGD (S$)** — Dollar Singapura *(Kurs: 1 SGD = Rp 12.000)*
       - **EUR (€)** — Euro Uni Eropa *(Kurs: 1 EUR = Rp 17.500)*
     - Simpan pilihan pengguna di `GetStorage` / Hive via `StorageService` (`key: 'currency_preference'`).
     - Terapkan helper reaktif agar harga tiket (`OrderSummaryView`) dan harga menu F&B (`FnbTab`, `FnbCheckoutView`) otomatis terkonversi dan terformat rapi.
  2. **Penyesuaian Zona Waktu Penayangan Film (`PB-049` / FR-054):**
     - Zona waktu yang didukung:
       - **WIB (UTC+7)** — Waktu Indonesia Barat *(Default jadwal bioskop)*
       - **WITA (UTC+8)** — Waktu Indonesia Tengah *(+1 jam)*
       - **WIT (UTC+9)** — Waktu Indonesia Timur *(+2 jam)*
       - **UTC (GMT+0)** — Greenwich Mean Time *(-7 jam)*
     - Simpan preferensi zona waktu di `GetStorage` / Hive (`key: 'timezone_preference'`).
     - Seluruh jadwal tayang film di `BookByCinemaView`, `BookByMovieView`, `TicketDetailView`, dan `TicketsTab` otomatis bergeser jamnya dan menampilkan label zona waktu (contoh: jadwal `14:00 WIB` otomatis tampil `15:00 WITA`).
  3. **Pengaturan di Profil & Persistensi Lintas Halaman (`PB-050` / FR-055, FR-056):**
     - Tambahkan selector pengaturan *"Mata Uang"* dan *"Zona Waktu"* pada `ProfileTab` (`lib/views/dashboard/tabs/profile_tab.dart`).
- **Target File yang Dikerjakan:**
  - `lib/utils/currency_helper.dart` (Helper konversi kurs & format simbol mata uang)
  - `lib/utils/timezone_helper.dart` (Helper pergeseran jam penayangan & format label zona)
  - `lib/views/dashboard/tabs/profile_tab.dart` (Menu pemilihan mata uang dan zona waktu)
  - `test/currency_conversion_test.dart` & `test/timezone_format_test.dart` (Unit test)

---

### 🍿 Pilihan 3: Penyempurnaan Alur Pintasan F&B & Stepper Status (Epic FNB)
*Rujukan Backlog: PB-034 & PB-035, SRS §3.6 FR-037 & FR-038*

- **Tujuan Modul:** Melengkapi kenyamanan pemesanan F&B dari berbagai titik aplikasi serta menyediakan pelacakan status pesanan secara visual dan transparan.
- **Rincian Fitur:**
  1. **Pintasan Menu F&B dengan Konteks Bioskop Terbawa (`PB-034` / FR-037):**
     - Sediakan tombol pintasan *"Pesan F&B untuk Nonton"* di halaman `TicketDetailView`, `OrderSummaryView`, dan banner di `HomeTab`.
     - Saat ditekan, navigasikan langsung ke `FnbTab` / `FnbCheckoutView` dengan otomatis mengunci bioskop yang sesuai dengan tiket atau bioskop yang sedang aktif.
  2. **Detail Status Stepper & Simulasi Pesanan F&B (`PB-035` / FR-038):**
     - Buat layar `FnbOrderDetailView` dengan stepper vertikal dinamis:
       - ⏳ *Sedang Disiapkan (Processing)*: Pesanan diterima concession.
       - ✨ *Siap Diambil / Diantar (Ready)*: Makanan selesai dimasak/disiapkan.
       - ✅ *Selesai (Completed)*: Makanan telah diterima penonton.
     - Sediakan tombol simulasi petugas bioskop untuk memajukan status pesanan langsung di Hive cache lokal.
- **Target File yang Dikerjakan:**
  - `lib/views/fnb/fnb_order_detail_view.dart` (Layar detail pesanan F&B dengan stepper visual)
  - `lib/views/tickets/ticket_detail_view.dart` (Tambahkan tombol pintasan pesan F&B bioskop)
  - `lib/controllers/fnb_controller.dart` (Metode navigasi shortcut dengan parameter bioskop & simulasi status)
  - `test/fnb_order_cart_test.dart` (Unit test shortcut context & update status pesanan)

---

### 🤖 Pilihan 4: AI Profiling & Chatbot Asisten Rekomendasi (Epic AIL)
*Rujukan Backlog: PB-036 s.d. PB-041, SRS §3.7 FR-039 s.d. FR-045*

- **Tujuan Modul:** Memberikan asisten interaktif cerdas bagi pengguna yang mencari rekomendasi film personal melalui dialog chat atau kuesioner profiling.
- **Rincian Fitur:**
  1. **Formulir Profiling Preferensi Nonton (`PB-037` / FR-042):**
     - Layar kuesioner interaktif: input mood, preferensi genre, teman nonton (sendiri, pasangan, keluarga), durasi maksimal, dan budget.
  2. **Layanan AI dengan Rule-based Fallback Offline (`PB-036` / FR-044, FR-045):**
     - Integrasi abstraksi LLM dengan validasi JSON dan skema fallback lokal berkualitas tinggi tanpa Supabase.
  3. **Chatbot Asisten Bioskop (`PB-039`, `PB-040` / FR-039, FR-040):**
     - Antarmuka chat interaktif dengan gelembung pesan, typing indicator, dan riwayat obrolan tersimpan di Hive.
- **Target File yang Dikerjakan:**
  - `lib/views/ai/ai_profiling_view.dart` & `lib/views/ai/ai_chat_view.dart`
  - `lib/controllers/ai_controller.dart` & `lib/services/ai_service.dart`
  - `test/ai_recommendation_test.dart`

---

### 📌 Standar Koding & Pengujian Sebelum Pull Request (PR)

1. **Arsitektur GetX OOP & Offline-First:**
   - Pisahkan logika ke `Controller`, data/cache ke `Service`/`Utils`, dan antarmuka ke `View`.
   - Pastikan aplikasi selalu berjalan mulus dalam mode offline dengan fallback data lokal / Hive.
   - Gunakan palet warna konsisten dari [AppColors](file:///C:/Users/Pongo/Documents/Praktikkum_Pemrogramman_Mobile/project/Cinemate/lib/utils/app_colors.dart) (*Dark Cinema Palette: `#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`*).
2. **Offline-First & Graceful Fallback:**
   - Preferensi tersimpan di storage lokal sehingga saat aplikasi dibuka kembali dalam mode offline, pilihan mata uang dan zona waktu tetap persisten.
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
