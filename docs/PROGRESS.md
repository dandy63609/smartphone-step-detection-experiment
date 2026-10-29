# Progress Tracker: Smartphone Step Detection Experiment

Dokumen ini mencatat seluruh fitur, algoritma, antarmuka pengguna (UI), pengujian, dan pipeline CI/CD yang telah selesai diimplementasikan pada proyek `smartphone-step-detection-experiment`.

---

## 1. Ringkasan Status Proyek

| Modul / Area | Status | Keterangan |
| :--- | :---: | :--- |
| **1. Dual Sensor Acquisition (`Raw` + `UserAccelerometer`)** | ✅ Selesai | Langganan paralel 100 Hz dengan sinkronisasi *timestamp* monotonik & *gravity filter fallback*. |
| **2. 4-Way Step Detection Engine (`A1, A2, B1, B2`)** | ✅ Selesai | Eksekusi serentak *Adaptive Midpoint* & *Mean + k·SD* pada sinyal *Raw (+G)* dan *Linear (-G)*. |
| **3. Stationary MEMS Noise Gate & Chart Lock** | ✅ Selesai | Ambang rentang dinamis minimum (`1.2 m/s²`) mencegah *false step* saat HP diam di meja; skala grafik dikunci min `6.0 m/s²`. |
| **4. Redesign UI Google Material Design 3** | ✅ Selesai | Seluruh 5 layar dirombak dengan gaya Google Fit / Health Connect (`#1A73E8`, *SegmentedButton*, *Circular Step Gauge*). |
| **5. 4-Algorithm Scoreboard & Integrity Verification** | ✅ Selesai | Tabel komparasi langsung `A1–B2` dengan status (`Akurat`, `Overcounting`, `Undercounting`) & validasi *live vs replay*. |
| **6. Penyimpanan Imutabel & Ekspor 3 CSV** | ✅ Selesai | Penyimpanan JSON lokal + ekspor `sensor_data.csv`, `sensor_linear_data.csv`, dan `evaluation_summary.csv`. |
| **7. Automated Unit & Widget Test Suite** | ✅ Selesai | 14 pengujian otomatis lulus 100% (termasuk uji diam 30 detik & sinyal sintetik 100 langkah untuk 4 varian). |
| **8. GitHub Actions CI, Gitleaks, & Auto-Release APK** | ✅ Selesai | Workflow `ci.yml` & `auto-release.yml` (`--split-per-abi` + R8 shrinking: ~51 MB → ~15 MB). |
| **9. Dokumentasi & Lisensi** | ✅ Selesai | `README.md`, `docs/PLANNING.md`, `docs/ARCHITECTURE.md`, `docs/PILOT_PROTOCOL.md`, `PROGRESS.md`, & `LICENSE` (MIT). |
| **10. Eksekusi Protokol Eksperimen Fisik (Lapangan)** | ⏳ Tahap Uji Fisik | Pengambilan data nyata 100 langkah oleh penguji menggunakan APK di perangkat Android. |

---

## 2. Rincian Fitur & Komponen yang Telah Diimplementasikan

### A. Akuisisi Sensor & Pemrosesan Sinyal (`lib/services/` & `lib/algorithms/`)
- [x] **Dual-Stream Sensor Recording (`lib/services/recording_service.dart`):**
  - Membaca `accelerometerEventStream` (Stream A: menyertakan gravitasi $\approx 9.81\ \text{m/s}^2$) dan `userAccelerometerEventStream` (Stream B: percepatan linear murni $\approx 0.0\ \text{m/s}^2$ saat diam).
  - Menyediakan *causal low-pass gravity filter fallback* ($\alpha = 0.8$) apabila perangkat tidak memiliki *virtual linear sensor* atau saat dijalankan di lingkungan pengujian.
- [x] **Causal Moving Average Smoothing (`lib/algorithms/step_detector.dart`):**
  - Perataan sinyal magnitudo menggunakan jendela masa lalu & sampel saat ini saja (tanpa sampel masa depan) demi menjaga kesetaraan *real-time* dan *offline replay*.
- [x] **4 Kombinasi Algoritma Serentak (`StepDetector.replayAllFour`):**
  - **A1 (`adaptive_midpoint`):** Ambang $T(t) = \frac{\max + \min}{2}$ pada *Raw Accelerometer (+Gravity)*.
  - **A2 (`adaptive_midpoint_linear`):** Ambang $T(t) = \frac{\max + \min}{2}$ pada *User Accelerometer (-Gravity)*.
  - **B1 (`mean_std`):** Ambang $T(t) = \mu + k\sigma$ pada *Raw Accelerometer (+Gravity)*.
  - **B2 (`mean_sd_linear`):** Ambang $T(t) = \mu + k\sigma$ pada *User Accelerometer (-Gravity)*.
- [x] **Stationary Noise Gate (`minWindowSpreadMps2 = 1.2` $\text{m/s}^2$):**
  - Memastikan fluktuasi *thermal micro-noise* MEMS ($\approx \pm 0.03\ \text{m/s}^2$) saat HP diletakkan diam di atas meja menghasilkan **0 langkah**, sementara perekaman sampel sensor 100 Hz tetap berjalan utuh.
- [x] **Valley Confirmation & Refractory Lockout (`250 ms`):**
  - Mencegah penghitungan ganda (*double-triggering*) pada satu hentakan langkah.

---

### B. Antarmuka Pengguna Google Material Design 3 (`lib/screens/` & `lib/main.dart`)
- [x] **Tema Global Material 3 (`lib/main.dart`):**
  - Skema warna Google Blue (`#1A73E8`), permukaan bersih (`#F8FAFD`), kartu tanpa elevasi kasar dengan sudut `20px`, dan tombol pil (`StadiumBorder`).
- [x] **Dashboard Screen (`lib/screens/dashboard_screen.dart`):**
  - Kartu ringkasan progres dengan *Circular Progress Ring* (`X / 40 Trials`), rata-rata akurasi keseluruhan, serta daftar 8 kondisi faktorial (**E1–E8**) dengan bar progres 5-segmen per kondisi.
- [x] **Setup Screen (`lib/screens/setup_screen.dart`):**
  - Indikator kesiapan sensor *real-time*, pengisian otomatis kode kondisi (`E1–E8`), pemilihan faktor menggunakan `SegmentedButton`, serta pengaturan parameter lanjutan (`Sampling Rate`, `Smoothing`, `Window Duration`, `Step Lockout`, `k`, dan `Stationary Gate`).
- [x] **Live Recording Screen (`lib/screens/live_recording_screen.dart`):**
  - Hitung mundur persiapan 3 detik (`3... 2... 1...`).
  - *Circular Step Gauge* besar dengan animasi *pulse* setiap kali langkah terdeteksi.
  - Indikator status gerak *real-time*: **`Stationary (Idle)`** vs **`Motion Active`**.
  - Grafik *live waveform* dengan skala vertikal minimum terkunci (`6.0 m/s²`), kurva magnitudo bergradasi, garis *threshold* putus-putus (*dashed*), dan titik hijau penanda puncak langkah.
- [x] **Results & 4-Algorithm Scoreboard Screen (`lib/screens/results_screen.dart`):**
  - Lencana verifikasi integritas eksperimen (*Live Step Count == Offline Replay Count*).
  - **Tabel Scoreboard 4 Algoritma (`A1, A2, B1, B2`)** yang menampilkan langkah terdeteksi, selisih langkah bertanda (`signedErrorSteps`), *Margin of Error (%)*, penanda pemenang otomatis, dan status (`Akurat`, `Overcounting`, `Undercounting`).
  - Kartu komparasi berdampingan dan tombol navigasi cepat **Next Trial (#N)**.
- [x] **Export Screen (`lib/screens/export_screen.dart`):**
  - Ringkasan jumlah *trial*, total sampel mentah, rincian skor `A1/A2/B1/B2` per rekaman, dan fitur *one-tap share* 3 file CSV via Android Share Sheet.

---

### C. Penyimpanan Data & Ekspor CSV (`lib/services/`)
- [x] **Immutable JSON Repository (`lib/services/recording_repository.dart`):**
  - Menyimpan setiap sesi sebagai file JSON imutabel (`REC_YYYYMMDD_NNN.json`) lengkap dengan sampel mentah, sampel linear, dan hasil *replay* 4 varian.
- [x] **3 Skema File CSV (`lib/services/csv_export.dart` & `lib/services/export_service.dart`):**
  1. `sensor_data.csv` — 9 kolom standar sesuai spesifikasi `AGENTS.md` §11.1.
  2. `sensor_linear_data.csv` — 13 kolom *dual-stream* (`ax, ay, az, mag_raw, ux, uy, uz, mag_user`).
  3. `evaluation_summary.csv` — Ringkasan performa keempat varian (`A1, A2, B1, B2`) terhadap patokan 100 langkah.

---

### D. CI/CD, Keamanan, & Optimasi Rilis APK (`.github/workflows/` & `android/`)
- [x] **Optimasi Ukuran APK (~51 MB → ~13–16 MB):**
  - Mengaktifkan R8 `isMinifyEnabled = true` dan `isShrinkResources = true` di `android/app/build.gradle.kts`.
  - Menggunakan `--split-per-abi --tree-shake-icons --obfuscate --split-debug-info=build/debug-info`.
- [x] **Workflow CI & Security Guard (`.github/workflows/ci.yml`):**
  - **`sensitive-file-guard`**: Memblokir `.env`, `key.properties`, `*.jks`, `*.keystore`, `google-services.json`, dan `credentials/`.
  - **`secret-scanning`**: Memindai kebocoran kredensial dengan **Gitleaks** (`gitleaks/gitleaks-action@v2`).
  - **`flutter-ci`**: Menjalankan `flutter pub get`, `flutter analyze`, dan `flutter test` otomatis.
- [x] **Workflow Auto-Release APK (`.github/workflows/auto-release.yml` & `.github/changelog-config.json`):**
  - Berjalan saat *push tag* `v*` (contoh: `v1.0.0`).
  - Mem-build APK `arm64-v8a` & `armeabi-v7a`, menyusun *changelog* otomatis dari *commit message*, dan mengunggah APK langsung ke halaman **GitHub Releases**.

