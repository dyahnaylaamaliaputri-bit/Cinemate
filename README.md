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

## ✅ Status Pengerjaan (Sprint 1, Sprint 2, & Sprint 3 — SELESAI 100%)

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

### 5. Epic Pesan Makanan & Minuman / F&B (FNB)
- [x] **PB-026 (Katalog F&B Supabase & Hive Offline Cache):** `FnbItemModel`, `FnbService` terintegrasi Supabase `fnb_items` & fallback offline Hive cache (`fnb_cache`), sub-tab katalog dengan filter kategori interaktif (*Semua*, *Snack*, *Minuman*, *Paket Combo*, *Makanan Berat*) dan pencarian live.
- [x] **PB-027 (Keranjang Pesanan F&B / Reactive Cart Management):** `FnbController` mengelola keranjang reaktif, penambahan/pengurangan item, catatan khusus per menu, subtotal, biaya layanan, dan floating summary checkout bar di bagian bawah layar.
- [x] **PB-028 (Pilihan Bioskop & Metode Pengambilan):** `FnbCheckoutView` mendukung pemilihan bioskop concession dan 2 metode pengambilan: *Ambil di Counter Concession* atau *Antar ke Studio & Kursi* (otomatis membaca data studio dan kursi).
- [x] **PB-029 (Simulasi Pembayaran & E-Voucher QR Code F&B):** Integrasi transaksi ke tabel Supabase `fnb_orders` & `fnb_order_items`, penerbitan kode pickup 5 digit (`FNB-XXXXX`), serta QR Code E-Voucher (`qr_flutter`) untuk verifikasi staf bioskop.
- [x] **PB-030 (Riwayat & Pelacakan Status Pesanan F&B):** Sub-tab *"Pesanan Saya"* dengan status stepper dinamis (*Sedang Disiapkan* ⏳ $\rightarrow$ *Siap Diambil* ✨ $\rightarrow$ *Selesai Diambil* ✅), persistensi offline ke Hive (`fnb_orders_cache`), dan tombol simulasi staf bioskop.

### 6. Epic Rekomendasi Film Berbasis Mood AI (MOD)
- [x] **PB-031 (Layar Pemilih Mood Interaktif):** Banner pengantar Mood AI di `HomeTab`, navigasi ke `MoodPickerView` dengan 6 kategori emosi (*Gembira*, *Haru*, *Romantis*, *Tegang*, *Santai*, *Bosan*), visualisasi gradien estetik, dan highlight kartu emosi terpilih.
- [x] **PB-032 (Mood-to-Genre Engine & Filter TMDB Discovery):** `MoodRecommendationService` memetakan genre ID TMDB dan memanggil discovery API `/discover/movie` dengan rating $\ge 7.0$, dilengkapi fallback kurasi offline berkualitas tinggi jika jaringan offline/limit.
- [x] **PB-033 (Hasil Rekomendasi AI & Aksi Direct Booking):** Kartu rekomendasi film dengan persentase kecocokan AI (*88% - 99% MATCH*), analisis personalisasi berbasis mood, tombol sinopsis, dan tombol *"Pesan Tiket"* yang langsung membuka alur *Book by Movie* (`Routes.bookByMovie`).

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
5. **Jalankan pengujian unit (Semua 41 Unit Test Wajib Passed):**
   ```bash
   flutter test
   ```
6. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

## 🎯 TUGAS SELANJUTNYA UNTUK ANGGOTA TIM (2 PB)

> **Pesan untuk Rekan Tim:**  
> Halo! Pengerjaan **Sprint 3 (PB 5 - Pemesanan F&B dan PB 6 - Rekomendasi Mood AI)** sudah rampung 100% dan seluruh 41 unit test sudah lolos pengujian.  
> Untuk giliran kamu selanjutnya, silakan kerjakan **2 Product Backlog** pada **Sprint 4 (Epic Profil & Preferensi Regional)**: **PB-048 (Konversi Mata Uang)** dan **PB-049 (Penyesuaian Zona Waktu)**.  
> Panduan implementasi, kriteria keberterimaan (*acceptance criteria*), dan file terkait sudah disiapkan di bawah ini:

---

### 🌿 Panduan Branching Git
Silakan tarik update terbaru dari `main` dan buat branch baru:
```bash
git pull origin main
git checkout -b feat/pb-048-049-currency-timezone
```

---

### 💵 1. PB-048: Konversi Mata Uang Dinamis (Currency Preference & Conversion)
- **Tujuan:** Pengguna dapat mengubah mata uang tampilan di seluruh aplikasi (tiket bioskop, jajanan F&B, dan ringkasan pembayaran) secara instan dan reaktif.
- **Mata Uang yang Didukung:**
  1. **IDR (Rp)** — Rupiah Indonesia *(Default kurs: 1.0)*
  2. **USD ($)** — Dollar Amerika Serikat *(Contoh kurs konversi: 1 USD = Rp 16.000)*
  3. **SGD (S$)** — Dollar Singapura *(Contoh kurs konversi: 1 SGD = Rp 12.000)*
  4. **EUR (€)** — Euro Uni Eropa *(Contoh kurs konversi: 1 EUR = Rp 17.500)*
- **Penyimpanan Preferensi (GetStorage):**
  - Simpan preferensi pengguna ke `GetStorage` melalui `StorageService` dengan key `'currency_preference'` (default: `'IDR'`).
- **File & Komponen yang Dibuat / Dimodifikasi:**
  - `lib/utils/currency_helper.dart` (Buat helper baru yang reaktif dengan Rx string, method `formatPrice(int priceInIdr)`, `formatTicketPrice(...)`, dan `convertFromIdr(...)`).
  - `lib/views/dashboard/tabs/profile_tab.dart` (Tambahkan kartu/modal "Pilihan Mata Uang" dengan radio button atau selection modal).
  - Integrasikan helper harga ke:
    - Katalog F&B: `lib/views/dashboard/tabs/fnb_tab.dart`
    - Checkout F&B: `lib/views/fnb/fnb_checkout_view.dart`
    - Booking Tiket: `lib/views/booking/order_summary_view.dart` & `lib/views/booking/book_by_cinema_view.dart`
- **Pengujian Unit Baru:**
  - Buat `test/currency_conversion_test.dart` untuk memverifikasi kalkulasi konversi IDR ke USD, SGD, EUR, serta format simbolnya.

---

### ⏰ 2. PB-049: Penyesuaian Zona Waktu Penayangan Film (Timezone Preference & Shift)
- **Tujuan:** Menyesuaikan jadwal penayangan bioskop di seluruh aplikasi sesuai zona waktu lokal yang dipilih pengguna.
- **Zona Waktu yang Didukung:**
  1. **WIB (UTC+7)** — Waktu Indonesia Barat *(Default zona bioskop)*
  2. **WITA (UTC+8)** — Waktu Indonesia Tengah *(+1 jam dari waktu tayang default)*
  3. **WIT (UTC+9)** — Waktu Indonesia Timur *(+2 jam dari waktu tayang default)*
  4. **UTC (GMT+0)** — Greenwich Mean Time *(-7 jam dari waktu tayang default)*
- **Penyimpanan Preferensi (GetStorage):**
  - Simpan preferensi zona waktu pengguna ke `GetStorage` melalui `StorageService` dengan key `'timezone_preference'` (default: `'WIB'`).
- **File & Komponen yang Dibuat / Dimodifikasi:**
  - `lib/utils/timezone_helper.dart` (Buat helper konversi jam penayangan bioskop dan penambahan label zona, misal: `14:00 WIB` $\rightarrow$ `15:00 WITA` jika pengguna memilih WITA).
  - `lib/views/dashboard/tabs/profile_tab.dart` (Tambahkan kartu/modal "Pilihan Zona Waktu").
  - Integrasikan helper jam tayang ke:
    - Jadwal bioskop: `lib/views/booking/book_by_cinema_view.dart` & `lib/views/booking/book_by_movie_view.dart`
    - Detail E-Ticket: `lib/views/ticket/ticket_detail_view.dart`
    - Riwayat Tiket: `lib/views/dashboard/tabs/tickets_tab.dart`
- **Pengujian Unit Baru:**
  - Buat `test/timezone_format_test.dart` untuk memverifikasi pergeseran jam penayangan dari WIB ke WITA, WIT, dan UTC.

---

### 📌 Standar Koding & Pengujian Sebelum Pull Request (PR)

1. **Arsitektur GetX OOP:**
   - Pisahkan logika ke `Controller`, data/helper ke `Utils`/`Service`, dan antarmuka ke `View`.
   - Gunakan warna dari `AppColors` (*Dark Cinema Palette: `#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`*).
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
