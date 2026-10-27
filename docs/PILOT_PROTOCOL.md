# Physical Android Hardware Pilot Protocol (8 Conditions E1–E8)

This guide provides instructions for conducting the controlled 100-step detection pilot on physical Android smartphone hardware according to the experimental design in `AGENTS.md`.

---

## 1. Hardware Preparation

1. **Physical Device:** Android smartphone with hardware accelerometer running Android 8.0+ (API 26+).
2. **Developer Options:** Enable **USB Debugging** on the Android device.
3. **Connection:** Connect the phone to the development machine via USB cable and verify connection:
   ```bash
   flutter devices
   ```
4. **App Installation & Launch:**
   ```bash
   cd D:\dandy_personal\RUN_CENSOR_PROJECT\OFFICIAL_REPO_CENSOR_ONLY
   flutter run -d <device-id> --release
   ```

---

## 2. Experimental Design Matrix (E1–E8)

The pilot requires **5 repetitions** per combination across 8 conditions (total 40 physical recordings):

| Condition ID | Activity | Phone Placement | Primary Live Algorithm | Repetitions |
| :--- | :--- | :--- | :--- | :--- |
| **E1** | Walking | Hand-held | Adaptive midpoint | 5 |
| **E2** | Walking | Hand-held | Mean + k·SD | 5 |
| **E3** | Jogging | Hand-held | Adaptive midpoint | 5 |
| **E4** | Jogging | Hand-held | Mean + k·SD | 5 |
| **E5** | Walking | Pocket | Adaptive midpoint | 5 |
| **E6** | Walking | Pocket | Mean + k·SD | 5 |
| **E7** | Jogging | Pocket | Adaptive midpoint | 5 |
| **E8** | Jogging | Pocket | Mean + k·SD | 5 |

---

## 3. Standardized Execution Procedure per Trial

Each trial strictly evaluates against a true value of **exactly 100 physical steps**:

1. **Dashboard:** Select the condition card to test (e.g., E1), or tap **"New 100-Step Trial"**.
2. **Setup Verification:**
   - Confirm Participant ID (e.g., `P01`).
   - Confirm Activity (`Walking` or `Jogging`).
   - Confirm Placement:
     - **Hand:** Phone held in dominant hand, screen facing user, forearm roughly horizontal.
     - **Pocket:** Phone placed vertically in front pocket, screen oriented inward toward the thigh.
   - Ground Truth Steps: Fixed at `100`.
   - Tap **"Proceed to Live Trial"**.
3. **Preparation Countdown:**
   - A 3-second preparation countdown (`3... 2... 1...`) allows the participant to position the phone and assume the starting posture.
4. **Paced Physical Activity:**
   - Participant begins walking or jogging at a natural, consistent cadence.
   - The participant (or observer) counts physical steps up to exactly **100 steps**.
   - Live telemetry on screen displays the real-time detected step counter, step pulses, elapsed time, and signal waveform.
5. **Trial Completion:**
   - Exactly upon completing the 100th physical footstrike, tap **"Stop (100 Steps Completed)"**.
6. **Results & Replay Verification:**
   - Review the side-by-side benchmark (`adaptive_midpoint` vs `mean_std`).
   - Verify that **Experimental Integrity** displays a green checkmark indicating that live detections matched offline replay.
   - Tap **"Next Trial"** to automatically advance the trial index for the next repetition.

---

## 4. Exporting Data

1. Once trials are completed, navigate to **Export Datasets** via the Dashboard app bar icon.
2. Tap **"Export & Share CSV Package"**.
3. The app generates:
   - `sensor_data.csv`: Complete high-frequency raw timeseries.
   - `evaluation_summary.csv`: Margin of error and accuracy metrics for all trials.
4. Share the CSV files directly to Google Drive, email, or local files using Android's native share sheet.
