# Rencana Eksperimen: Komparasi Algoritma Deteksi Langkah Real-Time & Pipeline CI/CD

Dokumen ini memuat rencana kerja teknis untuk eksperimen deteksi langkah pada repositori `smartphone-step-detection-experiment`, mencakup desain algoritma, protokol pengujian 100 langkah fisik, serta arsitektur **CI/CD, Security Guard (Gitleaks), Optimasi Ukuran APK, dan Distribusi Otomatis via GitHub Releases**.

---

## 1. Fokus & Keputusan Teknis Eksperimen

1. **Uji 100 Langkah Fisik (*Ground Truth* Mutlak):**
   * Penguji memegang/mengantongi ponsel sambil menghitung manual tepat 100 langkah.
   * Toleransi error diukur langsung: $\text{Margin Error (\%)} = \frac{|\text{Langkah Terdeteksi} - 100|}{100} \times 100\%$.
2. **Stationary Noise Gate & Kunci Skala Grafik:**
   * Saat ponsel diletakkan diam di atas meja, *thermal micro-noise* MEMS ($\approx \pm 0.03\ \text{m/s}^2$ di sekitar $9.81\ \text{m/s}^2$) diblokir oleh `minWindowSpreadMps2 = 1.2` $\text{m/s}^2$ sehingga deteksi langkah tetap **0 langkah** dan grafik *live* tetap berupa garis lurus stabil, sementara sampel mentah 100 Hz tetap terekam utuh ke `sensor_data.csv`.
3. **4 Kombinasi Algoritma Berjalan Serentak (*Apple-to-Apple*):**
   * Sekali sesi jalan 100 langkah merekam kedua stream sensor (`Raw Accelerometer` + `User Accelerometer`) dan langsung diproses oleh 4 kombinasi algoritma (`A1`, `A2`, `B1`, `B2`) secara paralel.
4. **Penundaan Background Foreground Service:**
   * Karena durasi tes 100 langkah hanya berlangsung singkat (~1–1,5 menit), layar ponsel dibiarkan tetap menyala. Foreground service persisten ditunda hingga tahap pengembangan audio di masa mendatang.
5. **UI Google Material Design 3 (Google Fit / Health Connect Style):**
   * Seluruh layar (`DashboardScreen`, `SetupScreen`, `LiveRecordingScreen`, `ResultsScreen`, `ExportScreen`) menggunakan tema Material 3 dengan warna Google Blue (`#1A73E8`), *SegmentedButton*, *Circular Step Gauge*, serta *Scoreboard* 4 algoritma.

---

## 2. Matriks 4 Kombinasi Algoritma yang Diuji

Data percepatan dibaca melalui dua stream dari hardware:
* **Stream A (Raw Accelerometer):** Menyertakan gravitasi bumi ($\approx 9.8\ \text{m/s}^2$).
* **Stream B (User Accelerometer / Linear):** Gravitasi telah dieliminasi oleh OS ($\approx 0.0\ \text{m/s}^2$ saat diam), dilengkapi *causal low-pass gravity filter fallback*.

Keempat kombinasi yang dievaluasi secara paralel pada setiap sesi rekaman:

| Kode | Algoritma Ambang | Input Sensor | Karakteristik yang Diuji |
| :---: | :--- | :--- | :--- |
| **A1** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | Raw Accelerometer (dengan gravitasi) | Baseline eksperimen awal. |
| **A2** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | User Accelerometer (tanpa gravitasi) | Menguji apakah eliminasi gravitasi menstabilkan midpoint. |
| **B1** | **Mean + $k \times \text{StdDev}$** | Raw Accelerometer (dengan gravitasi) | Sensitivitas terhadap deviasi lonjakan hentakan. |
| **B2** | **Mean + $k \times \text{StdDev}$** | User Accelerometer (tanpa gravitasi) | Kombinasi modern (sinyal dinamis murni). |

---

## 3. Tahapan Implementasi Teknis

### Fase 1: Perbaikan Noise Diam & Redesign UI Material 3 (Selesai ✅)
- [x] Tambahkan *Stationary Noise Gate* (`minWindowSpreadMps2 = 1.2` $\text{m/s}^2$) pada `StepDetector` agar HP diam di meja menghasilkan 0 langkah.
- [x] Kunci rentang skala vertikal minimum (`6.0` $\text{m/s}^2$) pada grafik `LiveRecordingScreen` serta tampilkan indikator status `Stationary (Idle)` vs `Motion Active`.
- [x] Rombak seluruh UI ke Google Material Design 3 (Google Fit / Health Connect aesthetic).
- [x] Tambahkan *unit test* 30 detik (3.000 sampel) untuk memvalidasi 0 *false positive* saat HP diam di meja.

### Fase 2: Perluasan Pipeline Sensor Ganda & Eksekusi 4 Jalur (Selesai ✅)
- [x] Modifikasi `RecordingService` di `lib/services/recording_service.dart` untuk berlangganan paralel pada `accelerometerEventStream` dan `userAccelerometerEventStream` (dengan *gravity filter fallback*).
- [x] Adaptasi `StepDetector` (`useLinearAcceleration`) dan tambahkan `StepDetector.replayAllFour()` untuk memproses keempat varian (`A1`, `A2`, `B1`, `B2`) sekaligus.

### Fase 3: Pembaruan UI Scoreboard & Ekspor CSV Lengkap (Selesai ✅)
- [x] **Layar Hasil Komparasi (4-Algorithm Scoreboard):** Menampilkan tabel perbandingan langsung (`A1`, `A2`, `B1`, `B2`) beserta jumlah langkah, selisih langkah, *Margin of Error (%)*, dan status (`Akurat` / `Overcounting` / `Undercounting`).
- [x] **Ekspor CSV Lengkap:** Mengekspor `sensor_data.csv` (9 kolom standar), `sensor_linear_data.csv` (dual-stream raw + linear), dan `evaluation_summary.csv` (mencakup keempat varian `A1–B2`).

### Fase 4: Eksekusi Protokol Eksperimen Fisik (100 Langkah — Siap Diuji di Perangkat Фиsik)
- [ ] **Uji Diam (Baseline Noise - 30 Detik):** HP diletakkan di meja tanpa melangkah (Target: 0 langkah pada A1, A2, B1, B2).
- [ ] **Uji Jalan 100 Langkah (Posisi Digenggam Tangan & Saku Depan):** Penguji menghitung manual 100 langkah berjalan.
- [ ] **Uji Jogging 100 Langkah (Posisi Digenggam Tangan & Saku Depan):** Penguji menghitung manual 100 langkah jogging.

---

## 4. Analisis Mengapa File `app-release.apk` Membengkak Jadi 51 MB

Saat perintah standar `flutter build apk` dijalankan tanpa flag tambahan, Flutter membuat **Fat APK (`app-release.apk`)** yang menggabungkan **3 binary engine C++ (`libflutter.so`) + kode kompilasi Dart (`libapp.so`)** sekaligus di dalam satu file:
1. `armeabi-v7a` (HP Android 32-bit lawas)
2. `arm64-v8a` (HP Android 64-bit modern — 99% HP saat ini)
3. `x86_64` (Emulator PC/Intel — sama sekali tidak terpakai di HP fisik!)

Karena 1 arsitektur engine Flutter (Impeller/Skia + Dart AOT runtime) berukuran ~14–16 MB, menggabungkan ketiganya dalam satu APK membuat ukurannya membengkak menjadi **~51 MB**.

### Strategi Pemangkasan Ukuran APK (51 MB → ~13–16 MB)
1. **Split per ABI (`--split-per-abi`):** Memisahkan APK berdasarkan arsitektur CPU sehingga penguji cukup mengunduh `arm64-v8a` tanpa membawa beban binary 32-bit dan emulator x86_64.
2. **R8 Code & Resource Shrinking (`android/app/build.gradle.kts`):** Mengaktifkan `isMinifyEnabled = true` dan `isShrinkResources = true` pada blok `buildTypes.release`.
3. **Font Icon Tree-Shaking (`--tree-shake-icons`):** Memangkas ribuan glyph font `MaterialIcons` menjadi hanya ikon yang benar-benar dipanggil di kode Dart.
4. **Debug Info Separation (`--obfuscate --split-debug-info=build/debug-info`):** Memisahkan tabel simbol debug dari binary `libapp.so`.

---

## 5. Rencana & Arsitektur GitHub Actions (CI/CD, Security, & Auto-Release)

Seluruh pipeline otomasi ditempatkan di `.github/workflows/` dengan dua workflow utama dan satu konfigurasi changelog:

### A. Workflow 1: `.github/workflows/ci.yml` (CI, Code Check, & Security Guard)
Berjalan otomatis pada setiap `push` ke semua branch dan `pull_request` ke `main`:
1. **Job 1 — `sensitive-file-guard`:** Memblokir commit jika ditemukan file sensitif: `.env`, `key.properties`, `*.jks`, `*.keystore`, `google-services.json`, `credentials/`, atau `temp/`.
2. **Job 2 — `secret-scanning` (Gitleaks):** Menjalankan `gitleaks/gitleaks-action@v2` pada riwayat repositori.
3. **Job 3 — `flutter-ci`:** Menjalankan `flutter pub get`, `flutter analyze`, dan `flutter test`.

### B. Workflow 2: `.github/workflows/auto-release.yml` (Build Slim APK & GitHub Release Otomatis)
Berjalan otomatis setiap kali developer mendorong *git tag* berawalan `v*` (misalnya `v1.0.0`):
1. Menyiapkan JDK 17 (`temurin`) + Flutter SDK dan menjalankan `flutter test`.
2. Mengompilasi APK ramping dengan `flutter build apk --release --split-per-abi --tree-shake-icons --obfuscate --split-debug-info=build/debug-info`.
3. Memberi nama file rilis:
   - `step-detection-${TAG}-arm64-v8a.apk` *(Utama — ~14-16 MB untuk semua HP Android modern)*
   - `step-detection-${TAG}-armeabi-v7a.apk` *(Cadangan — untuk HP Android 32-bit lama)*
4. Membuat **GitHub Release** otomatis dengan changelog (`mikepenz/release-changelog-builder-action@v5`) dan melampirkan kedua file APK (`softprops/action-gh-release@v2`).
