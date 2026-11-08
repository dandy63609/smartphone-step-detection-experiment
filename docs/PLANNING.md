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

Arsitektur UI Stradio mengacu pada dua referensi visual utama yang disimpan di repositori:

```
assets/images/
├── stradio-reference-1.png   (Referensi 1: Ergonomi Layar Player & Library List)
└── stradio-reference-2.png   (Referensi 2: Hero Waveform Center Play & Floating Navigation)
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

## 4. Rencana Navigasi & Layar Masa Depan (MVP Roadmap) `[STATUS: PLANNING]`

Untuk mempersiapkan aplikasi saat *reactive beat & melody generator* diintegrasikan, aplikasi akan dibungkus dengan **Root Shell Navigation** yang menggunakan bilah navigasi melayang (*Floating Island Bottom Navigation* sesuai Referensi 2) dengan struktur **5-Tab Gold Standard**:

```
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│                   KONTEN LAYAR YANG AKTIF                     │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│    ┌─────────────────────────────────────────────────────┐    │
│    │   🏠         🎵          ╭─────╮         📊        ⚙️   │    │
│    │  Home     Library         │ RUN │      Activity  Settings│    │
│    │                           ╰─────╯                   │    │
│    └─────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

### 5 Bagian Utama Navigasi (Kiri ke Kanan):

#### 1. Tab `Home` (Dashboard & Penemuan)
- **Header Asimetris:** Sapaan modern (*"Good Morning / Find Your Rhythm"*) dengan profil avatar mini dan indikator status kesiapan sensor IMU.
- **Kartu Ringkasan:** Rekap capaian lari mingguan, *quick stats*, dan skor konsistensi ritme terakhir.
- **Quick Start Actions:** Pilihan preset lari cepat (100 Langkah Fisik, Brisk Walk 118 BPM, Tempo Jog 145 BPM).

#### 2. Tab `Library` (Koleksi Tema Musik Reaktif)
- Mengadopsi struktur kartu vertikal dan horizontal dari **Referensi 1 (Layar 2 & 3)**.
- Katalog tema soundscape reaktif yang menyesuaikan ketukan dengan langkah kaki:
  - **Neon Stride (165 BPM):** Synthwave berenergi tinggi untuk jogging cepat.
  - **Lo-Fi Pace (118 BPM):** Beat santai untuk jalan santai dan pemanasan.
  - **Cyber Cadence (145 BPM):** Ketukan ritmis elektronik untuk lari jarak jauh tempo stabil.
- Setiap kartu memiliki preview audio, filter genre/tempo, dan tombol favorit.

#### 3. Center Elevated Action: `( RUN )` (Tombol Aksi Utama)
- **Desain & Ergonomi:** Berada tepat di tengah bilah navigasi bawah, berukuran lebih besar (56–64px), sedikit menonjol melayang (*elevated floating action button*), dan berwarna **Sonic Coral (`#FF765F`)**.
- **Fungsi:** Merupakan pemicu aksi cepat instan (*instant primary CTA*) yang paling mudah dijangkau jempol satu tangan. Menekan tombol ini langsung membuka sesi lari aktif (`ActiveRunScreen`) untuk mulai melangkah.

#### 4. Tab `Activity` (Histori, Analisis & Scoreboard Riset)
- Riwayat seluruh sesi latihan dan rekaman eksperimen yang tersimpan di memori lokal.
- Ringkasan pencapaian akurasi terhadap ground truth 100 langkah fisik (Margin of Error %).
- Grafik visual *Signature Rhythm Score* dan konsistensi cadence antar sesi.

#### 5. Tab `Settings` (Pengaturan, Labs & Telemetri)
- **Sensor Labs & Diagnostik IMU:** Uji komparasi 4 algoritma paralel (`A1`, `A2`, `B1`, `B2`).
- **PostHog Cloud Telemetry:** Konfigurasi Project API Key dan status event synchronization.
- **Dataset Actions:** Ekspor dataset CSV lengkap (`sensor_data.csv` & `evaluation_summary.csv`).
- **Manajemen Penyimpanan:** Fitur *Hapus Semua Sampel* untuk membersihkan file JSON lokal dan mereset dari awal.
- Akses ke antarmuka riset Legacy Material 3.

---

## 5. Roadmap Eksekusi (6 Milestone) `[STATUS: PARTIALLY DONE (M1-M3 SELESAI)]`

1. **Milestone 1 (SELESAI - Commit `9153502`):** Revamp UI `ActiveRunScreen` (`lib/screens/stradio/active_run_screen.dart`).
   - Hero Waveform Card dengan tombol Play melayang di tengah saat standby, Segmented Utility Pills (BPM, Placement, Algorithm), angka langkah Sora 68px, target 100 langkah fisik, dan secondary metrics card.
2. **Milestone 2 (SELESAI - Commit `7da690f`):** Revamp UI `PostRunSummaryScreen` (`lib/screens/stradio/post_run_summary_screen.dart`).
   - Header pencapaian ritmis `SESSION HIGHLIGHTS`, Stradio Signature Circular Rhythm Visualizer, matriks statistik latihan (Total Langkah out of 100, Durasi, SPM, Speed, Jarak) dalam 3 kolom horizontal deck rapi, grafik konsistensi ritme langkah, mini Scoreboard akurasi 4 algoritma (A1–B2), serta tombol aksi "Save & Finish Workout" non-blocking.
3. **Milestone 3 (SELESAI - Commit `7da690f`):** Revamp UI `SensorLabsSheet` (`lib/screens/stradio/sensor_labs_sheet.dart`).
   - Panel diagnostik biomekanika & instrumen laboratorium eksperimen mengadopsi estetika kartu gelap modern Referensi 1 & 2: Toggle Developer Mode Live Overlay, kartu diagnostik kesehatan sensor (100 Hz latency & zero dropped samples), kalibrasi Target Ground Truth 100 Langkah, pemilih algoritma primer berpasangan 3x2, ekspor dataset CSV lengkap, dan reset data sampel.
4. **Milestone 4 (PLANNING):** `RootNavigationShell` & `HomeScreen`.
   - Bilah navigasi 5-tab melayang (*Floating Island Bottom Navigation*: Home, Library, **( RUN ) center elevated**, Activity, Settings) dan Dashboard Home pelari dengan sapaan asimetris modern (*"Find Your Rhythm"*) & Quick Actions.
5. **Milestone 5 (PLANNING):** `LibraryScreen`.
   - Katalog soundscapes reaktif (*Neon Stride 165*, *Tempo Jog 145*, *Lo-Fi Pace 118*, *Cyber Cadence 180*) mengadopsi layout kartu dari Referensi 1 dengan preview beat dan filter chips tempo.
6. **Milestone 6 (PLANNING):** `ActivityScreen` & `SettingsScreen`.
   - Riwayat latihan lengkap, analisis target 100 langkah fisik & akurasi error antar-kondisi (E1–E8), serta panel terpadu Settings dan data retention.

---

## 6. Protokol Integritas Eksperimen & Performa Sistem `[STATUS: DONE - 24/24 TESTS PASSED]`

Meskipun tampilan visual ditingkatkan menjadi produk komersial modern, seluruh **integritas riset dan metodologi ilmiah tetap terjaga 100%**:

1. **Fixed 100-Step Ground Truth:** Setiap sesi benchmarking tetap terkalibrasi ke standar 100 langkah fisik aktual.
2. **Deterministic Offline Replay:** Penyimpanan sampel sensor mentah tetap berformat `SensorSample` murni (X, Y, Z, timestamp) sehingga algoritma dapat di-replay secara *offline* untuk pembuktian ilmiah.
3. **Asynchronous Non-Blocking Pipeline:** Seluruh pemrosesan dataset besar berjalan di thread asinkron agar perangkat smartphone tidak mengalami lag atau *screen freeze*.
4. **Privacy & Offline First:** Penyimpanan data bersifat lokal dan offline-first. Pengiriman telemetri ke PostHog Cloud hanya berjalan saat koneksi internet aktif tanpa menghambat antarmuka pengguna.

---

## 7. Sprint Roadmap Baru: Robustness, Lifecycle, Persistence & Background Service `[STATUS: IN-PROGRESS]`

Dokumen kerja operasional untuk menyelesaikan bug lifecycle, polishing brand identity, persistensi data sesi aktif, serta persiapan pengujian fisik di kantong/layar mati.

### 7.1 Ringkasan Status Sprint

| Sprint | Fokus Utama | Target Deliverable | Status |
| :--- | :--- | :--- | :--- |
| **Sprint 1** | **Stream & Lifecycle Bug Fixes** | Auto-recovery sensor stream, restart session mulus setelah Finish, eliminasi false sensorError | `DONE` |
| **Sprint 2** | **Visual Identity & Polish** | Logo Stradio header, headline *"Run the Vibe"*, 3-kolom Sensor Labs, button spinner | `DONE` |
| **Sprint 3** | **Active Session Persistence** | Pilihan A: Incremental auto-flush buffer ke cache lokal (`.temp_run.json`), crash recovery dialog | `DONE` |
| **Sprint 4** | **Background Service & Lockscreen Control** | Android Foreground Service (`flutter_foreground_task`), lockscreen interactive notification | `READY / NEXT` |

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

### 7.5 Rincian Sprint 4: Background Service & Interactive Notification `[STATUS: READY / NEXT]`
1. **Android Foreground Service (`flutter_foreground_task`):**
   - Mencegah OS Android (Doze Mode & Battery Saver) mematikan sensor akselerometer saat layar terkunci (*screen sleep*) atau saat ponsel berada di dalam saku celana (Kondisi E5–E8).
2. **Interactive Notification (Media/Workout Style):**
   - Menampilkan notifikasi persisten di lock screen:
     - Header: `Stradio · Running (118 BPM)`
     - Body: `Steps: 42 / 100 (A1 Midpoint) · 01:23`
     - Action Buttons: `[ ⏸ Pause / ▶ Resume ]` dan `[ 🏁 Finish ]` yang dapat diklik langsung tanpa membuka kunci ponsel.

---

### 7.6 Catatan Teknis Deployment APK (Pembaruan & Signature Key)
* **Mengapa Muncul Pesan "App Not Installed / Package Conflicts" saat Update APK?**
  1. **Keystore Signature Mismatch:** APK debug menggunakan `debug.keystore` (unik per mesin/komputer), sedangkan APK release menggunakan release key. Android secara ketat melarang update jika signature key berbeda untuk melindungi aplikasi dari pembajakan.
  2. **Version Code Identik / Turun:** Jika `versionCode` di `pubspec.yaml` tidak dinaikkan (tetap `1.0.0+1`), installer Android bisa menolak pembaruan.
* **Standar Penanganan:**
  * Selama tahap pengembangan cepat, hapus (*uninstall*) APK lama sebelum menginstal APK baru.
  * Untuk pembaruan tanpa uninstall di kemudian hari: gunakan build mode konsisten dan naikkan build number di `pubspec.yaml` (`1.0.0+2`, `1.0.0+3`, dst).


