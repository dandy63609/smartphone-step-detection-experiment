# Stradio: Product Roadmap, UI Revamp & Navigation Architecture

> **"Stride + Audio: Movement Becomes Music"**  
> Dokumen ini memuat cetak biru teknis dan arsitektur desain antarmuka (UI/UX) untuk aplikasi **Stradio**. Dokumen ini menggabungkan sains eksperimen biomekanika langkah kaki (*adaptive threshold algorithms*) dengan pengalaman pemutar musik reaktif (*reactive sports-music audio app*).

---

## 1. Visi Produk & Filosofi Desain `[STATUS: DONE]`

Stradio adalah aplikasi kebugaran generasi baru yang menyelaraskan setiap langkah lari pengguna dengan ritme musik adaptif. Pendekatan desain Stradio menolak tampilan eksperimen yang kaku maupun *AI visual slop*, melainkan mengadopsi standar desain produk kelas dunia (*crafted by a designer*) dengan kontras tinggi, navigasi ergonomis untuk jempol saat bergerak, serta hierarki visual yang bernapas (*spacious and focused*).

### Brand Identity & Design Tokens

* **Color Palette (Stradio 03 Palette):**
  * **Midnight (`#191923`):** Kanvas gelap utama yang mendalam dan hemat daya layar OLED.
  * **Warm Ivory (`#F5F0E8`):** Tipografi utama untuk keterbacaan tinggi tanpa membuat mata lelah.
  * **Sonic Coral (`#FF765F`):** Warna energi utama untuk tombol *Play/Pause*, *pulse impact*, dan aksi primer.
  * **Rhythm Violet (`#A995DB`):** Aksen harmonis untuk indikator tempo BPM, gelombang frekuensi, dan labs.
  * **Supporting Indigo (`#46509E`):** Warna penopang gradien untuk kartu visualizer dan elemen status.
  * **Surface Dark (`#232331`) & Surface Subtle (`#2D2E40`):** Lapisan kartu bertingkat dengan border halus `borderDark` (`#37384E`).

* **Tipografi (Stradio 04 Typography):**
  * **Sora:** Font display modern, bold, dan punchy untuk angka metrik besar (langkah, BPM) dan judul utama.
  * **Inter:** Font fungsional dengan legibilitas superior untuk label data, status mikro, dan teks deskripsi.

---

## 2. Acuan Desain Resmi (Visual References) `[STATUS: DONE]`

Arsitektur UI Stradio mengacu pada tiga referensi visual utama yang disimpan di repositori, serta dirinci kontrak visual dan pengalamannya pada `docs/DESIGN.md` dan `docs/EXPERIENCE.md`:

```
assets/images/
├── stradio-reference-1.png             (Referensi 1: Ergonomi Layar Player & Library List)
├── stradio-reference-2.png             (Referensi 2: Hero Waveform Center Play & Floating Navigation)
└── stradio-reference-3-navigation.png  (Referensi 3: Variasi Floating Island Bottom Navigation)
```

### Referensi 1: `stradio-reference-1.png` (Dribbble Audio & Sports Companion)
* **Penerapan pada Stradio:**
  * **Ergonomi Active Session (Layar 1):** Penataan kartu visualizer di bagian atas dengan sudut lengkung besar (~24px), diikuti deretan kapsul utilitas mini horizontal (*segmented utility pills*), serta penempatan tombol aksi besar di area jangkauan jempol bawah.
  * **Katalog Suara & Riwayat (Layar 2 & 3):** Struktur kartu daftar horizontal (*stacked cards*) dengan thumbnail visual di sisi kiri dan metrik ringkas di sisi kanan, serta baris *filter chips* horizontal di bagian atas (`All`, `Brisk Walk`, `Tempo Jog`, `Neon Stride`).

### Referensi 2: `stradio-reference-2.png` (Pinterest Modern Beat Studio)
* **Penerapan pada Stradio:**
  * **Hero Waveform dengan Center Floating Play Button:** Penempatan tombol Play/Pause bulat di pusat area gelombang visualizer audio saat standby. Ketika ditekan, visualizer menjadi hidup dan bergelombang dinamis mengikuti entakan kaki.
  * **Punchy Asymmetrical Greeting:** Judul header dengan aksen warna ganda: `Find Your` (Warm Ivory) + `Rhythm` (Sonic Coral).
  * **Quick Actions Row:** Baris kartu tindakan cepat horizontal ber-radius melengkung untuk akses kilat ke preset lari, kalibrasi sensor, atau generator ritme.
  * **Floating Island Bottom Navigation Bar:** Navigasi bawah melayang (*floating pill*) yang tidak menempel kaku ke dasar layar, memberikan kesan visual modern dan elegan.

---

## 3. Cetak Biru Visual ASCII & Sistem Desain Baru (Zero-Scroll "Unified Stride Deck") `[STATUS: DONE - SPRINT 2 POLISH PENDING]`

Bagian ini memuat visualisasi tata letak ASCII terkini untuk **Layar Utama (`ActiveRunScreen`)**, hierarki bentuk/sudut lengkung (*shape & border system*), serta **Komparasi Tema Light/Dark**. Seluruh rancangan disusun bebas dari *AI slop*, mengadopsi 100% karakter produk premium dari **Referensi 1** dan **Referensi 2**, serta memadukan identitas sejati **Stradio (Strava + Audio)**.

### 3.1 Visualisasi ASCII Terkini: Zero-Scroll "Unified Stride Deck"

Desain ini telah divalidasi dan diterapkan di kode nyata:
* **Branding Asli:** Mengganti avatar dummy "Mark C." dengan **Logo Resmi Stradio** + Status Pill dinamis.
* **Slogan & Subtitle Kuat:** *"Run the Vibe"* + *"Neon Stride · Adaptive Stride"* (bebas dari teks BPM redundan).
* **Waveform Rhythm Core:** Menampilkan **Rhythm Core Emblem (`( ◎ )`)** non-button di tengah visualizer yang berdenyut reaktif mengikuti tempo & entakan kaki.
* **Kontrol Terpusat (Zero-Ambiguity):** Seluruh aksi kendali lari (*Play/Pause* bulat Sonic Coral dan *Finish Run* stadium pill) berada strictly 100% di **Bottom Thumb Zone**.

```
┌─────────────────────────────────────────────────────────────┐
│ [ STRADIO LOGO ]  [● PAUSED]          [ ☀/☾ ] [ ⚗ Labs ]   │
├─────────────────────────────────────────────────────────────┤
│ Run the Vibe                                                │
│ Neon Stride · Adaptive Stride                               │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  AUDIO-STRIDE WAVEFORM                    118 BPM TARGET│ │
│ │                                                         │ │
│ │   || | |||| ||| ||||||| ( ◎ ) ||||||| ||| |||| | ||     │ │
│ │   (Rhythm Core Emblem: Denyut ritme tempo & hentakan)   │ │
│ │                                                         │ │
│ │  Cadence Sync: 0 SPM                    ● Standby Preview│ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  STRIDE GOAL                              0 / 100 (0%)  │ │
│ │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░  0%         │ │
│ │                                                         │ │
│ │        0                    0 SPM           00:00       │ │
│ │      STEPS                 CADENCE          TIME        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │   ╭─────────╮                                           │ │
│ │   │ ▶ PLAY  │        [        FINISH RUN        ]       │ │
│ │   ╰─────────╯                                           │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Spesifikasi Bentuk: 100% Borderless & Corner Radius Hierarchy

Stradio menolak penggunaan border garis abu-abu 1px kaku khas AI slop. Seluruh pemisahan bidang kartu dilakukan menggunakan **Tonal Contrast** dan **Diffused Ambient Shadow**.

#### 1. Aturan Borderless & Elevasi Lembut
* **Border:** `BorderSide.none` pada seluruh kartu dan modal.
* **Separasi Bidang:** Diciptakan melalui kontras alas Warm Ivory (`#F7F6F2`) dengan permukaan kartu Pure White (`#FFFFFF`), dipertegas oleh bayangan difus 2-lapis:
  ```dart
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black ambient
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000), // 2% black contact
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  ```

#### 2. Hierarki Sudut Lengkung (Deep Organic Squircle)

| Level | Token | Nilai | Elemen UI | Alasan Desain (Ref 1 & 2) |
| :--- | :--- | :--- | :--- | :--- |
| **Level 1** | `StradioRadii.hero` | **28.0 px** | Waveform Deck, Modal Bottom Sheet, Cover Art | Memberikan siluet batu kerikil halus (*smooth pebble*) yang sangat modern dan ramah mata ala Ref 2. |
| **Level 2** | `StradioRadii.squircle` | **20.0 px** | Stride Goal Deck, Quick Action Tiles | Bentuk squircle proporsional (mirip launchpad MPC audio) yang tactile dan nyaman saat dipandang. |
| **Level 3** | `StradioRadii.card` | **16.0 px** | Panel diagnostik internal, kartu riwayat | Radius standar fungsional untuk kartu anak (*nested containers*). |
| **Level 4** | `StradioRadii.pill` | **999.0 px** | Tombol CTA (Finish), Status Badge, Floating Nav | Bentuk kapsul penuh (*stadium*) untuk seluruh elemen yang bisa disentuh jempol, memberi kontras tegas terhadap kartu squircle. |

### 3.3 Komparasi Palet: Warm Organic Dual Theme

```
┌───────────────────────────────────────┬───────────────────────────────────────┐
│ LIGHT THEME (Warm Ivory - Ref 1 & 2)  │ DARK THEME (Deep Obsidian - Night Run)│
├───────────────────────────────────────┼───────────────────────────────────────┤
│ • Canvas: Warm Ivory (`#F7F6F2`)      │ • Canvas: Deep Obsidian (`#121217`)   │
│ • Surfaces: Pure White (`#FFFFFF`)    │ • Surfaces: Charcoal Card (`#1E1E26`) │
│ • Typography: Midnight (`#191923`)    │ • Typography: Warm Ivory (`#F5F0E8`)  │
│ • Secondary: Muted Slate (`#666680`)  │ • Secondary: Soft Silver (`#9E9EB2`)  │
│ • Accent 1: Sonic Coral (`#FF765F`)   │ • Accent 1: Sonic Coral (`#FF765F`)   │
│ • Accent 2: Rhythm Violet (`#8B72DE`) │ • Accent 2: Rhythm Violet (`#A995DB`) │
│ • Elevation: Soft Warm Shadows        │ • Elevation: Tonal Surface Separation │
│   (100% Borderless, tanpa garis 1px)  │   (Kontras lembut, tanpa glow norak)  │
└───────────────────────────────────────┴───────────────────────────────────────┘
```

### 3.4 Pemetaan Token ke `lib/theme/stradio_theme.dart`

1. **`StradioRadii`:** Menambahkan `hero = 28.0`, `squircle = 20.0`, dan `pill = 999.0`.
2. **`StradioColors`:** Menambahkan token Dark Theme (`obsidianCanvas = Color(0xFF121217)`, `charcoalSurface = Color(0xFF1E1E26)`).
3. **`StradioTheme.darkTheme`:** Mengimplementasikan tema gelap organik nyata alih-alih sekadar alias `lightTheme`.
4. **`cardTheme`:** Mengunci `side: BorderSide.none` dan elevasi 0 dengan `StradioColors.cardShadow`.

---

## 4. Rencana Navigasi, Onboarding & Layar End-User (`v0.2.0` Roadmap) `[STATUS: IN PROGRESS (MILESTONE 4 SELESAI)]`

Pasca rilis `v0.1.7` (versi terakhir fase semi-eksperimen), Stradio bertransformasi menjadi aplikasi kebugaran untuk **pengguna akhir non-teknis** dengan arsitektur dwibahasa (**English** default + **Bahasa Indonesia**), kontrak visual pada `docs/DESIGN.md`, dan kontrak perilaku pada `docs/EXPERIENCE.md`.

### 4.1 First-Run Onboarding (Tanpa Login / OAuth)
Pengguna baru langsung disambut alur onboarding singkat 2 langkah sebelum memasuki `Home`:
1. **Welcome & Local Privacy Promise:** Penjelasan ramah bahwa seluruh data profil pribadi (nama panggilan, tinggi badan, riwayat olahraga) disimpan **100% lokal di perangkat** tanpa akun atau login. Pilihan bahasa (`English` default / `Bahasa Indonesia`) tersedia sejak awal.
2. **Quick Personalization:**
   - **Nama Panggilan:** Opsional dengan tombol **Skip** (otomatis memakai nama default `"Runner"` untuk sapaan di `Home`).
   - **Tinggi Badan (cm):** Opsional untuk kalibrasi estimasi panjang langkah dan jarak (fallback ke standar `0.74 m / 0.95 m`).
   - **Target Langkah Harian:** Pilihan preset cepat atau input angka custom, serta opsi mode *Open Goal*.
   - **Anonymous Telemetry Toggle (PostHog):** Default **ON** dengan toggle yang dapat dimatikan langsung dan penjelasan transparan bahwa hanya metrik performa & penggunaan anonim yang dikirim (nama dan file sensor mentah tidak pernah dikirim). Project API key disuntikkan saat build melalui `--dart-define=POSTHOG_API_KEY` (GitHub Secrets + `.env` lokal yang di-ignore Git), bukan di-hardcode di repositori.

### 4.2 Root Navigation Shell (Floating Island 5-Slot per Referensi 3)
Aplikasi dibungkus oleh **Root Shell Navigation** menggunakan bilah navigasi melayang (*Floating Island Bottom Navigation* mengacu pada `stradio-reference-3-navigation.png` varian baris kanan bawah):

```
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│                   KONTEN LAYAR YANG AKTIF                     │
│        (Dengan bottom scroll clearance agar tidak tertutup)   │
├───────────────────────────────────────────────────────────────┤
│    ┌─────────────────────────────────────────────────────┐    │
│    │  [Home]    [Music]        ╭─────╮       [Chart]   [Gear]│
│    │  Home     Library         │  ▶  │      Activity  Settings│    │
│    │                           ╰─────╯                   │    │
│    │                             Run                     │    │
│    └─────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

### 4.3 Rincian 5 Bagian Utama Navigasi & Layar Pendukung (Kiri ke Kanan):

#### 1. Tab `Home` (Dashboard Pelari)
- **Header Asimetris (Referensi 2):** Sapaan personal dwibahasa (*"Hello again, [Nama]"* / *"Halo lagi, [Nama]"*) bersama tombol cepat pengubah tema Light/Dark.
- **Kartu Progres Harian Akumulatif:** Menampilkan total langkah akumulatif pada hari kalender berjalan dibanding target harian (atau ringkasan bebas jika *Open Goal*), jarak tempuh nyata, dan waktu aktif hari ini.
- **Quick Start Actions:** Kartu pintas non-teknis (*Brisk Walk 118 BPM*, *Tempo Jog 145 BPM*, *Neon Stride 165 BPM*) yang langsung membuka sesi lari aktif.

#### 2. Tab `Library` (Katalog Tema Soundscape Bergaya Aplikasi Musik)
- Mengadopsi layout daftar kartu musik modern dari **Referensi 1 (Layar 2 & 3)** dengan filter chips tempo di atas (`All`, `Chill`, `Jog`, `Fast`, `Favorites`).
- Berfungsi sebagai **placeholder siap audio** dengan daftar tema (*Chill Walk 110 BPM*, *Lo-Fi Pace 118 BPM*, *Tempo Jog 145 BPM*, *Neon Stride 165 BPM*, *Sprint Surge 180 BPM*).
- Setiap baris memiliki thumbnail artwork/gelombang, nama tema, deskripsi vibe, badge BPM, tombol **Favorit**, dan tombol **Preview** jujur (memicu animasi gelombang + status bahwa file audio tim segera diintegrasikan sambil mengaktifkan tempo tersebut untuk sesi lari).

#### 3. Center Elevated Action: `( RUN )` -> `ActiveRunScreen` (Full-Screen)
- **Desain & Ergonomi (Referensi 3):** Lingkaran menonjol berwarna **Sonic Coral (`#FF765F`)** di tengah bilah navigasi bawah dengan **label teks kecil `"Run"` / `"Lari"`** di bawah lingkaran.
- **Alur Target Sesi:** Jika pengguna memakai *Daily Target*, menekan `( RUN )` menawarkan opsi cepat **Continue Daily Target** (melanjutkan sisa target langkah hari ini) atau **Open Goal** (tanpa batas). Jika target tercapai di tengah jalan, sesi tetap berjalan mulus tanpa berhenti paksa.
- **Mesin Deteksi & UI Bersih:** Menggunakan **`A1 (Adaptive Midpoint Raw)`** sebagai penghitung langkah konsumen utama. Membuka `ActiveRunScreen` secara full-screen (tanpa bottom nav). Tombol `Labs` serta kode `A1`/`B1` disembunyikan sepenuhnya saat Developer Mode OFF.
- **Post-Run (`PostRunSummaryScreen`):** Versi konsumen menampilkan Steps, Duration, Cadence, Distance, Rhythm Score, dan grafik konsistensi. Kartu 4-Algorithm Scoreboard hanya tampil ketika Developer Mode ON.

#### 4. Tab `Activity` (Jurnal Latihan & Akumulasi Harian)
- Menampilkan progres harian akumulatif, grafik tren mingguan dari data lokal nyata, serta daftar riwayat sesi (*stacked cards* dengan filter `All`, `Walking`, `Jogging`).
- Mengetuk kartu membuka ringkasan sesi bersih (`PostRunSummaryScreen` mode konsumen) tanpa istilah *Margin of Error 100 Langkah* atau `Participant ID`.
- **Optimasi Penyimpanan & Kecepatan:** Saat **Developer Mode OFF**, sesi hanya menyimpan **ringkasan ringan** (`summary` + cadence buckets) agar penyimpanan ponsel hemat dan pembacaan daftar `Activity` berlangsung instan.

#### 5. Tab `Settings` & Hidden Developer Mode
- **Menu End-User:**
  - **Profile & Language:** Ubah nama panggilan, tinggi badan, dan bahasa (`English` / `Bahasa Indonesia`).
  - **Workout Defaults:** Pilihan target harian / Open Goal, mode aktivitas default, serta posisi bawa HP (*In Hand* / *In Pocket*).
  - **Appearance & Device:** Toggle Light/Dark Theme, Lockscreen Workout Controls, dan panduan singkat optimasi baterai Android.
  - **Privacy & Storage:** Toggle PostHog Anonymous Telemetry (default ON) dan tombol *Clear Workout History* dengan dialog konfirmasi aman.
- **Hidden Developer Mode (Masuk 7-Tap, Keluar 1-Switch):**
  - Ketuk teks **App Version** sebanyak **7 kali** di bagian bawah `Settings` untuk membuka kartu **`Developer & Research Tools`**.
  - Saat Developer Mode **ON**: perekaman raw accelerometer 100 Hz diaktifkan kembali ke file terpisah agar siap ekspor CSV, tombol `Labs` (`SensorLabsSheet`) muncul di `ActiveRunScreen`, Scoreboard 4-Algoritma tampil di `PostRunSummaryScreen`, dan akses ke 5 layar Legacy Material 3 (`LegacyExperimentShell`) tersedia.
  - **Keluar:** Cukup geser switch **`Developer Mode`** di bagian paling atas kartu Developer & Research Tools ke posisi **OFF** untuk langsung kembali ke tampilan konsumen bersih.

---

## 5. Roadmap Eksekusi (7 Milestone) `[STATUS: DONE (M1-M7 SELESAI)]`

1. **Milestone 1 (SELESAI - Commit `9153502`):** Revamp UI `ActiveRunScreen` (`lib/screens/stradio/active_run_screen.dart`).
   - Hero Waveform Card dengan tombol Play melayang di tengah saat standby, Segmented Utility Pills (BPM, Placement, Algorithm), angka langkah Sora 68px, target langkah, dan secondary metrics card.
2. **Milestone 2 (SELESAI - Commit `7da690f`):** Revamp UI `PostRunSummaryScreen` (`lib/screens/stradio/post_run_summary_screen.dart`).
   - Header pencapaian ritmis, Stradio Signature Circular Rhythm Visualizer, matriks statistik latihan (Steps, Durasi, SPM, Speed, Jarak), grafik konsistensi ritme langkah, mini Scoreboard akurasi 4 algoritma (A1-B2), serta tombol aksi "Save & Finish Workout" non-blocking.
3. **Milestone 3 (SELESAI - Commit `7da690f`):** Revamp UI `SensorLabsSheet` (`lib/screens/stradio/sensor_labs_sheet.dart`).
   - Panel diagnostik biomekanika & instrumen laboratorium eksperimen: Toggle Developer Mode Live Overlay, diagnostik kesehatan sensor 100 Hz, kalibrasi Target Ground Truth, pemilih algoritma, ekspor dataset CSV lengkap, dan reset data sampel.
4. **Milestone 4 (SELESAI - Tahap 4A, 4B, 4C & 4D):** `Onboarding`, `i18n (EN/ID)`, `RootNavigationShell` & `HomeScreen`.
   - Implementasi First-Run Onboarding 2 langkah (`lib/screens/stradio/onboarding_screen.dart`: privasi lokal, bahasa EN/ID, nama opsional fallback `"Runner"`, tinggi badan, target harian, toggle PostHog default ON), kamus lokalisasi modular per bahasa (`lib/l10n/`), pemisahan penyimpanan summary vs raw samples, Floating Island 5-tab navigation (`lib/screens/stradio/root_navigation_shell.dart` sesuai `stradio-reference-3-navigation.png` dengan label `"Run"`/`"Lari"` & Pre-Run Goal Selector Sheet), `HomeScreen` (`lib/screens/stradio/home_screen.dart`) dengan cincin progres akumulasi langkah harian dan Quick Start, serta penyembunyian elemen riset (`Labs`, badge `A1 Midpoint`, dan `4-Algorithm Scoreboard` di `PostRunSummaryScreen`) saat Developer Mode OFF.
5. **Milestone 5 (SELESAI - Tahap 5A & 5B):** `LibraryScreen` & Integrasi Preset Tempo.
   - Ekstraksi dan pengayaan katalog tema bergaya aplikasi musik (`lib/screens/stradio/library_screen.dart`: *Chill Walk 110*, *Lo-Fi Pace 118*, *Tempo Jog 145*, *Neon Stride 165*, *Sprint Surge 180*) dengan Active Soundscape Hero Card (`28px` Pebble, tombol 1-tap `Run This Tempo` + tombol pemilih target sesi `Pre-Run Goal Selector Sheet`), filter chips (`All`, `Chill`, `Jog`, `Fast`, `Favorites`), honest empty favorites state, inline contextual audio preview notice langsung di bawah kartu yang di-preview, serta sinkronisasi judul soundscape dan 5 opsi BPM ke `ActiveRunScreen`.
6. **Milestone 6 (SELESAI - Tahap 6A & 6B):** `ActivityScreen`, `SettingsScreen`, `Hidden Developer Mode` & Pembersihan Mode Konsumen.
   - Pengayaan jurnal riwayat `Activity` (`lib/screens/stradio/activity_screen.dart`) dengan grafik tren 7 hari reaktif yang mengikuti filter aktivitas (`All`/`Walking`/`Jogging`) serta pengurutan kronologis terbaru di atas, `SettingsScreen` dwibahasa lengkap (`lib/screens/stradio/settings_screen.dart`: edit profil nama/tinggi badan/target harian, panduan baterai saku Android, clear workout history dengan dialog konfirmasi), serta panel `Developer & Research Tools` lengkap (akses langsung ke `SensorLabsSheet`, ekspor 3 CSV, dan `LegacyExperimentShell`).
7. **Milestone 7 (SELESAI - Tahap 7A, 7B & 7C):** Consumer UX Polish, Targeted Glassmorphism & Interactive Activity Analytics.
   - Pemisahan visual tombol tengah `Run` agar menonjol keluar dari garis atas Floating Island Nav Bar dengan efek *targeted frosted glassmorphism*, perbaikan simetri pill filter `"All"` di `ActivityScreen`, penyelarasan 1 baris *time-aware greeting* + `[Nama]` di `HomeScreen`, peningkatan diagram `ActivityScreen` (`1W` / `1M` / `3M` / `All`, opsi `Bar` / `Line-Area` / `Activity Split`, serta *tap popover* info tiap titik/batang), *Custom Frosted Tempo Picker Sheet* + toggle cepat `Hand`/`Pocket` opsional di `ActiveRunScreen`, dan mikro-animasi/ambient wash bertakar `MOTION 2`.

---

## 6. Protokol Integritas Eksperimen & Performa Sistem `[STATUS: DONE - 53/53 TESTS PASSED]`

Meskipun tampilan visual ditingkatkan menjadi produk komersial modern, seluruh **integritas riset dan metodologi ilmiah tetap terjaga 100%**:

1. **Fixed 100-Step Ground Truth:** Setiap sesi benchmarking tetap terkalibrasi ke standar 100 langkah fisik aktual.
2. **Deterministic Offline Replay:** Penyimpanan sampel sensor mentah tetap berformat `SensorSample` murni (X, Y, Z, timestamp) sehingga algoritma dapat di-replay secara *offline* untuk pembuktian ilmiah.
3. **Asynchronous Non-Blocking Pipeline:** Seluruh pemrosesan dataset besar berjalan di thread asinkron agar perangkat smartphone tidak mengalami lag atau *screen freeze*.
4. **Privacy & Offline First:** Penyimpanan data bersifat lokal dan offline-first. Pengiriman telemetri ke PostHog Cloud hanya berjalan saat koneksi internet aktif tanpa menghambat antarmuka pengguna.

---

## 7. Sprint Roadmap Baru: Robustness, Lifecycle, Persistence & Background Service `[STATUS: DONE]`

Dokumen kerja operasional untuk menyelesaikan bug lifecycle, polishing brand identity, persistensi data sesi aktif, serta persiapan pengujian fisik di kantong/layar mati.

### 7.1 Ringkasan Status Sprint

| Sprint | Fokus Utama | Target Deliverable | Status |
| :--- | :--- | :--- | :--- |
| **Sprint 1** | **Stream & Lifecycle Bug Fixes** | Auto-recovery sensor stream, restart session mulus setelah Finish, eliminasi false sensorError | `DONE` |
| **Sprint 2** | **Visual Identity & Polish** | Logo Stradio header, headline *"Run the Vibe"*, 3-kolom Sensor Labs, button spinner | `DONE` |
| **Sprint 3** | **Active Session Persistence** | Pilihan A: Incremental auto-flush buffer ke cache lokal (`.temp_run.json`), crash recovery dialog | `DONE` |
| **Sprint 4** | **Background Service & Lockscreen Control** | Android Foreground Service (`flutter_foreground_task`), lockscreen interactive notification | `DONE` |

---

### 7.2 Rincian Sprint 1: Fix Bug Stream & State Lifecycle `[STATUS: DONE]`
1. **Auto-Recovery Hardware Stream pada Tombol Play (`_togglePauseResume`):**
   - Menambahkan guard: jika `!_recordingService.isRecording`, otomatis memanggil `_startSensorStream()` sebelum mengaktifkan `_RunStreamState.running`.
   - Mengatasi kasus sensor stream mati saat drawer Sensor Labs dibuka atau saat berganti algoritma primer.
2. **Session Reset Mulus Setelah Kembali dari Summary Screen:**
   - Ketika kembali dari `PostRunSummaryScreen` (baik melalui "Save & Finish" maupun "Back/Discard"), pastikan state tidak stuck:
     - Jika disimpan (`savedAndFinished == true`): Buat `recordingId` baru (misal `REC_..._002`), reset seluruh detektor, dan re-subscribe sensor stream ke status Standby/Paused segar.
     - Jika dibatalkan (`savedAndFinished == false`): Re-subscribe kembali sensor stream agar user bisa melanjutkan atau menekan play tanpa freeze.
3. **Penghapusan False `sensorError` Timeout:**
   - Menghilangkan abort kaku pada `isAccelerometerAvailable` saat ponsel diletakkan diam di meja, menggantikannya dengan lazy resilient connection.

---

### 7.3 Rincian Sprint 2: Visual Identity & UX Micro-Interactions `[STATUS: DONE]`
1. **Header Stradio Brand Logo:**
   - Mengganti avatar dummy "MC" dan nama "Mark C." di `active_run_screen.dart` dengan logo resmi `assets/images/stradio-logo.png` (tinggi ~30–32dp) berdampingan dengan *Dynamic Status Pill* (`PAUSED` / `RUNNING`).
2. **Brand Headline Evolution:**
   - Mengganti slogan generik *"Find Your Stride"* menjadi *"Run the Vibe"* (menggambarkan konsep sejati Stradio: Strava + Audio).
3. **Sensor Labs 3-Kolom Sejajar:**
   - Mengubah layout `Wrap` 2+1 pada `SensorManager Active (100 Hz)` di `sensor_labs_sheet.dart` menjadi `Row` 3 kolom berimbang (`TIMESTAMP`, `SAMPLE DROPS`, `BUFFERED SAMPLES`).
4. **Micro-Interaction Loading pada Tombol Save & Finish:**
   - Mengganti teks panjang *"Saving Workout & Telemetry..."* dengan spinner `CircularProgressIndicator` putih berukuran 22x22 tepat di tengah tombol.

---

### 7.4 Rincian Sprint 3: Active Session Persistence (Pilihan A: Auto-Flush Cache) `[STATUS: DONE]`
1. **Incremental Streaming Append (Pilihan A):**
   - Setiap batch 100 sampel (~1 detik) atau saat sesi dijeda, data mentah otomatis di-append ke file cache sementara di storage lokal (`.temp_active_run.json`).
2. **Unfinished Session Detection (Crash Recovery):**
   - Saat aplikasi diluncurkan, periksa keberadaan file `.temp_active_run.json`.
   - Jika ditemukan sesi yang belum di-finish (misal karena baterai habis atau app tertutup mendadak), tampilkan dialog: *"Sesi lari sebelumnya terdeteksi: REC_... (X langkah). Simpan atau Buang?"*.

---

### 7.5 Rincian Sprint 4: Background Service & Interactive Notification `[STATUS: DONE]`
1. **Android Foreground Service (`flutter_foreground_task`):**
   - Mencegah OS Android (Doze Mode & Battery Saver) mematikan sensor akselerometer saat layar terkunci (*screen sleep*) atau saat ponsel berada di dalam saku celana (Kondisi E5–E8).
2. **Interactive Notification (Media/Workout Style):**
   - Menampilkan notifikasi persisten di lock screen:
     - Header: `Stradio · Running (118 BPM)`
     - Body: `Steps: 42 / 100 (A1 Midpoint) · 01:23`
     - Action Buttons: `[ ⏸ Pause / ▶ Resume ]` dan `[ 🏁 Finish ]` yang dapat diklik langsung tanpa membuka kunci ponsel.

---

### 7.6 Catatan Teknis Deployment APK (Pembaruan & Signature Key) `[STATUS: DONE]`
* **Penyebab Error "App Not Installed / Package Conflicts":**
  1. **Keystore Signature Mismatch:** CI/CD GitHub Actions sebelumnya men-generate `debug.keystore` acak baru di setiap run (karena runner ephemeral), sehingga tanda tangan digital berbeda antar rilis dan diblokir oleh Android.
  2. **Version Code Identik:** Versi sebelumnya terkunci pada `1.0.0+1` di `pubspec.yaml` sehingga nomor build tidak pernah naik.
* **Solusi Terimplementasi (Opsi A - CI/CD Release Automation):**
  1. **Dynamic SemVer & Incremental Build Number:**
     - `VERSION_NAME` diambil dinamis dari Git tag (misal tag `v0.2.0` menjadi nama versi `0.2.0`).
     - `VERSION_CODE` diambil dari `${{ github.run_number }}` yang selalu naik secara linear di setiap build GitHub Actions.
  2. **Persistent Release Keystore via GitHub Secrets:**
     - Gradle membaca `release.keystore` persisten yang didecode dari secret `RELEASE_KEYSTORE_BASE64`.
      - Tanda tangan digital APK selalu konsisten di setiap rilis, memungkinkan instalasi update langsung tanpa uninstall.
      - Fallback otomatis ke `debug` signing saat build lokal tanpa secret, menjaga stabilitas environment developer.

---

## 8. Future Enhancement & Technical Backlog `[STATUS: PLANNING]`

1. **Migrasi Lokalisasi ke Standar Resmi Flutter `.arb` + `flutter_localizations` (`gen-l10n`):**
   - Saat ini (`v0.2.0`) aplikasi memakai kontrak abstrak per bahasa (`lib/l10n/stradio_strings.dart`, `stradio_strings_en.dart`, `stradio_strings_id.dart`) agar *compile-time safe* dan menjaga ukuran APK tetap ramping tanpa dependency tambahan.
   - Jika ke depannya jumlah bahasa bertambah banyak atau melibatkan penerjemah eksternal, kamus teks akan dimigrasikan ke file `.arb` bersama `flutter_localizations` dan `intl`.
2. **Upload Musik Lokal & Mesin Sinkronisasi Audio Berbasis Klasifikasi Aktivitas Real-Time:**
   - Memungkinkan pengguna memilih/mengunggah file audio lokal (`MP3` / `M4A` / `WAV`) dari perangkat (`file_picker` + `just_audio` + `audio_service`), memetakannya ke kategori intensitas (`Chill Walk`, `Tempo Jog`, `Fast Sprint`) dan BPM target opsional.
   - Mengimplementasikan klasifikasi aktivitas real-time berbasis jendela `SPM` stabil (*hysteresis* 5–8 detik agar transisi musik tidak gugup akibat noise sesaat) untuk perpindahan trek (*crossfade*) dan penyesuaian tempo pemutaran halus (`setSpeed`) saat aplikasi aktif maupun berjalan di latar belakang (*screen-off / pocket*).


