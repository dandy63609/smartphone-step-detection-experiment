# Stradio: Smartphone Step Detection & Reactive Sports-Music App

**Stradio** (*"Stride + Audio: Movement Becomes Music"*) is a dual-mode Flutter application combining a consumer-friendly **reactive running & walking companion (`v0.2.0`)** with a full-featured **biomechanical step-detection research laboratory**.

Under the hood, Stradio processes real-time 100 Hz smartphone accelerometer streams and compares adaptive-threshold step-detection algorithms (**Adaptive Midpoint** and **Mean + $k\cdot\text{SD}$**) across both **Raw Accelerometer (with gravity)** and **User/Linear Accelerometer (without gravity)** streams for walking and jogging activities under different phone placements (`hand` vs. `pocket`).

---

## Key Features

### 1. Consumer Experience (`v0.2.0` Default Mode)
- **Zero-Account Local-First Onboarding (2 Steps):**
  - **Step 1 (Welcome & Privacy):** 100% local profile and workout storage promise with live **English** (default) and **Bahasa Indonesia** language switching.
  - **Step 2 (Quick Personalization):** Optional nickname (with 1-tap `Skip` defaulting to `"Runner"`), optional height in cm (`100-240 cm`) for personalized stride-length calibration, Daily Step Goal presets (`3,000`, `5,000`, `8,000`, `10,000`, custom input, or `Open Goal`), and a transparent **Anonymous Performance Stats (PostHog)** opt-out toggle.
- **Floating Island 5-Slot Navigation Shell:**
  - Persistent bottom navigation capsule (`Home`, `Library`, elevated `Sonic Coral` center `Run` / `Lari` action button, `Activity`, and `Settings`) built exclusively with official Flutter Material vector icons.
  - **Contextual Pre-Run Goal Selector Sheet:** When using a Daily Step Goal, tapping `Run` lets the user choose between **Continue Daily Target** (automatically targeting the remaining steps for today) or **Open Goal (Free Run)**.
- **Runner Home Screen & Same-Day Step Accumulation:**
  - Asymmetric two-tone greeting header with Light/Dark theme toggle (`Warm Ivory` Light Mode and `Deep Obsidian` Night Run Mode).
  - **Daily Goal Hero Card** with an animated circular progress ring (`450 ms`), celebratory goal-reached banner, and accumulated daily `Steps`, `Distance (km)`, and `Active Time` across all sessions recorded on the same calendar day.
  - **Active Soundscape Strip & Quick Start Presets:** 1-tap launch into *Lo-Fi Pace (118 BPM)*, *Tempo Jog (145 BPM)*, or *Neon Stride (165 BPM)*.
- **Music-Style Soundscape Library (`LibraryScreen`):**
  - **Active Soundscape Hero Card** with ideal SPM cadence range, animated rhythm bars, 1-tap `Run This Tempo` button, and a contextual goal-mode selector button.
  - Horizontal category filter chips (`All`, `Chill`, `Jog`, `Fast`, `Favorites`), inline honest audio preview notice, and persistent favorite themes.
- **Activity Journal & Bilingual Settings (`ActivityScreen` & `SettingsScreen`):**
  - **7-Day Step Trend Bar Chart** and weekly totals that dynamically filter by `All`, `Walking`, or `Jogging` sessions, sorted chronologically with newest runs first.
  - Full profile and daily goal editor sheet, Android pocket/battery optimization guide, and explicit confirmation dialog for clearing local workout history.
- **Storage-Optimized Consumer Sessions:**
  - When **Developer Mode is OFF**, completed workouts save lightweight ~1 KB summary JSON files (preserving step counts, duration, target BPM, and cadence consistency buckets while stripping raw 100 Hz sensor arrays) so history loading is instant.
- **Resilient Lifecycle & Lockscreen Controls:**
  - Incremental active-session crash recovery cache (`.temp_active_run.json`) and Android Foreground Service (`flutter_foreground_task`) with interactive lockscreen `Pause / Resume` and `Finish` controls.

### 2. Hidden Developer & Research Laboratory Mode
- **7-Tap Unlock & 1-Tap Exit:**
  - Tap **`Stradio v0.2.0`** 7 times at the bottom of the `Settings` tab to unlock the **`Developer & Research Tools`** card. Flip the top **`Developer Mode`** switch OFF anytime to return immediately to the clean consumer UI.
- **4-Algorithm Simultaneous Benchmark (`A1`, `A2`, `B1`, `B2`):**
  - When Developer Mode is ON, each trial records full 100 Hz dual sensor streams and evaluates all 4 algorithm variants side-by-side against a standardized **100 physical steps** ground truth ($N_{\text{true}} = 100$):

  | Code | Threshold Algorithm | Sensor Input Stream | Description |
  | :---: | :--- | :--- | :--- |
  | **A1** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | Raw Accelerometer (+Gravity) | Primary consumer & baseline adaptive midpoint with gravity ($\approx 9.81\ \text{m/s}^2$). |
  | **A2** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | User Accelerometer (Linear -Gravity) | Tests whether gravity removal stabilizes the dynamic midpoint. |
  | **B1** | **Mean + $k\cdot\text{SD}$** ($\mu + k\sigma$) | Raw Accelerometer (+Gravity) | Statistical deviation threshold on raw magnitude. |
  | **B2** | **Mean + $k\cdot\text{SD}$** ($\mu + k\sigma$) | User Accelerometer (Linear -Gravity) | Statistical deviation threshold on pure linear acceleration. |

- **Stationary Noise Gate (`minWindowSpreadMps2 = 1.2` $\text{m/s}^2$):**
  - Prevents thermal/MEMS micro-noise ($\approx \pm 0.03\ \text{m/s}^2$) from triggering false steps when the phone rests stationary on a table.
- **Sensor Labs & Complete CSV Dataset Export:**
  - Live 100 Hz telemetry overlay, 4-Algorithm Replay Scoreboard on `PostRunSummaryScreen`, and 1-tap native sharing of `sensor_data.csv`, `sensor_linear_data.csv`, and `evaluation_summary.csv`.

---

## Installation & Running

Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Dart `^3.11.0+`).

1. Clone the repository and install dependencies:

```bash
git clone https://github.com/dandy63609/smartphone-step-detection-experiment.git
cd smartphone-step-detection-experiment
flutter pub get
```

2. Run on a physical Android device (optionally supplying local environment variables via `.env`):

```bash
flutter run --dart-define-from-file=.env
```

Or download the latest pre-built **`step-detection-v*-arm64-v8a.apk`** directly from the repository's **GitHub Releases** page.

---

## Project Architecture

```text
lib/
├── algorithms/       # Causal moving average, rolling window stats, A1/A2/B1/B2 StepDetector
├── evaluation/       # 100-step ground-truth evaluation & height-calibrated RunMetricsCalculator
├── l10n/             # Compile-time verified bilingual strings (EN default + Bahasa Indonesia)
├── models/           # StradioUserProfile, ExperimentConfig, SensorSample, SavedRecording
├── screens/
│   ├── stradio/      # Consumer & Hybrid UI: Onboarding, RootNavigationShell, HomeScreen,
│   │                 # LibraryScreen, ActivityScreen, SettingsScreen, ActiveRunScreen,
│   │                 # PostRunSummaryScreen, SensorLabsSheet
│   └── ...           # Legacy E1-E8 Research Matrix screens (Dashboard, Setup, Live, Results, Export)
├── services/         # Accelerometer stream, RecordingStore, Preferences, PostHog, Foreground task
├── theme/            # StradioTheme tokens (Warm Ivory Light & Deep Obsidian Dark, 100% borderless)
└── widgets/          # Official Stradio topographical ribbon logo & waveform badges
```

---

## Glossary & Biomechanical-Audio Concepts

### 1. Biomechanical & Motion Dynamics

- **SPM (Steps Per Minute / Cadence):**
  The physical frequency of foot strikes per minute executed by the runner or walker, calculated over a rolling time window from peak-to-peak step intervals:
  $$\text{SPM} = \frac{60}{\Delta t_{\text{step}}}$$
- **Ground Truth 100 Steps ($N_{\text{true}} = 100$):**
  The fixed physical benchmark used for controlled research trials. Because $N_{\text{true}} = 100$, any step count deviation translates directly to a percentage margin of error:
  $$\text{Margin of Error} = \lvert N_{\text{predicted}} - 100 \rvert$$
- **Phone Placement (`hand` vs. `pocket`):**
  Standardized carrying locations. Hand-held captures arm swing dynamics; pocket placement isolates hip and leg translation.
- **Height-Calibrated Stride Length & Estimated Running Speed:**
  Instantaneous speed is approximated from cadence and stride length ($L_{\text{stride}}$):
  $$v = \text{SPM} \times L_{\text{stride}}$$
  When the user provides height ($h_{\text{cm}} \in [100, 240]\ \text{cm}$), stride length is calibrated as $L_{\text{walk}} = 0.00415 \times h_{\text{cm}}$ and $L_{\text{jog}} = 0.0055 \times h_{\text{cm}}$ (falling back to $0.74\ \text{m}$ for walking and $0.95\ \text{m}$ for jogging when unset).

### 2. Audio-Stride & Soundscape Catalog

- **BPM (Beats Per Minute / Music Tempo):**
  The musical tempo of the active soundscape. Stradio compares the runner's real-time cadence ($\text{SPM}$) against target $\text{BPM}$ to compute the **Rhythm Score (0-100%)**.
- **Curated Soundscape Themes:**
  - **Chill Walk (110 BPM):** Easy morning stroll and steady breathing.
  - **Lo-Fi Pace (118 BPM):** Brisk city walk and warm-up groove.
  - **Tempo Jog (145 BPM):** Balanced endurance cadence for steady jogging.
  - **Neon Stride (165 BPM):** High-energy synth pulse for responsive running.
  - **Sprint Surge (180 BPM):** Peak-cadence drive for fast intervals.

### 3. Signal Processing & Sensor Telemetry

- **3-Axis Raw Accelerometer ($a_x, a_y, a_z$):**
  Tri-axial acceleration in $\text{m/s}^2$ including Earth gravity ($\approx 9.81\ \text{m/s}^2$ at rest).
- **Linear / User Accelerometer ($u_x, u_y, u_z$):**
  Acceleration in $\text{m/s}^2$ with gravity removed.
- **Euclidean Vector Norm / Magnitude ($m(t)$):**
  Orientation-independent scalar total acceleration:
  $$m(t) = \sqrt{a_x(t)^2 + a_y(t)^2 + a_z(t)^2}$$
- **Causal Moving-Average Filter:**
  Low-pass smoothing filter using strictly past and current samples ($N = 3$) without look-ahead bias:
  $$s(t) = \frac{1}{N}\sum_{i=0}^{N-1} m(t - i)$$
- **Rolling Threshold Window ($T_w = 1000\ \text{ms}$):**
  A 1-second sliding buffer of smoothed magnitude values used to compute the dynamic threshold $T(t)$.
- **Refractory Lockout Period ($250\ \text{ms}$) & Valley Confirmation:**
  Enforces a minimum physiological interval between steps ($\le 240\ \text{SPM}$) and requires the signal to dip below a valley threshold before confirming the next step peak.

### 4. 4-Algorithm Matrix (`A1`, `A2`, `B1`, `B2`)

- **A1 - Adaptive Midpoint (Raw):**
  $$T(t) = \frac{\max(\text{window}) + \min(\text{window})}{2}$$
  Computed over raw accelerometer magnitude ($+g$). Used as the primary live step detector in consumer mode.
- **A2 - Adaptive Midpoint (Linear):**
  Same midpoint formula applied to linear acceleration ($-g$).
- **B1 - Mean + $k\cdot\text{SD}$ (Raw):**
  $$T(t) = \mu(\text{window}) + k \cdot \sigma(\text{window}),\quad k = 1.5$$
  Statistical threshold requiring foot strikes to exceed the window mean by $1.5$ standard deviations.
- **B2 - Mean + $k\cdot\text{SD}$ (Linear):**
  Statistical deviation threshold on pure linear acceleration ($-g$).

### 5. Evaluation Metrics & Classifications

- **Absolute Step Error:**
  $$\text{Absolute Error} = \lvert N_{\text{predicted}} - N_{\text{true}} \rvert = \lvert N_{\text{predicted}} - 100 \rvert$$
- **Percentage Margin of Error (out of 100 steps):**
  $$\text{Margin of Error} = \frac{\lvert N_{\text{predicted}} - 100 \rvert}{100} \times 100 = \lvert N_{\text{predicted}} - 100 \rvert$$
- **Step Count Accuracy:**
  $$\text{Accuracy} = \max(0,\ 100 - \text{Margin of Error})$$
- **Scoreboard Performance Classification:**
  - **`Akurat` (Accurate):** $\text{Margin of Error} \le 3.0$ ($97$ to $103$ detected steps).
  - **`Overcounting`:** $N_{\text{predicted}} > 103$ steps.
  - **`Undercounting`:** $N_{\text{predicted}} < 97$ steps.

---

## Running Tests

Run static analysis and the full automated test suite (52 unit and widget tests covering signal processing, height-calibrated stride metrics, summary-only vs. raw storage, bilingual localization, 2-step onboarding, 5-slot floating navigation shell, `HomeScreen` daily accumulation, `LibraryScreen` tempo catalog, `ActivityScreen` 7-day trends, `SettingsScreen` profile & developer suite, and full 4-screen research workflows):

```bash
flutter analyze
flutter test
```

---

## License

This project is licensed under the [MIT License](LICENSE).
