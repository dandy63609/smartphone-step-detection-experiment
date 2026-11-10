---
name: Stradio
status: final
sources:
  - docs/PLANNING.md
  - docs/DESIGN.md
updated: 2026-11-11
---

# Stradio: Experience Spine

> Kontrak pengalaman pengguna, arsitektur informasi, dwibahasa (EN default + ID), penanganan state, dan alur pengguna utama untuk rilis konsumen **Stradio v0.2.0**. Desain visual mengacu pada `docs/DESIGN.md` (spines menang jika terjadi konflik dengan mockup).

## Foundation

- **Platform & Form-Factor:** Aplikasi mobile Android-first berbasis Flutter (`StradioApp` di `lib/main.dart`), mendukung layout adaptif untuk tablet dan layar lebar (`maxWidth: 960 px`).
- **Sistem UI:** Material 3 sebagai fondasi widget, dikustomisasi penuh oleh `StradioTheme` (`lib/theme/stradio_theme.dart`) dan token di `docs/DESIGN.md`.
- **Bahasa:** Dua bahasa penuh (**English** sebagai default awal, dan **Bahasa Indonesia**), dapat diganti saat Onboarding maupun kapan saja dari tab `Settings`.
- **Model Penyimpanan & Privasi:**
  - Tanpa login / tanpa OAuth.
  - Data profil (nama panggilan, tinggi badan, target harian, bahasa) dan riwayat latihan tersimpan **100% lokal** pada perangkat.
  - Ketika **Developer Mode OFF (default konsumen)**, setiap sesi lari hanya menyimpan **ringkasan sesi** (*summary metadata + cadence buckets*) agar ruang penyimpanan ponsel hemat dan pembacaan tab `Home` serta `Activity` berlangsung instan.
  - Ketika **Developer Mode ON**, perekaman otomatis menyimpan data sampel akselerometer 100 Hz mentah ke file terpisah agar siap diekspor ke CSV dan di-replay oleh keempat algoritma (`A1, A2, B1, B2`).
  - **PostHog Analytics:** Secara default **ON** dengan tombol toggle transparan pada Onboarding dan `Settings`, mengirim telemetri penggunaan & performa langkah anonim menggunakan key dari `--dart-define=POSTHOG_API_KEY` (tidak pernah mengirim nama panggilan, tinggi badan, atau file mentah sensor).

## Information Architecture

| Surface | Reached From | Purpose | Visibility |
| :--- | :--- | :--- | :--- |
| **Onboarding Flow** | Cold start pertama kali (`hasCompletedOnboarding == false`) | Perkenalan privasi, pilih bahasa, profil singkat opsional, preferensi analitik | Sekali di awal |
| **Root Navigation Shell** | App open (setelah onboarding selesai) | Wadah 4 tab (`Home`, `Library`, `Activity`, `Settings`) + tombol aksi tengah `( RUN )` | Selalu (kecuali saat lari aktif) |
| **Tab: Home** | Tab 1 di Floating Nav | Sapaan personal, progres target harian akumulatif hari ini, ringkasan minggu ini, Quick Start | End-user |
| **Tab: Library** | Tab 2 di Floating Nav | Katalog soundscape berbasis tema & tempo (layout list aplikasi musik), filter BPM, favorit | End-user |
| **Active Run Screen** | Tombol tengah `( RUN )` / Quick Start di `Home` atau `Library` | Sesi olahraga full-screen (tanpa bottom nav): equalizer, step counter (`A1` primary), SPM, kontrol lockscreen | End-user (tombol Labs hanya jika Dev Mode ON) |
| **Pre-Run Goal Sheet** | Mengetuk `( RUN )` jika ada opsi pilihan target | Memilih mode lari: **Continue Daily Target** (sisa langkah hari ini) atau **Open Goal** | Kontekstual |
| **Post-Run Summary** | Tombol *Finish Run* di `ActiveRunScreen` atau tap kartu di `Activity` | Ringkasan pencapaian lari, Rhythm Score, grafik konsistensi cadence, tombol Share & Save | End-user (4-Algo Scoreboard hanya jika Dev Mode ON) |
| **Tab: Activity** | Tab 4 di Floating Nav | Progres akumulasi harian, tren mingguan nyata, daftar riwayat sesi (walking/jogging) | End-user |
| **Tab: Settings** | Tab 5 di Floating Nav | Edit profil (nama, tinggi badan), target harian, bahasa EN/ID, tema, toggle PostHog, hapus data | End-user |
| **Developer & Research Tools** | Ketuk **App Version 7x** di bagian bawah `Settings` | Switch keluar 1-ketuk (`Developer Mode OFF`), toggle raw 100 Hz recording, akses `SensorLabsSheet`, ekspor 3 CSV, `LegacyExperimentShell` | Hidden Developer Mode |

## Voice and Tone

Gaya bahasa ramah, langsung, memotivasi tanpa berlebihan, dan bebas jargon teknis di luar Developer Mode.

| Konteks | English (Default) | Bahasa Indonesia | Hindari |
| :--- | :--- | :--- | :--- |
| Sapaan Home | `Hello again, Raka` | `Halo lagi, Raka` | `Participant ID: P01` |
| Onboarding Privasi | `Your profile and workout history stay on this device. No account needed.` | `Profil dan riwayat olahragamu tersimpan aman di HP ini. Tanpa akun.` | Klaim membingungkan soal cloud |
| Toggle PostHog | `Share anonymous workout & step-accuracy stats to help improve Stradio. Name and raw sensor files stay private.` | `Bagikan statistik latihan & akurasi langkah secara anonim untuk bantu pengembangan Stradio. Nama dan file sensor tetap privat.` | Mengaktifkan pelacakan tanpa penjelasan |
| Placeholder Audio Library | `Audio track integration is coming soon. Tempo 165 BPM is active for your next run.` | `Integrasi file audio segera hadir. Tempo 165 BPM sudah aktif untuk sesi larimu.` | Tombol Play bisu tanpa penjelasan |
| Empty Activity | `No runs recorded yet. Tap Run below to capture your first steps.` | `Belum ada sesi tersimpan. Tekan Lari di bawah untuk mulai langkah pertamamu.` | `No data available` saja |
| Target Harian Tercapai | `Daily goal reached. Keep going or finish whenever you are ready.` | `Target harian tercapai. Lanjut terus atau selesaikan kapan saja.` | Menghentikan sesi lari secara paksa |

## Component Patterns

- **Floating Island Bottom Nav (`RootNavigationShell`):**
  - 5 slot: `Home` | `Library` | `Run` (elevated circle `{colors.accent-primary}` + label kecil `"Run"` / `"Lari"`) | `Activity` | `Settings`.
  - Mengetuk tab yang sedang aktif melakukan *scroll-to-top* jika daftar sedang di-scroll ke bawah.
  - Mengetuk tombol tengah **`( RUN )`**:
    - Jika mode target pengguna disetel ke *Daily Target*, sistem mengecek akumulasi langkah hari ini. Jika masih ada sisa target (atau sudah penuh), muncul pilihan cepat (lembar ringkas / quick chip): **Sisa Target Harian (`Remaining: X steps`)** atau **Open Goal**, lalu langsung masuk ke `ActiveRunScreen` (full-screen).
    - Jika mode default pengguna memang *Open Goal*, langsung masuk ke `ActiveRunScreen` tanpa modal tambahan agar instan.

- **Library Track List (Placeholder Siap Audio):**
  - Daftar tema awal:
    1. *Chill Walk* (`110 BPM`, jalan santai)
    2. *Lo-Fi Pace* (`118 BPM`, jalan cepat / pemanasan)
    3. *Tempo Jog* (`145 BPM`, jogging ritmis)
    4. *Neon Stride* (`165 BPM`, lari berenergi)
    5. *Sprint Surge* (`180 BPM`, lari cepat)
  - Mengetuk kartu memilih tema sebagai *Active Soundscape* (mengubah `targetBpm` dan nama tema di `Home` & `ActiveRunScreen`).
  - Mengetuk ikon *Play/Preview* pada kartu memicu animasi gelombang ritmis pada thumbnail kartu tersebut dan menampilkan status jujur bahwa audio file sedang disiapkan (siap diganti pemutar audio tim pada milestone audio tanpa mengubah struktur UI).
  - Mengetuk ikon *Heart* menyimpan status favorit ke `StradioPreferencesService`.

- **Mesin Deteksi Langkah & Kalkulasi Jarak:**
  - Penghitung langkah live pada `ActiveRunScreen` menggunakan **`A1 (Adaptive Midpoint Raw)`** sebagai sumber tunggal angka langkah konsumen agar responsif dan konsisten.
  - Panjang langkah untuk estimasi jarak memakai tinggi badan pengguna jika diisi pada Onboarding/Settings (`walking = heightCm * 0.00415`, `jogging = heightCm * 0.0055`), dan fallback ke nilai standar `0.74 m` / `0.95 m` jika tinggi badan dilewati.
  - Saat **Developer Mode ON**, detektor paralel (`A1, A2, B1, B2`) tetap direkam penuh beserta sampel 100 Hz untuk analisis dan ekspor CSV.

- **Mekanisme Masuk & Keluar Developer Mode:**
  - **Masuk:** Ketuk baris versi aplikasi (`Stradio v0.2.0`) sebanyak **7 kali** di bagian paling bawah tab `Settings`. Hitungan mundur halus muncul mulai ketukan ke-4 (*"3 taps left to enable Developer Mode"*).
  - **Keluar:** Kartu **Developer & Research Tools** muncul di tab `Settings` dengan switch **`Developer Mode`** di baris paling atas. Menggeser switch ke OFF langsung menyembunyikan kembali seluruh alat riset, tombol `Labs` di `ActiveRunScreen`, scoreboard 4 algoritma di `PostRunSummaryScreen`, serta menghentikan perekaman sampel mentah 100 Hz.

## State Patterns

| State | Surface | Perilaku & Tindakan Pengguna |
| :--- | :--- | :--- |
| **First Run** | Onboarding | Tampilkan alur 2 langkah; tombol *Skip* tersedia pada input nama dan tinggi badan (nama fallback ke `"Runner"`). |
| **Empty History** | `Home` & `Activity` | Tampilkan ilustrasi ikon non-generik atau kartu ringkas dengan pesan jelas dan 1 tombol CTA langsung memulai sesi lari pertama. Tidak ada angka dummy. |
| **Loading** | `Home`, `Activity`, `PostRun` | Tampilkan indikator progres ringan saat membaca daftar ringkasan lokal atau saat memproses akhir sesi. |
| **Sensor Connecting / Error** | `ActiveRunScreen` | Jika stream akselerometer belum aktif atau terblokir di emulator, tampilkan banner status beserta keterangan yang jelas (dan opsi simulasi hanya di mode uji/developer). |
| **Crash / Unfinished Session** | App Launch -> `Home` | Jika `.temp_active_run.json` ditemukan dari sesi terhenti, tampilkan dialog pemulihan (*Review & Save* atau *Discard*) sebelum memulai sesi baru. |
| **Storage Reset** | `Settings` | Penghapusan riwayat wajib melewati dialog konfirmasi eksplisit dengan konsekuensi yang jelas. |

## Interaction Primitives

- **Tap untuk aksi utama**, tanpa interaksi bergantung pada *hover* atau *long-press* tersembunyi.
- **Kontrol Lockscreen & Latar Belakang:** `flutter_foreground_task` tetap aktif saat sesi lari berjalan agar deteksi langkah tidak mati di saku celana saat layar terkunci, dengan kontrol `Pause/Resume` dan `Finish`.
- **Dilarang (Anti-Slop):** Tidak ada streak hukuman, tidak ada notifikasi spam pengingat, tidak ada modal bertumpuk lebih dari 1 lapis, dan tidak ada data atau profil palsu.

## Accessibility Floor

- Ukuran area sentuh seluruh tombol, filter chip, tab nav, dan tombol preview minimal **48x48 dp** dengan jarak antar target minimal **8 dp**.
- Seluruh tombol ikon saja (toggle tema, tombol favorit, tombol play/pause) wajib memiliki label `Semantics` dalam bahasa aktif (EN/ID).
- Mendukung `MediaQuery.textScalerOf` tanpa memotong teks tombol (*overflow*) pada skala font aksesibilitas hingga 1.3x.
- `Reduce Motion`: jika aktif di sistem perangkat, transisi kartu dan animasi denyut langkah diperhalus atau dilewati tanpa menghilangkan feedback status.

## Inspiration & Anti-patterns

- **Diadopsi dari Referensi 1 (`stradio-reference-1.png`):** Tata letak daftar kartu bertumpuk untuk `Library` dan `Activity` dengan filter chips horizontal dan thumbnail kiri.
- **Diadopsi dari Referensi 2 (`stradio-reference-2.png`):** Sapaan header asimetris dua warna di `Home` dan kartu *Quick Start* bersudut squircle.
- **Diadopsi dari Referensi 3 (`stradio-reference-3-navigation.png`):** Bilah navigasi kapsul melayang dengan tombol aksi lingkaran tengah berwarna aksen dan label teks ringkas `"Run"` di bawah lingkaran.
- **Ditolak (Anti-pattern):** Memaksa pengguna awam mengisi form eksperimen (`Participant ID`, penempatan saku/tangan, target 100 langkah) sebelum boleh berlari, atau menumpuk JSON sampel 100 Hz untuk pengguna biasa yang tidak membutuhkannya.

## Responsive & Platform

- **Android Doze & Battery Optimization:** Menyediakan kartu panduan singkat yang jujur di `Settings` bagi pengguna yang mengalami hitungan berhenti saat layar mati.
- **Reflow Multi-Lebar:** Pada tablet dan layar lebar (`>= 600 px`), `Home` dan `Activity` menyusun kartu ringkasan secara berdampingan (2 kolom) dan membatasi lebar maksimal konten `960 px` agar mata tidak lelah membaca baris terlalu panjang.

## Key Flows

### Flow 1: Pengguna Baru Masuk Pertama Kali (Raka, lari pagi pertama tanpa akun)

1. Raka membuka Stradio untuk pertama kali (`hasCompletedOnboarding == false`).
2. **Langkah 1 (Welcome & Privasi):** Raka membaca bahwa data profil & olahraganya tersimpan aman di perangkat tanpa akun. Ia tetap memilih default `English` (atau beralih ke `Bahasa Indonesia`).
3. **Langkah 2 (Quick Personalization):** Raka mengisi nama panggilan `"Raka"` (atau menekan *Skip* menjadi `"Runner"`), tinggi badan `172 cm`, memilih target harian `5,000 steps`, dan melihat toggle **Anonymous Telemetry (PostHog)** yang aktif secara default dengan penjelasan jujur bahwa nama dan data sensor mentah tidak dikirim.
4. Raka menekan **"Start Using Stradio"**.
5. **Climax:** Aplikasi menyimpan profil lokal dan langsung membuka `Home` dengan sapaan `Hello again, Raka`, progres `0 / 5,000 steps`, dan tombol tengah **`Run`** siap ditekan dalam satu sentuhan jempol.

### Flow 2: Lanjut Lari di Hari yang Sama (Nadia, akumulasi target harian vs Open Goal)

1. Pada pagi hari, Nadia berjalan `2,200 steps` dan menyimpan sesinya. Tab `Home` & `Activity` langsung menampilkan akumulasi `2,200 / 5,000 steps today`.
2. Sore harinya, Nadia ingin jogging lagi dan menekan tombol tengah **`Run`** di Floating Nav Bar.
3. Sistem menampilkan pilihan ringkas mode target: **Continue Daily Target (`2,800 steps left`)** atau **Open Goal**.
4. Nadia memilih **Continue Daily Target** dan mulai berlari dengan HP di saku.
5. Saat langkah ke-2.800 pada sesi itu tercapai (total hari itu 5.000), aplikasi memberi feedback *"Daily goal reached"* tanpa menghentikan lari.
6. **Climax:** Ketika Nadia menekan *Finish Run*, `PostRunSummaryScreen` menampilkan pencapaian sesi + status target harian 100% tercapai, dan `Home` kini menampilkan `5,000+ / 5,000 steps today`.

### Flow 3: Memilih Tema Tempo di Library (Raka, sebelum lari sore)

1. Raka membuka tab `Library`, mengetuk filter chip `Jog`.
2. Ia melihat daftar tema bergaya pemutar musik (*Tempo Jog · 145 BPM*, *Neon Stride · 165 BPM*).
3. Raka menekan tombol *Preview* pada *Neon Stride*. Kartu menampilkan animasi gelombang ritme serta pesan jujur bahwa pemutar audio penuh segera hadir, sementara tempo `165 BPM` langsung siap dipakai.
4. Raka mengetuk kartu *Neon Stride* dan menekan tombol cepat menuju sesi lari.
5. **Climax:** `ActiveRunScreen` terbuka dengan header `Neon Stride · 165 BPM` sudah aktif dan equalizer bergerak mengikuti langkah kakinya.

### Flow 4: Peneliti Mengaktifkan & Menonaktifkan Developer Mode (Andi, pengambilan dataset riset)

1. Andi membuka tab `Settings`, menggulir ke bagian paling bawah, lalu mengetuk teks versi aplikasi `Stradio v0.2.0` sebanyak **7 kali**.
2. Toast konfirmasi muncul: *"Developer Mode enabled"*, dan kartu **`Developer & Research Tools`** langsung muncul di `Settings`.
3. Saat Developer Mode ON, Andi dapat mengaktifkan perekaman raw 100 Hz penuh, membuka [`SensorLabsSheet`](file:///e:/project-android/smartphone-step-detection-experiment/lib/screens/stradio/sensor_labs_sheet.dart), melihat 4-Algorithm Scoreboard di `PostRunSummaryScreen`, mengekspor 3 CSV, atau mengakses `LegacyExperimentShell`.
4. Setelah selesai riset, Andi cukup menggeser switch **`Developer Mode`** ke **OFF** di baris paling atas kartu tersebut.
5. **Climax:** Seluruh UI kembali bersih 100% ke tampilan konsumen tanpa perlu menghapus data aplikasi atau mengganti APK.
