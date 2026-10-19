# Panduan Agen Repository

Repository ini mengimplementasikan eksperimen Flutter/Dart untuk deteksi
langkah dari sensor ponsel.

- Prioritaskan perekaman sensor pada perangkat fisik dan akurasi yang diukur.
- Simpan nilai akselerometer X/Y/Z mentah, timestamp, serta magnitudo turunan.
- Bandingkan algoritma titik tengah adaptif dan rata-rata plus standar deviasi
  pada sampel yang identik.
- Pisahkan akuisisi sensor, pemrosesan sinyal, penyimpanan, evaluasi, ekspor,
  dan UI.
- Simpan rekaman secara lokal; jangan menambahkan akun, backend, analytics,
  pembayaran, atau upload tanpa kebutuhan dan persetujuan yang jelas.
- Jangan mengarang dataset, hasil, klaim performa, dukungan perangkat, atau
  perilaku permission.
- Gunakan rekaman berlabel dan data hold-out saat melaporkan precision, recall,
  F1, latensi, dan error jumlah langkah.
- Buat unit test deterministik untuk logika murni dan validasi sampling aktual
  pada ponsel Android fisik.
- Tunda audio, prediksi cadence, implementasi Kotlin/native, machine learning
  kompleks, dan statistik inferensial sampai baseline tervalidasi.
- Simpan parameter persis setiap proses, jangan ubah data mentah setelah
  disimpan, dan bedakan data pilot dari data evaluasi.
- Jangan menyatakan build atau test berhasil jika belum benar-benar dijalankan
  dan diverifikasi.

README.md berisi ringkasan proyek dan milestone saat ini. Dokumen brief lengkap
menjadi dasar untuk menjaga protokol eksperimen tetap konsisten.
