# Repository Agent Guidance

This repository implements the Flutter/Dart smartphone step-detection
experiment.

- Prioritize reliable physical-device sensor recording and measured accuracy.
- Preserve raw accelerometer X/Y/Z values, timestamps, and derived magnitudes.
- Compare adaptive midpoint and mean-plus-standard-deviation algorithms on identical samples.
- Keep sensor acquisition, signal processing, persistence, evaluation, exports, and UI separate.
- Keep recordings local by default; do not add accounts, backend services, analytics, payments, or uploads without a clear need and approval.
- Do not invent datasets, results, performance claims, device support, or permission behavior.
- Use labeled recordings and held-out trials when reporting precision, recall, F1, latency, and count error.
- Write deterministic unit tests for pure logic and validate actual sampling on a physical Android phone.
- Defer audio, cadence prediction, Kotlin/native rewrites, complex ML, and inferential statistics until the baseline is validated.
- Store the exact parameters for every run, keep raw recordings immutable, and separate pilot data from evaluation data.
- Do not claim a build or test passed unless it was actually run and verified.

`README.en.md` contains the English project summary. The full project brief is
the source of truth for preserving the experiment protocol.
