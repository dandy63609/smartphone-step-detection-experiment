# Eksperimen Deteksi Langkah dari Ponsel

Aplikasi Android berbasis Flutter/Dart untuk mengumpulkan data akselerometer
ponsel dan membandingkan dua algoritma deteksi langkah dengan ambang adaptif.

## Tujuan penelitian

Eksperimen ini membandingkan:

1. **Titik tengah adaptif:** `(nilai maksimum + nilai minimum) / 2`
2. **Rata-rata plus standar deviasi:** `rata-rata + k × standar deviasi`

Kedua algoritma harus memproses rekaman mentah yang sama, pipeline smoothing
yang sama, aturan puncak yang sama, durasi jendela adaptif yang sama, serta
interval minimum antarlangkah yang sama.

Pilot awal menggunakan dua aktivitas (berjalan dan jogging) serta dua posisi
ponsel (digenggam dan saku). Target awalnya lima pengulangan per kondisi dan
jumlah pengulangan dapat ditambah. Pilot ini bersifat eksploratif dan tidak
digunakan untuk menyatakan signifikansi statistik.

## Kemampuan yang direncanakan

- Merekam nilai akselerometer X/Y/Z dengan timestamp monotonik.
- Menyimpan magnitudo mentah dan mengukur interval sampling aktual.
- Memutar ulang setiap rekaman melalui kedua algoritma secara offline.
- Mengimpor timestamp langkah dari anotasi ground truth manual.
- Menghitung metrik event, jumlah langkah, latensi, dan pemrosesan.
- Mengekspor data sensor, deteksi, ground truth, dan hasil evaluasi ke CSV.
- Menjaga rekaman mentah tetap utuh serta menyimpan parameter setiap proses.

## Batasan ruang lingkup

Proyek ini bersifat lokal terlebih dahulu. Proyek tidak memerlukan akun,
backend, upload cloud, pembayaran, GPS, atau analytics. Gravitasi tetap
termasuk dalam eksperimen magnitudo mentah awal. Pemutaran audio, prediksi
cadence, implementasi Kotlin/native, dan machine learning kompleks ditunda
sampai pipeline sensor dan detektor tervalidasi pada ponsel Android fisik.

## Status saat ini

Repository ini berisi scaffold aplikasi Flutter. Milestone implementasi
berikutnya adalah pipeline end-to-end minimal:

1. Mengatur konfigurasi rekaman.
2. Mengambil dan menyimpan sampel akselerometer.
3. Memutar ulang kedua algoritma pada sampel yang identik.
4. Menyimpan hasil dan mengekspor file CSV.

Nilai placeholder dan sinyal sintetis tidak boleh dianggap sebagai hasil
eksperimen nyata.

## Pengembangan

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Validasi sensor harus dilakukan pada ponsel Android fisik. Pengujian emulator
dan sinyal sintetis berguna untuk logika perangkat lunak, tetapi tidak dapat
menggantikan rekaman berjalan dan jogging di dunia nyata.

Lihat `AGENTS.md` untuk aturan teknis, integritas eksperimen, dan batasan
implementasi lengkap.
