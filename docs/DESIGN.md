---
name: Stradio
description: Aplikasi kebugaran dan ritme lari konsumen yang memadukan deteksi langkah real-time dengan soundscape adaptif. Hangat, borderless, ergonomis untuk satu tangan.
colors:
  surface-base: '#F7F6F2'
  surface-raised: '#FFFFFF'
  surface-subtle: '#F0EFEA'
  ink-primary: '#191923'
  ink-secondary: '#666680'
  ink-muted: '#9E9EB2'
  accent-primary: '#FF765F'
  accent-secondary: '#8B72DE'
  status-live: '#2EBF6F'
  status-paused: '#F59E0B'
  status-error: '#EF4444'
  border-focus: '#FF765F'
  border-input: '#E2E0D8'
  surface-base-dark: '#121217'
  surface-raised-dark: '#1E1E26'
  surface-subtle-dark: '#282834'
  ink-primary-dark: '#F5F0E8'
  ink-secondary-dark: '#9E9EB2'
  ink-muted-dark: '#68687D'
  accent-secondary-dark: '#A995DB'
typography:
  metric-hero:
    fontFamily: Sora
    fontSize: 56px
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: -1.2px
  heading:
    fontFamily: Sora
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: -0.3px
  body:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: 0px
  label:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.6px
rounded:
  tag: 8px
  control: 12px
  card: 16px
  squircle: 20px
  hero: 28px
  pill: 999px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '7': 28px
  nav-clearance: 104px
components:
  floating-nav-bar:
    surface: '{colors.surface-raised}'
    surfaceDark: '{colors.surface-raised-dark}'
    radius: '{rounded.pill}'
    activeTint: '{colors.accent-primary}'
    inactiveTint: '{colors.ink-secondary}'
    centerActionFill: '{colors.accent-primary}'
    centerActionSize: 56px
  hero-card:
    surface: '{colors.surface-raised}'
    surfaceDark: '{colors.surface-raised-dark}'
    radius: '{rounded.hero}'
    padding: '{spacing.5}'
  squircle-deck:
    surface: '{colors.surface-raised}'
    surfaceDark: '{colors.surface-raised-dark}'
    radius: '{rounded.squircle}'
    padding: '{spacing.4}'
  cta-primary:
    fill: '{colors.accent-primary}'
    ink: '#FFFFFF'
    radius: '{rounded.pill}'
    minHeight: 48px
  filter-chip:
    surface: '{colors.surface-subtle}'
    activeFill: '{colors.accent-primary}'
    radius: '{rounded.pill}'
    minHeight: 44px
---

# Stradio: Design Spine

> Dial estetika: **ENERGY 3 / RHYTHM 2 / MOTION 2**.  
> Implementasi token nyata mengacu dan selaras dengan `lib/theme/stradio_theme.dart`.

## Brand & Style

Stradio (*Stride + Audio: Movement Becomes Music*) membawa pengalaman kebugaran yang terasa seperti studio musik pribadi di saku pelari, bukan instrumen laboratorium kaku. Mulai rilis konsumen (`v0.2.0`), seluruh tampilan luar mengutamakan keterbacaan cepat saat tubuh bergerak, hierarki yang lapang, dan kontrol satu tangan di area jempol bawah.

Estetika visual berdiri di atas dua pilar: **Warm Organic Dual System** (kanvas gading hangat pada siang hari dan obsidian gelap pada lari malam) serta **100% Borderless Tonal Architecture**. Pemisahan antarbidang dicapai melalui kontras tonal permukaan dan bayangan difus lembut, tanpa garis tepi abu-abu 1px maupun efek *glow* berlebihan.

*Alasan desain:* Bahasa visual hangat dan borderless memisahkan identitas Stradio dari aplikasi utilitas riset bawaan Material 3 sekaligus menjaga fokus pengguna pada angka langkah dan ritme saat bergerak.

## Colors

Palet Stradio dibatasi maksimal 2 warna inti netral adaptif + 1 aksen primer (`Sonic Coral`) + 1 aksen tempo (`Rhythm Violet`), sehingga mata pengguna langsung tahu mana tombol aksi dan mana indikator ritme.

- **Warm Ivory (`{colors.surface-base}` / `#F7F6F2`) & Pure White (`{colors.surface-raised}` / `#FFFFFF`):** Kanvas utama dan permukaan kartu pada Mode Terang. Hangat untuk mencegah silau di luar ruangan di bawah matahari pagi.
- **Deep Obsidian (`{colors.surface-base-dark}` / `#121217`) & Charcoal (`{colors.surface-raised-dark}` / `#1E1E26`):** Kanvas dan kartu pada Mode Gelap untuk sesi malam. Menghindari hitam murni `#000000` agar lapisan kartu tetap terpisah secara tonal.
- **Midnight (`{colors.ink-primary}` / `#191923`) & Warm Ivory Text (`{colors.ink-primary-dark}` / `#F5F0E8`):** Teks utama dan angka metrik besar dengan kontras di atas 12:1 terhadap kanvas masing-masing (melampaui standar WCAG AA 4.5:1).
- **Muted Slate (`{colors.ink-secondary}` / `#666680`) & Soft Silver (`{colors.ink-secondary-dark}` / `#9E9EB2`):** Label sekunder, metadata waktu, dan subtitle kartu.
- **Sonic Coral (`{colors.accent-primary}` / `#FF765F`):** Satu-satunya aksen aksi primer (tombol tengah `Run`, tombol *Play/Pause*, target progress bar, dan penekanan kata kunci sapaan asimetris). Tidak dipakai sebagai latar penuh halaman.
- **Rhythm Violet (`{colors.accent-secondary}` / `#8B72DE` terang, `{colors.accent-secondary-dark}` / `#A995DB` gelap):** Aksen khusus untuk gelombang frekuensi, indikator BPM, dan badge status tempo.
- **Semantik Status (`#2EBF6F`, `#F59E0B`, `#EF4444`):** Hanya digunakan untuk status nyata (`RUNNING`, `PAUSED`, dan error sensor atau validasi input).

*Alasan desain:* Membatasi `Sonic Coral` pada aksi utama dan `Rhythm Violet` pada telemetri tempo menciptakan kode warna fungsional yang konsisten dari layar `Home` hingga `ActiveRunScreen`.

## Typography

Stradio memadukan dua peran tipografi yang kontras agar angka olahraga mudah dipindai sekilas, sementara teks instruksi dan label tetap nyaman dibaca dalam Bahasa Inggris maupun Bahasa Indonesia:

- **Sora (`metric-hero`, `heading`):** Digunakan untuk angka besar (total langkah, target harian, BPM) dengan `FontFeature.tabularFigures()` wajib aktif agar digit tidak bergeser ke kiri-kanan saat bertambah real-time. Dipakai juga untuk judul layar dan sapaan asimetris dua warna (`Hello again,` + nama pengguna dalam `Sonic Coral`).
- **Inter (`body`, `label`):** Digunakan untuk kalimat pengantar onboarding, deskripsi kartu, tombol filter, dan label metrik (`STEPS`, `SPM`, `KM`). Menggunakan fallback `Roboto`, `Segoe UI`, `sans-serif`.

Aturan panjang teks dwibahasa (EN/ID): seluruh kontainer tombol dan kartu harus memberi kelonggaran lebar atau *wrapping* 2 baris karena frasa Bahasa Indonesia rata-rata 15% hingga 25% lebih panjang daripada Bahasa Inggris.

*Alasan desain:* `Sora` dengan `tabularFigures()` menjaga kestabilan visual saat angka langkah berdetak tiap detik, sementara `Inter` menjaga legibilitas teks kecil di layar ponsel yang bergerak.

## Layout & Spacing

Skala jarak baku: `4 / 8 / 12 / 16 / 20 / 24 / 28 px` (`{spacing.1}` sampai `{spacing.7}`).

- **Breakpoint Responsif:**
  - **Mobile (`< 600 px`):** Tata letak 1 kolom penuh dengan margin horizontal `20 px` (`{spacing.5}`).
  - **Tablet (`600 px - 899 px`):** Margin horizontal `28 px` (`{spacing.7}`), kartu statistik dan ringkasan beralih ke grid 2 kolom agar proporsional.
  - **Wide / Desktop (`>= 900 px`):** Konten dibatasi `maxWidth: 960 px` di tengah layar dengan margin `40 px`.
- **Aturan Floating Navigation Clearance (`{spacing.nav-clearance}`):** Seluruh tab di dalam `RootNavigationShell` wajib menyisakan ruang scroll bawah minimal `104 px` ditambah `MediaQuery.paddingOf(context).bottom` agar kartu atau tombol terbawah tidak pernah tertutup oleh bilah navigasi melayang.

*Alasan desain:* Memberi margin adaptif dan jarak aman bawah menjamin konten di ponsel layar kecil hingga tablet tidak berdesakan atau terpotong oleh navigasi mengambang.

## Elevation & Depth

Stradio menggunakan pendekatan **100% Borderless**:

- **Mode Terang:** Kartu dipisahkan dari kanvas `{colors.surface-base}` melalui warna putih `{colors.surface-raised}` dan bayangan difus dua tahap (`StradioColors.cardShadow`: 4% black blur 24 offset `(0, 8)` + 2% black blur 6 offset `(0, 2)`).
- **Mode Gelap:** Tidak memakai bayangan terang atau efek *glow*. Kedalaman dibuat melalui perbedaan tonal bertingkat (`#121217` -> `#1E1E26` -> `#282834`) ditambah `StradioColors.darkCardShadow` yang sangat halus.
- **Pengecualian Border:** Hanya input teks formulir saat mendapat fokus yang memakai ring `2 px` berwarna `{colors.border-focus}` untuk keterbacaan aksesibilitas.

*Alasan desain:* Menghilangkan border 1px membuat permukaan terasa organik seperti perangkat audio modern tanpa kebisingan garis.

## Shapes

Hierarki radius (`StradioRadii`) membentuk urutan peran komponen secara konsisten:

| Level | Token | Nilai | Penggunaan | Alasan Desain |
| :--- | :--- | :--- | :--- | :--- |
| Level 1 | `{rounded.hero}` | `28 px` | Hero Waveform, Kartu Progres Harian, Bottom Sheet | Memberi siluet lembut (*smooth pebble*) untuk kontainer fokus utama ala Referensi 2. |
| Level 2 | `{rounded.squircle}` | `20 px` | Deck metrik, kartu preset Quick Start, kartu riwayat sesi | Sudut squircle proporsional yang kokoh untuk blok data berulang. |
| Level 3 | `{rounded.card}` | `16 px` | Item daftar trek `Library`, tile sub-statistik, panel pengaturan | Radius kompak untuk daftar padat agar ruang konten tetap lega. |
| Level 4 | `{rounded.control}` | `12 px` | Input nama/tinggi badan/target langkah | Membedakan bidang ketik formulir secara tegas dari kartu dan tombol. |
| Level 5 | `{rounded.tag}` | `8 px` | Tag BPM, label tempo | Penanda ringkas tanpa mendominasi judul trek. |
| Level 6 | `{rounded.pill}` | `999 px` | Floating Nav Island, tombol CTA, filter chips, status pill | Membentuk batas jelas pada seluruh area sentuh jempol. |

## Components

Komponen utama yang membangun sistem antarmuka pengguna konsumen (mengacu `assets/images/stradio-reference-1.png`, `stradio-reference-2.png`, dan `stradio-reference-3-navigation.png`):

1. **Floating Island Bottom Navigation (`floating-nav-bar`):**
   - Mengacu langsung pada **Referensi 3 (varian baris kanan bawah)**: kapsul melayang horizontal (`{rounded.pill}`) dengan jarak mengambang dari tepi bawah (`12-16 px` di atas safe area) dan `elevation` lembut.
   - Berisi **5 slot sejajar** menggunakan **ikon vektor resmi Flutter Material** (dilarang keras menggunakan emoji pada ikon UI maupun teks tombol):
     - `Home`: `Icons.home_rounded` (aktif) / `Icons.home_outlined` (pasif)
     - `Library`: `Icons.graphic_eq_rounded` atau `Icons.music_note_rounded`
     - **Tombol tengah `( RUN )`**: lingkaran elevated berukuran `56 px` berwarna `{colors.accent-primary}` dengan `Icons.play_arrow_rounded` atau `Icons.directions_run_rounded` putih dan **label teks kecil `"Run"` / `"Lari"` tepat di bawah lingkaran** agar bebas ambigu bagi pengguna baru
     - `Activity`: `Icons.bar_chart_rounded`
     - `Settings`: `Icons.settings_rounded` (aktif) / `Icons.settings_outlined` (pasif)
   - Tab aktif memakai ikon solid + teks warna `{colors.accent-primary}`; tab pasif memakai `{colors.ink-secondary}`.

2. **First-Run Onboarding Deck:**
   - 2 kartu langkah terfokus di tengah kanvas tanpa bottom nav: Step 1 (*Welcome & Local Privacy Promise* + pilih Bahasa `EN`/`ID`), Step 2 (*Quick Personalization*: Nama panggilan dengan tombol *Skip*, Tinggi badan cm, Target langkah harian pilihan cepat/custom, dan toggle PostHog Analytics dengan default ON beserta keterangan jujur).

3. **Home Screen Components:**
   - **Asymmetric Greeting Header (Ref 2):** Baris sapaan kontekstual dua baris (`Hello again,` dalam `{colors.ink-primary}` diikuti `[Nama]` dalam `{colors.accent-primary}`), ditemani tombol toggle tema Light/Dark (`48x48 px`).
   - **Daily Goal Hero Card (`hero-card`):** Ring progres akumulasi langkah hari ini (`Today: X / Target steps`) atau mode *Open Goal*, dilengkapi 3 metrik nyata hari ini (`Steps`, `Distance`, `Active Time`).
   - **Quick Start Carousel / Row (`squircle-deck`):** Kartu pilihan cepat mode (*Brisk Walk 118 BPM*, *Tempo Jog 145 BPM*, *Neon Stride 165 BPM*) dengan tinggi minimum nyaman disentuh jempol.

4. **Library Music-Style Catalog (Ref 1 Layar 2 & 3):**
   - Baris *filter chips* horizontal di atas (`All`, `Chill`, `Jog`, `Fast`, `Favorites`).
   - **Track Row Card (`rounded.card`):** Thumbnail artwork tema berwarna/waveform mini di kiri (`56x56 px`), judul tema + deskripsi suasana + badge BPM di tengah, serta tombol Favorit (♡) dan ikon status/preview di kanan.
   - **Active Soundscape Bottom Bar:** Bilah mini di atas Floating Nav yang menunjukkan tema tempo aktif saat ini (mis. *Neon Stride · 165 BPM*) dengan aksi cepat menuju `Run`.

5. **Active Run & Post-Run Summary (`ActiveRunScreen` & `PostRunSummaryScreen`):**
   - Membuka **full-screen tanpa Floating Nav** agar tidak tertekan saat berlari.
   - Mode konsumen menyembunyikan tombol `Labs`, kode varian (`A1`, `B1`), dan tabel benchmark 4 algoritma; seluruh elemen tersebut hanya muncul ketika **Developer Mode** diaktifkan dari `Settings`.

6. **Settings & Hidden Developer Mode:**
   - Daftar kartu kelompok (*Profile & Language*, *Workout & Goal Preferences*, *Appearance & Device*, *Privacy & Data*).
   - Bagian **Developer & Research Tools** tersembunyi sepenuhnya secara default; muncul sebagai kartu baru hanya setelah ketukan 7x pada teks versi aplikasi di bagian paling bawah, lengkap dengan switch **Developer Mode ON/OFF** di baris teratasnya.

## Do's and Don'ts

| Do | Don't |
| :--- | :--- |
| Gunakan bahasa manusia untuk pelari (*Pace, Daily Goal, Rhythm Match*) pada seluruh layar utama. | Menampilkan istilah riset (*Participant P01, Ground Truth 100, Margin of Error, A1/B2*) di luar Developer Mode. |
| Pastikan setiap tombol, preview, dan navigasi punya fungsi nyata atau label jujur (*Audio coming soon*). | Memasang tombol *Preview Audio* yang diam tanpa respons atau data statistik bohong untuk mengisi ruang kosong. |
| Beri *bottom padding* cukup pada setiap layar tab di balik Floating Island Nav. | Membiarkan item daftar paling bawah tertutup oleh kapsul navigasi melayang. |
| Pertahankan target sentuh minimal `48x48 dp` untuk tombol di layar aktif maupun nav bar. | Membuat tombol kecil rapat tanpa jarak aman, terutama tombol kontrol saat berlari. |
| Gunakan tonal contrast dan bayangan difus 2 lapis sesuai `StradioColors`. | Menambahkan border 1px, gradient biru-ungu generik, atau animasi berulang tanpa henti. |
| Gunakan ikon vektor resmi Flutter (`Icons.*_rounded`) yang konsisten dan bermakna. | Menggunakan karakter emoji (`🏠`, `🎵`, `🔥`) pada navigasi, judul, badge, atau tombol. |
| Terapkan mikro-animasi terarah (`MOTION 2`) hanya saat transisi status atau respons ketukan nyata, patuh `disableAnimations`. | Memberi animasi *floating/bounce/pulse* terus-menerus tanpa pemicu aksi atau sinyal nyata. |
