# Stradio: Product Roadmap, UI Revamp & Navigation Architecture

> **"Stride + Audio: Movement Becomes Music"**  
> Dokumen ini memuat cetak biru teknis dan arsitektur desain antarmuka (UI/UX) untuk aplikasi **Stradio**. Dokumen ini menggabungkan sains eksperimen biomekanika langkah kaki (*adaptive threshold algorithms*) dengan pengalaman pemutar musik reaktif (*reactive sports-music audio app*).

---

## 1. Visi Produk & Filosofi Desain

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

## 2. Acuan Desain Resmi (Visual References)

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

## 3. Revamp Layar Saat Ini: Active Run Screen (Semi-Experiment)

Layar saat ini (`ActiveRunScreen`) berfungsi ganda: sebagai pemutar lari aktif bagi pelari sekaligus instrumen eksperimen biomekanika bagi penguji/peneliti. Revamp dilakukan agar kedua kebutuhan ini menyatu secara harmonis tanpa saling mengganggu.

```
┌─────────────────────────────────────────────────────────┐
│ [● LIVE STRIDE]                        [ ⚗ Sensor Labs ]│
├─────────────────────────────────────────────────────────┤
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │  AUDIO-STRIDE WAVEFORM             165 BPM      │   │
│   │                                                 │   │
│   │          ~~~~~~ ( ▶ PLAY ) ~~~~~~               │   │
│   │                                                 │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
│   [ 165 BPM ]   [ Hand • Right ]   [ Algoritma: A1 ]    │
│                                                         │
│                         084                             │
│                        STEPS                            │
│           Detected: 84 / Target: 100 Steps              │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │   158 AVG SPM   •   04:12 TIME   •   8.4 KM/H   │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │  Neon Stride                                    │   │
│   │  ( ⏸ PAUSE )           [    FINISH RUN    ]     │   │
│   └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Rincian Komponen Revamp:

1. **Top Bar Minimalis:**
   - Sisi kiri: *Live Status Badge* (titik hijau solid untuk lari aktif, titik kuning solid untuk standby/paused).
   - Sisi kanan: Tombol *Sensor Labs* (ikon tabung reaksi) untuk membuka drawer diagnostik dan ekspor CSV.
   - Bebas dari judul teks redundan agar layar terasa lapang.

2. **Hero Waveform Card dengan Center Action Button:**
   - Kartu visualizer berlatar belakang gelap gradien dengan border halus.
   - Saat kondisi **Standby/Paused**: Menampilkan garis horizon tenang dan tombol **Play bulat Sonic Coral melayang di tengah visualizer** (mengadopsi Referensi 2).
   - Saat kondisi **Running**: Menampilkan gelombang 3-lapis dinamis yang terhubung langsung dengan sinyal akselerometer 100 Hz. Tombol berpindah ke deck bawah sehingga visualizer bebas menampilkan grafik gerakan secara penuh.

3. **Segmented Utility Capsule Bar:**
   - Tiga kapsul kontrol horizontal yang rapi (mengadopsi Referensi 1):
     1. *Target Tempo BPM Selector* (118 / 145 / 165 BPM).
     2. *Phone Placement Selector* (Hand / Pocket).
     3. *Active Algorithm Selector* (A1 Midpoint Raw / B1 Mean+SD).

4. **Digital Stride Readout:**
   - Angka langkah berukuran ekstra besar (Sora 64–72px) dengan animasi transisi angka halus.
   - Indikator pencapaian target ground truth: `Detected: X / Target: 100 Steps`.

5. **Secondary Performance Bar:**
   - Tiga metrik pelari dalam satu kartu horizontal: Cadence (SPM), Durasi Berjalan (Menit:Detik), dan Estimasi Kecepatan (km/h).

6. **Bottom Control Deck:**
   - Tombol bulat **Pause / Resume** berwarna Sonic Coral dengan efek glow lembut.
   - Tombol **Finish Run** berbentuk pill penuh yang bersih, nyaman ditekan, dan dilengkapi overlay loading non-blocking agar tidak terjadi freeze saat komputasi data besar.

---

## 4. Rencana Navigasi & Layar Masa Depan (MVP Roadmap)

Untuk mempersiapkan aplikasi saat *reactive beat & melody generator* diintegrasikan, aplikasi akan dibungkus dengan **Root Shell Navigation** yang menggunakan bilah navigasi melayang (*Floating Island Bottom Navigation* sesuai Referensi 2) dengan struktur **5-Tab Gold Standard**:

```
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│                   KONTEN LAYAR YANG AKTIF                     │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│    ┌─────────────────────────────────────────────────────┐    │
│    │   🏠         🎵           ╭─────╮         📊        ⚙️   │    │
│    │  Home     Library         │ RUN │      Activity  Settings│    │
│    │                           ╰─────╯                    │    │
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

## 5. Roadmap Eksekusi (6 Milestone)

1. **Milestone 1 (SELESAI - Commit `9153502`):** Revamp UI `ActiveRunScreen` (`lib/screens/stradio/active_run_screen.dart`).
   - Hero Waveform Card dengan tombol Play melayang di tengah saat standby, Segmented Utility Pills (BPM, Placement, Algorithm), angka langkah Sora 68px, target 100 langkah fisik, dan secondary metrics card.
2. **Milestone 2 (Berikutnya):** Revamp UI `PostRunSummaryScreen` (`lib/screens/stradio/post_run_summary_screen.dart`).
   - Header pencapaian ritmis, Stradio Signature Circular Rhythm Visualizer, matriks statistik latihan (Total Langkah out of 100, Durasi, SPM, Speed, Jarak), grafik konsistensi ritme langkah, mini Scoreboard akurasi 4 algoritma (A1–B2), serta tombol aksi "Save & Finish Workout" non-blocking.
3. **Milestone 3:** Revamp UI `SensorLabsSheet` (`lib/screens/stradio/sensor_labs_sheet.dart`).
   - Panel diagnostik biomekanika & instrumen laboratorium eksperimen mengadopsi estetika kartu gelap modern Referensi 1 & 2: Toggle Developer Mode Live Overlay, kartu diagnostik kesehatan sensor (100 Hz latency & zero dropped samples), kalibrasi Target Ground Truth 100 Langkah, pemilih algoritma primer, ekspor dataset CSV lengkap, dan reset data sampel.
4. **Milestone 4:** `RootNavigationShell` & `HomeScreen`.
   - Bilah navigasi 5-tab melayang (*Floating Island Bottom Navigation*: Home, Library, **( RUN ) center elevated**, Activity, Settings) dan Dashboard Home pelari dengan sapaan asimetris modern (*"Find Your Rhythm"*) & Quick Actions.
5. **Milestone 5:** `LibraryScreen`.
   - Katalog soundscapes reaktif (*Neon Stride 165*, *Tempo Jog 145*, *Lo-Fi Pace 118*, *Cyber Cadence 180*) mengadopsi layout kartu dari Referensi 1 dengan preview beat dan filter chips tempo.
6. **Milestone 6 (Terakhir):** `ActivityScreen` & `SettingsScreen`.
   - Riwayat latihan lengkap, analisis target 100 langkah fisik & akurasi error antar-kondisi (E1–E8), serta panel terpadu Settings dan data retention.

---

## 6. Protokol Integritas Eksperimen & Performa Sistem

Meskipun tampilan visual ditingkatkan menjadi produk komersial modern, seluruh **integritas riset dan metodologi ilmiah tetap terjaga 100%**:

1. **Fixed 100-Step Ground Truth:** Setiap sesi benchmarking tetap terkalibrasi ke standar 100 langkah fisik aktual.
2. **Deterministic Offline Replay:** Penyimpanan sampel sensor mentah tetap berformat `SensorSample` murni (X, Y, Z, timestamp) sehingga algoritma dapat di-replay secara *offline* untuk pembuktian ilmiah.
3. **Asynchronous Non-Blocking Pipeline:** Seluruh pemrosesan dataset besar berjalan di thread asinkron agar perangkat smartphone tidak mengalami lag atau *screen freeze*.
4. **Privacy & Offline First:** Penyimpanan data bersifat lokal dan offline-first. Pengiriman telemetri ke PostHog Cloud hanya berjalan saat koneksi internet aktif tanpa menghambat antarmuka pengguna.

---

## 7. Cetak Biru Visual ASCII & Sistem Desain Baru (Hasil Review UX Sally & Anti-Slop)

Bagian ini memuat visualisasi tata letak ASCII baru untuk **Layar Utama (`ActiveRunScreen`)**, hierarki bentuk/sudut lengkung (*shape & border system*), serta **Komparasi Tema Light/Dark**. Seluruh rancangan disusun bebas dari *AI slop* dan mengadopsi 100% karakter produk premium dari **Referensi 1** dan **Referensi 2**.

### 7.1 Visualisasi ASCII: Zero-Scroll "Unified Stride Deck"

Desain ini mengatasi 4 cacat UX pada draf sebelumnya: mengeliminasi tombol ganda (*no dual play buttons*), menjamin **Zero-Scroll** (pas dalam 1 viewport ponsel saat berlari), membuang istilah kaku laboratorium (*"Physical Steps"* diganti *"Session Goal"*), serta menempatkan seluruh kontrol vital di **Thumb Zone** bawah.

```
┌─────────────────────────────────────────────────────────────┐
│ (👤) Mark C.  [● ACTIVE]              [ ☀/☾ ] [ ⚗ Labs ]    │
├─────────────────────────────────────────────────────────────┤
│ Find Your Stride                                            │
│ Neon Stride · 165 BPM ⚡                                     │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  AUDIO-STRIDE WAVEFORM                                  │ │
│ │                                                         │ │
│ │   || | |||| ||| ||||||| ||||||| ||| |||| | ||           │ │
│ │   || | |||| ||| ||||||| ||||||| ||| |||| | ||           │ │
│ │   (Equalizer bar vertikal berirama reaktif langkah)     │ │
│ │                                                         │ │
│ │  Cadence Sync: Optimal (162 SPM)        ● Live Reactive │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  STRIDE GOAL                              84 / 100      │ │
│ │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░  84%        │ │
│ │                                                         │ │
│ │       084                   162             04:18       │ │
│ │      STEPS                  SPM             TIME        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │   ╭─────────╮                                           │ │
│ │   │ ⏸ PAUSE │        [     FINISH WORKOUT     ]        │ │
│ │   ╰─────────╯                                           │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

### 7.2 Spesifikasi Bentuk: 100% Borderless & Corner Radius Hierarchy

Berdasarkan analisis bedah visual terhadap **Referensi 1** dan **Referensi 2**, Stradio menolak penggunaan border garis abu-abu 1px kaku khas AI slop. Seluruh pemisahan bidang kartu dilakukan menggunakan **Tonal Contrast** dan **Diffused Ambient Shadow**.

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

---

### 7.3 Komparasi Palet: Warm Organic Dual Theme

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

---

### 7.4 Pemetaan Token Baru ke `lib/theme/stradio_theme.dart`

Untuk mendukung implementasi di kode Flutter, token berikut akan diperbarui:

1. **`StradioRadii`:** Menambahkan `hero = 28.0`, `squircle = 20.0`, dan `pill = 999.0`.
2. **`StradioColors`:** Menambahkan token Dark Theme (`obsidianCanvas = Color(0xFF121217)`, `charcoalSurface = Color(0xFF1E1E26)`).
3. **`StradioTheme.darkTheme`:** Mengimplementasikan tema gelap organik nyata alih-alih sekadar alias `lightTheme`.
4. **`cardTheme`:** Mengunci `side: BorderSide.none` dan elevasi 0 dengan `StradioColors.cardShadow`.

