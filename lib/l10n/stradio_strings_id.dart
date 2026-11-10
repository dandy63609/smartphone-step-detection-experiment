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
  String get audioComingSoonNotice =>
      'Integrasi file audio segera hadir. Tempo ini sudah aktif untuk sesi larimu.';
  @override
  String get emptyActivityBody =>
      'Belum ada sesi tersimpan. Tekan Lari di bawah untuk mulai langkah pertamamu.';

  // --- Developer Mode ---
  @override
  String get devModeEnabledToast => 'Mode Pengembang diaktifkan.';
  @override
  String get devModeDisabledToast => 'Mode Pengembang dinonaktifkan.';
  @override
  String devModeTapsRemaining(int remaining) =>
      '$remaining ketukan lagi untuk membuka Mode Pengembang.';
}

