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
- **Peta & LBS:** `flutter_map` (OpenStreetMap tile layer gratis & offline friendly), `geolocator`, `latlong2`, `url_launcher`
- **Konversi & Format:** `intl` (locale IDR, USD, SGD, EUR, JPY, GBP) & penyesuaian zona waktu (WIB, WITA, WIT, London GMT/BST)
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
├── controllers/                # GetxController (CinemaController, PreferenceController, FnbController, dll.)
├── models/                     # Data class/model (CinemaModel, ShowtimeModel, FnbItemModel, TicketModel, dll.)
├── repositories/               # Repository pattern (Interface & Implementation)
├── routes/                     # AppRoutes & AppPages
├── services/                   # Service layer (LocationService, CinemaService, FnbService, MoodService, dll.)
├── utils/                      # AppColors, AppTheme, CurrencyHelper, TimezoneHelper, Validators
└── views/                      # Antarmuka UI (splash, auth, dashboard, booking, cinema, fnb, mood, profile, ticket)
assets/
├── .env.example                # Template variabel lingkungan
└── .env                        # Kredensial API (diabaikan oleh git)
docs/
└── supabase_schema.sql         # Skema database & RLS Supabase
```

---

## ✅ Status Pengerjaan (Sprint 1 s/d Sprint 4 — SELESAI 100%)

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

### 5. Epic Pesan Makanan & Minuman / F&B (FNB — PB 7 Teman)
- [x] **PB-026 (Katalog F&B Offline-First & Hive Cache — Tanpa Supabase):** Model `FnbItemModel` dengan 12 varian menu lengkap, `FnbService` berbasis Hive box `fnb_cache` (100% offline-first murni tanpa ketergantungan Supabase), banner indikator status Hive cache & timestamp sinkronisasi, filter chip kategori dinamis (*Semua*, *Snack*, *Minuman*, *Paket Combo*, *Makanan Berat*) dengan counter kuantitas menu, pencarian real-time dengan tombol clear, shimmer skeleton loading (`FnbListSkeleton`), dan penanganan empty state saat pencarian tidak ditemukan.
- [x] **PB-027 (Keranjang Pesanan F&B / Reactive Cart Management — Tanpa Supabase):** `FnbController` mengelola keranjang belanja reaktif (`cart`), penambahan/pengurangan item, persistensi otomatis ke Hive box `fnb_cache` (`active_cart` & `cart_notes`), instruksi/catatan khusus per menu (`itemNotes`), kalkulasi subtotal, biaya layanan aplikasi Rp 2.000, grand total, floating summary bar interaktif, badge keranjang di AppBar, modal bottom sheet detail keranjang (`FnbCartBottomSheet`), serta dialog konfirmasi pengosongan keranjang.
- [x] **PB-028 (Pilihan Bioskop & Metode Pengambilan F&B — Tanpa Supabase):** Layar `FnbCheckoutView` mendukung pemilihan lokasi bioskop penjualan (`availableCinemas`) dari seed/cache lokal tanpa Supabase, 2 metode pengambilan (*Ambil di Counter Concession* dengan QR voucher mandiri vs *Antar Langsung ke Studio & Kursi* oleh staf bioskop), auto-detection tiket aktif (`detectedActiveTicket`) dari Hive `tickets_cache` / `TicketsController` untuk pre-fill otomatis nama studio & nomor kursi lengkap dengan banner visual informasi tiket, text controller persisten tersinkronisasi, serta validasi form pengantaran studio & kursi sebelum checkout.
- [x] **PB-029 (Simulasi Pembayaran & E-Voucher QR Code F&B):** Integrasi transaksi ke tabel Supabase `fnb_orders` & `fnb_order_items`, penerbitan kode pickup 5 digit (`FNB-XXXXX`), serta QR Code E-Voucher (`qr_flutter`) untuk verifikasi staf bioskop.
- [x] **PB-030 (Riwayat & Pelacakan Status Pesanan F&B):** Sub-tab *"Pesanan Saya"* dengan status stepper dinamis (*Sedang Disiapkan* 🍳 $\rightarrow$ *Siap Diambil* 🍿 $\rightarrow$ *Selesai Diambil* ✅), persistensi offline ke Hive (`fnb_orders_cache`), dan tombol simulasi staf bioskop.

### 6. Epic Rekomendasi Film Berbasis Mood AI (MOD / AIL — PB 8 Teman)
- [x] **PB-031 (Layar Pemilih Mood Interaktif — Tanpa Supabase):** Banner pengantar Mood AI di `HomeTab`, navigasi ke `MoodPickerView` dengan 6 kategori emosi (*Gembira*, *Haru*, *Romantis*, *Tegang*, *Santai*, *Bosan*), visualisasi gradien estetik dinamis, highlight kartu emosi terpilih, `MoodController` reaktif, integrasi binding rute, fallback kurasi offline tanpa Supabase, dan penyimpanan Hive cache lokal.
- [x] **PB-032 (Mood-to-Genre Engine & Filter TMDB Discovery — Tanpa Supabase):** Engine rekomendasi `MoodRecommendationService` memetakan genre ID TMDB dengan filter penemuan discovery cerdas (rating $\ge 7.0$, sorting dinamis *Terpopuler* & *Rating Tertinggi*), fallback kurasi offline berkualitas tinggi dengan TTL di Hive cache tanpa Supabase, serta didukung langkah opsional Tambah Makanan F&B sebelum ringkasan pesanan tiket bioskop (FR-028 / PB-032).
- [x] **PB-033 (Hasil Rekomendasi AI & Aksi Direct Booking — Tanpa Supabase):** Kartu rekomendasi film interaktif dengan persentase kecocokan AI (*88% - 99% MATCH*), badge gradien dinamis, analisis personalisasi berbasis mood emosi pengguna, tombol *"Lihat Sinopsis"* untuk detail lengkap, tombol *"Pesan Tiket"* langsung ke alur *Book by Movie* (`Routes.bookByMovie`), serta didukung alur pemesanan F&B mandiri tanpa tiket dengan kode ambil unik 5 digit `FNB-XXXXX` dan status processing (FR-036 / PB-033).

### 7. Epic Location-Based Services & Peta Bioskop (LBS — PB 9)
- [x] **PB-042 (Deteksi Lokasi Pengguna & Izin GPS):** Service `LocationService` dengan integrasi `geolocator`, pendeteksian koordinat pengguna secara real-time, tombol "Deteksi GPS Otomatis" di `HomeTab` & `CinemaMapView`, penyimpanan koordinat terakhir ke storage lokal (`GetStorage`), dan penanganan prompt perizinan Android & iOS yang aman tanpa crash.
- [x] **PB-043 (Daftar Bioskop Terdekat Terurut Jarak):** Kalkulasi jarak realtime setiap bioskop dari koordinat pengguna dengan formula *Haversine* dan pengurutan ascending (km) yang reaktif di `CinemaController` (`getCinemasSortedByDistance`).
- [x] **PB-044 (Peta Bioskop Interaktif `flutter_map`):** Visualisasi peta interaktif OpenStreetMap (OSM) via `CinemaMapView` (`Routes.cinemaMap`) tanpa API key berbayar, marker posisi user (pin biru dengan efek glowing), dan pin bioskop (merah/emas) yang interaktif memunculkan bottom modal detail bioskop.
- [x] **PB-045 (Filter Radius Jarak Bioskop):** Filter radius dinamis: `1 km`, `3 km`, `5 km`, `10 km`, `25 km`, dan `Semua Jarak`. Penanda peta & daftar bioskop tersaring secara real-time disertai indikator jumlah bioskop yang ditemukan.
- [x] **PB-046 (Rute & Navigasi Eksternal ke Google Maps):** Tombol *"Petunjuk Arah"* pada kartu & peta bioskop yang membuka aplikasi Google Maps eksternal via `url_launcher` dengan koordinat tujuan bioskop dan fallback geo URI.
- [x] **PB-047 (Fallback Offline & Pilihan Lokasi Manual):** Penyedia 10 titik acuan kota manual (Jakarta Pusat, Jakarta Selatan, Jakarta Utara, Depok, Tangerang, Bandung, Surabaya, Yogyakarta, Medan, Bali) agar LBS tetap berfungsi 100% mulus saat offline atau saat izin GPS ditolak.

### 8. Epic Konversi Mata Uang, Zona Waktu, Pintasan F&B & Profil (KNV / PRF / FNB — PB 10)
- [x] **PB-048 (Konversi Mata Uang Dinamis):** Helper `CurrencyHelper` mendukung konversi harga tiket dan F&B ke IDR, USD, SGD, EUR, JPY, dan GBP, lengkap dengan metadata waktu pembaruan kurs (TTL cache 12 jam) dan formatting locale akurat.
- [x] **PB-049 (Penyesuaian Zona Waktu Jam Tayang Film):** Helper `TimezoneHelper` menyesuaikan jadwal tayang film di seluruh aplikasi ke zona waktu pilihan (WIB UTC+7, WITA UTC+8, WIT UTC+9, dan London GMT/BST UTC+0/+1) lengkap dengan konversi jam rollover tengah malam.
- [x] **PB-050 (Selector Preferensi Mata Uang & Waktu di Profil):** `PreferenceController` reaktif dan modal bottom sheet pemilih mata uang & zona waktu di `ProfileTab` yang persisten ke local storage (`GetStorage`) serta pratinjau live konversi.
- [x] **PB-034 (Pintasan Menu F&B dari Halaman Lain):** Tombol pintasan *"Pesan F&B di Bioskop Ini"* di `TicketDetailView` untuk tiket aktif dan card pintasan `+ Tambah Popcorn & Minuman (F&B)` di `OrderSummaryView` yang otomatis mengunci bioskop terpilih.
- [x] **PB-035 (Stepper Pelacakan & Simulasi Status Pesanan F&B):** Layar `FnbOrderDetailView` dengan stepper visual dinamis (*Sedang Disiapkan* 🍳 $\rightarrow$ *Siap Diambil* 🍿 $\rightarrow$ *Selesai Diambil* ✅), E-Voucher QR Code, dan tombol simulasi status staf bioskop.
- [x] **PB-062 (Form Edit Profil Pengguna):** Layar `EditProfileView` (`Routes.editProfile`) dengan form edit nama lengkap, nomor telepon, dan selector lencana avatar anggota (Cinephile, VIP Gold, Director, Popcorn Fan, Sci-Fi Star) yang tersimpan di sesi lokal.

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
5. **Jalankan pengujian unit (Semua 79 Unit Test Wajib Passed):**
   ```bash
   flutter test
   ```
6. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

## 🎯 Rekomendasi & Pembagian Tugas Adil untuk Developer Selanjutnya (PB 11 & PB 12)

> **⚖️ Prinsip Pembagian Tugas yang Adil & Transparan:**  
> Seluruh backlog **PB 1 s/d PB 10 (total 40+ user stories)** telah tuntas 100% dengan **79 unit tests lolos (100%)** dan 0 issue statis `dart analyze`.  
> Untuk sprint berikutnya, developer partner ditugaskan menyelesaikan **2 PB berikutnya (PB 11 dan PB 12)**:

---

### 📦 Tugas Teman Selanjutnya 1: Epic Pencarian & Filter Katalog (SRC — PB 11)
*Menuntaskan modul pencarian global lintas film, bioskop, dan F&B (PB-051 s.d. PB-055)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria |
| :---: | :---: | :--- | :--- |
| 1 | **PB-051** | Pencarian Multi-Entitas dengan Debounce | Input search bar di dashboard dengan debounce 300ms untuk mencari film, bioskop, dan menu F&B sekaligus. |
| 2 | **PB-052** | Filter Pencarian Multi-Kriteria | Filter hasil berdasarkan genre, rating ($\ge 7.0$), rentang harga tiket, dan kota bioskop. |
| 3 | **PB-053** | Pengurutan Hasil Pencarian | Sorting hasil pencarian berdasarkan *Rating Tertinggi*, *Paling Populer*, *Harga Termurah*, dan *Jarak Terdekat*. |
| 4 | **PB-054** | Riwayat Pencarian Terakhir | Menyimpan 5 pencarian terakhir ke `GetStorage` / Hive dengan tombol hapus riwayat individual & hapus semua. |
| 5 | **PB-055** | State Kosong & Skeleton Loading | Tampilan empty state ramah ilustrasi saat pencarian tidak ditemukan serta skeleton loading saat proses pencarian. |

- **Target File yang Dikerjakan:**
  - `lib/controllers/search_controller.dart`
  - `lib/views/search/search_view.dart`
  - `test/search_filter_test.dart`

---

### 📦 Tugas Teman Selanjutnya 2: Epic Notifikasi Lokal & Pengingat Jadwal (NTF — PB 12)
*Menuntaskan modul notifikasi lokal transaksi dan pengingat tayang film (PB-056 s.d. PB-060)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria |
| :---: | :---: | :--- | :--- |
| 1 | **PB-056** | Notifikasi Konfirmasi Pemesanan | Notifikasi instan saat checkout tiket bioskop atau pesanan F&B berhasil dengan rincian kode booking. |
| 2 | **PB-057** | Notifikasi Pengingat Jadwal Film Terjadwal | Penjadwalan alarm notifikasi lokal otomatis H-2 jam sebelum film dimulai menggunakan `flutter_local_notifications`. |
| 3 | **PB-058** | Pengaturan Izin & Preferensi Notifikasi di Profil | Toggle on/off notifikasi tiket dan promo di `ProfileTab` yang persisten di storage lokal. |
| 4 | **PB-059** | Deep Link Notifikasi ke E-Ticket | Mengetuk notifikasi konfirmasi langsung membuka halaman `TicketDetailView` tiket bersangkutan. |
| 5 | **PB-060** | Notifikasi Penawaran Promo F&B Mingguan | Simulasi notifikasi promosi diskon F&B berkala untuk meningkatkan engagement pengguna. |

- **Target File yang Dikerjakan:**
  - `lib/services/notification_service.dart`
  - `test/notification_service_test.dart`

---

### 🌿 Panduan Branching Git untuk Teman
Tarik update terbaru dari `main` dan buat branch baru untuk PB 11 & PB 12:
```bash
git checkout main
git pull origin main

# Buat branch pengerjaan baru:
git checkout -b feat/pb-051-060-search-and-notification
```

---

### 📌 Standar Koding & Pengujian Sebelum Pull Request (PR)

1. **Arsitektur GetX OOP & 100% Offline-First:**
   - Pisahkan logika ke `Controller`, data/cache ke `Service`/`Utils`, dan antarmuka ke `View`.
   - Wajib berjalan mulus dalam mode offline dengan fallback data lokal / Hive tanpa Supabase.
   - Gunakan palet warna konsisten dari `AppColors` (*Dark Cinema Palette: `#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`*).
2. **Checklist Wajib Sebelum Commit & Push:**
   ```bash
   # 1. Pastikan tidak ada error atau warning:
   dart analyze lib test

   # 2. Jalankan seluruh unit test (wajib 100% passed):
   flutter test

   # 3. Format kode:
   dart format lib test
   ```
3. **Keamanan Kredensial:**
   - Jangan pernah melakukan commit berkas `assets/.env`.
