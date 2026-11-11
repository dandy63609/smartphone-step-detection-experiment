import 'stradio_strings.dart';

/// Bahasa Indonesia translation implementation.
class StradioStringsId extends StradioStrings {
  const StradioStringsId();

  // --- Navigation (Floating Island 5-Slot) ---
  @override
  String get navHome => 'Beranda';
  @override
  String get navLibrary => 'Koleksi';
  @override
  String get navRun => 'Lari';
  @override
  String get navActivity => 'Aktivitas';
  @override
  String get navSettings => 'Setelan';

  // --- Onboarding Step 1: Welcome & Privacy ---
  @override
  String get onboardingWelcomeTitle => 'Temukan Ritme Langkahmu';
  @override
  String get onboardingWelcomeSubtitle =>
      'Sinkronkan langkah jalan dan larimu dengan tempo musik yang responsif.';
  @override
  String get onboardingPrivacyBadge => 'Privasi Lokal 100%';
  @override
  String get onboardingPrivacyBody =>
      'Profil dan riwayat olahragamu tersimpan aman di HP ini. Tanpa akun dan tanpa login.';
  @override
  String get onboardingLanguageLabel => 'Pilih Bahasa Aplikasi';
  @override
  String get onboardingContinueButton => 'Lanjut';

  // --- Onboarding Step 2: Quick Personalization ---
  @override
  String get onboardingProfileTitle => 'Personalisasi Singkat';
  @override
  String get onboardingProfileSubtitle =>
      'Sesuaikan sapaan dan estimasi jarak langkahmu. Bisa diubah kapan saja di Setelan.';
  @override
  String get nicknameLabel => 'Nama Panggilan';
  @override
  String get nicknameHint => 'Misal: Raka (opsional)';
  @override
  String get skipNicknameButton => 'Lewati (Pakai "Runner")';
  @override
  String get heightLabel => 'Tinggi Badan (cm, opsional)';
  @override
  String get heightHint => 'Contoh: 170';
  @override
  String get heightHelper =>
      'Digunakan untuk menghitung panjang langkah dan jarak tempuh secara lebih akurat.';
  @override
  String get dailyGoalSectionTitle => 'Target Langkah Harian';
  @override
  String get openGoalOptionLabel => 'Open Goal (Tanpa Target)';
  @override
  String get customGoalHint => 'Target langkah sendiri';
  @override
  String get telemetryToggleTitle => 'Statistik Performa Anonim';
  @override
  String get telemetryToggleSubtitle =>
      'Bagikan statistik latihan & akurasi langkah secara anonim untuk bantu pengembangan Stradio. Nama dan file sensor tetap privat.';
  @override
  String get onboardingStartButton => 'Mulai Gunakan Stradio';
  @override
  String get onboardingBackButton => 'Kembali';

  // --- Home Screen ---
  @override
  String get homeGreetingPrefix => 'Halo lagi,';
  @override
  String get homeDailyGoalTitle => 'Progres Hari Ini';
  @override
  String get homeOpenGoalBadge => 'Mode Bebas Hari Ini';
  @override
  String homeStepsOfTarget(String current, String target) =>
      '$current / $target langkah';
  @override
  String get homeGoalReachedBanner =>
      'Target harian tercapai. Lanjut terus atau istirahat kapan saja.';
  @override
  String get metricSteps => 'LANGKAH';
  @override
  String get metricDistance => 'JARAK';
  @override
  String get metricActiveTime => 'WAKTU AKTIF';
  @override
  String get activeSoundscapeLabel => 'Tema Tempo Aktif';
  @override
  String get changeSoundscapeAction => 'Ubah';
  @override
  String get quickStartTitle => 'Mulai Cepat';
  @override
  String get recentSessionTitle => 'Sesi Terakhir';
  @override
  String get emptyHomeHistoryTitle => 'Siap untuk langkah pertamamu?';
  @override
  String get emptyHomeHistoryBody =>
      'Pilih salah satu tempo Mulai Cepat di atas atau tekan tombol Lari di tengah bawah.';

  // --- Pre-Run Goal Selector Sheet ---
  @override
  String get preRunSheetTitle => 'Pilih Mode Target Sesi';
  @override
  String get preRunContinueDailyTitle => 'Lanjutkan Target Harian';
  @override
  String preRunRemainingStepsSubtitle(String remaining) =>
      'Sisa $remaining langkah lagi untuk mencapai target hari ini.';
  @override
  String get preRunDailyAlreadyMetSubtitle =>
      'Target hari ini sudah tercapai. Tambah langkah ekstra hari ini.';
  @override
  String get preRunOpenGoalTitle => 'Open Goal (Lari Bebas)';
  @override
  String get preRunOpenGoalSubtitle =>
      'Bergerak bebas tanpa batas target langkah.';

  // --- Library & Audio Placeholder ---
  @override
  String get libraryHeaderSubtitle =>
      'Selaraskan kadensi langkahmu dengan tema tempo yang responsif.';
  @override
  String get libraryFilterAll => 'Semua';
  @override
  String get libraryFilterFavorites => 'Favorit';
  @override
  String get libraryEmptyFavoritesTitle => 'Belum ada tema favorit';
  @override
  String get libraryEmptyFavoritesBody =>
      'Ketuk ikon hati pada tema tempo mana saja untuk menyimpannya di sini.';
  @override
  String get libraryRunWithThemeAction => 'Lari dengan Tempo Ini';
  @override
  String get libraryPreviewingBadge => 'Pratinjau Tempo';
  @override
  String get audioComingSoonNotice =>
      'Integrasi file audio segera hadir. Tempo ini sudah aktif untuk sesi larimu.';
  @override
  String get emptyActivityBody =>
      'Belum ada sesi tersimpan. Tekan Lari di bawah untuk mulai langkah pertamamu.';

  // --- Activity Journal ---
  @override
  String get activityWeeklyTitle => '7 Hari Terakhir';
  @override
  String get activityFilterAll => 'Semua';
  @override
  String get activityFilterWalking => 'Jalan';
  @override
  String get activityFilterJogging => 'Lari';
  @override
  String activitySessionsCount(int count) => '$count sesi';
  @override
  String get activityEmptyFilterBody =>
      'Belum ada sesi untuk filter aktivitas ini.';
  @override
  String get activityStartFirstRunAction => 'Mulai Lari Pertama';

  // --- Settings & Profile ---
  @override
  String get settingsProfileSectionTitle => 'Profil Pelari & Target Harian';
  @override
  String get settingsEditProfileAction => 'Ubah Profil & Target';
  @override
  String get settingsSaveProfileAction => 'Simpan Perubahan';
  @override
  String get settingsAppearanceTitle => 'Mode Tema';
  @override
  String get settingsAppearanceSubtitle =>
      'Beralih antara Terang Gading dan Gelap Karbon';
  @override
  String get settingsBatteryGuideTitle => 'Panduan Saku & Layar Mati';
  @override
  String get settingsBatteryGuideSubtitle =>
      'Atur penggunaan baterai ke Tanpa Pembatasan agar Android tidak menjeda deteksi langkah saat HP di dalam saku.';
  @override
  String get settingsClearHistoryAction => 'Hapus Riwayat Latihan';
  @override
  String get settingsClearHistoryConfirmTitle => 'Hapus semua riwayat latihan?';
  @override
  String get settingsClearHistoryConfirmBody =>
      'Tindakan ini menghapus permanen seluruh sesi tersimpan dan mereset progres hari ini di perangkat ini.';
  @override
  String get settingsClearHistoryClearedToast => 'Riwayat latihan dihapus.';
  @override
  String get settingsCancelAction => 'Batal';
  @override
  String get settingsDeleteAction => 'Hapus Semua';

  // --- Developer Mode ---
  @override
  String get settingsDevToolsTitle => 'Alat Pengembang & Riset';
  @override
  String get settingsDevToolsSubtitle =>
      'Perekaman sampel mentah 100 Hz, scoreboard 4 algoritma, dan ekspor dataset CSV aktif.';
  @override
  String get settingsOpenSensorLabsAction => 'Buka Sensor Labs & Diagnostik';
  @override
  String get settingsExportCsvAction => 'Ekspor Dataset Riset (CSV)';
  @override
  String get settingsOpenLegacyShellAction => 'Buka Shell Eksperimen E1-E8';
  @override
  String get devModeEnabledToast => 'Mode Pengembang diaktifkan.';
  @override
  String get devModeDisabledToast => 'Mode Pengembang dinonaktifkan.';
  @override
  String devModeTapsRemaining(int remaining) =>
      '$remaining ketukan lagi untuk membuka Mode Pengembang.';
}

