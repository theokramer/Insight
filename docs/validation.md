# Validation

Verified on this machine:

- The updated native iPhone simulator compilation succeeds with PDFKit, Apple Vision, RevenueCat, Superwall, Expo Router, and the mask gestures linked. Expo's final window-activation helper fails because System Events is unavailable; the compiled app is installed successfully.
- iPhone and Android production JavaScript bundles export successfully.
- Expo Doctor passes all 18 compatibility checks.
- TypeScript checks pass for the app and Worker.
- Expo lint passes without warnings after compatibility pinning to ESLint 9.
- Twenty-six app tests and fifteen backend tests pass, including label splitting, padding, corrected OCR text, multiline grouping, repeated labels, and duplicate prevention.
- The deployed protected Worker selected all 17 labels from the OCR regression fixture with real GPT, excluded the heading, and returned measured OCR geometry for every mask. Both native engines also pass upright and EXIF-rotation image tests. See [text detection verification](ocr-validation.md).
- Native Android compilation succeeds with installed Java 17 and SDK 36, including the local PDF/ML Kit module. The generated development APK targets arm64 devices.
- Both Superwall editor previews correctly switch yearly/weekly product indices, accessible radio selection, prices, and billing copy. The iPhone SE preview fits both choices, the purchase button, and legal labels without clipping. This verifies the editor design; native store checkout remains untested.

Verified October 4, 2026:

- Fixed shared text line-height sizing, top safe areas on tab screens and study completion, Create tab spacing, light-mode secondary text contrast, long diagram titles, and collection counts.
- Inspected Activity, Today, imports, Settings, and the mask editor in the iPhone 17 simulator. Activity's heading and statistics are now fully visible. The Today diagram caption sits below its drawing instead of covering a mask.
- Added remembered, withdrawable consent before image/OCR sharing with OpenAI, with tests for declining, allowing, and re-asking after withdrawal.
- Created and published Privacy Policy, Terms, and Support pages on GitHub Pages.
- Archived iOS 1.0.0 (20261004), arm64, signed under Theo Kramer, and uploaded it to the restored Schaubilder record (`de.tk.Insight`, Apple ID `6503291588`). App Store Connect shows **Ready to Submit** in TestFlight. This is an upload, not a public release.
- Apple accepted the upload with missing dSYM warnings for React, ReactNativeDependencies, and Hermes. Those frameworks' crash symbolication remains limited.

In progress / not yet claimed:

- The rebuilt iPhone app launches and shows its learning screens. Imports, PDF page handling, mask drag/resize, light/dark appearance, larger text, offline persistence, and complete study flows still need broader UI verification before release.
- Both Apple products now report Ready to Submit, RevenueCat is connected, and the iPhone Superwall treatment receives 100% traffic. Native purchases and restores are not yet verified. Public legal/support pages and the iPhone paywall legal actions are now published through GitHub Pages; Android legal actions are still pending.
- Native device performance, camera capture on physical hardware, and App Review submission are not yet verified.
- Legacy UIKit CoreData migration is not implemented. App Store history showed no earlier public release; only legacy development/TestFlight installations may have old libraries.

Verified October 14, 2026:

- Production backend deployed at the existing Insight hostname with RevenueCat project `55ee54de` and REST entitlement `entl7a5dfe0ff9`. The read-only credential is valid; health returns 200 and a non-subscriber GPT request returns 401. The old preview token no longer grants service access.
- Apple weekly and yearly plans are the same service level and both review images reached `UPLOAD_COMPLETE`; Apple reports both products `READY_TO_SUBMIT`.
- Release requests ignore persisted development backend addresses; regression tests reject insecure or credentialed destinations.
- Added direct Restore purchases and Terms controls in Settings. An offline launch no longer permanently disables the configured purchase SDK. The native restore action was exercised and correctly reports no active subscription on the unpaid QA device.
- The release configuration preflight passes. App tests, backend tests, lint, and both typechecks pass.
- Build `20261014` archived, exported, uploaded, and processed as `VALID` / `APP_STORE_ELIGIBLE`. It is attached to the manual-release draft and available in TestFlight. The owner confirmed a successful TestFlight purchase and GPT analysis.
- Native study grading advances the queue, and review totals survive a full restart. Library filtering and editing/saving/reopening mask text were exercised.
- Native Today, Study, Library, Activity, Settings, Create, and the current paywall were inspected. iPhone and 13-inch iPad listing screenshots are uploaded and processed. System photo picker presentation works; selecting photos and purchase-sheet automation are blocked by this session’s simulator coordinate controls.
- The owner confirmed content rights. Apple accepted the content-rights declaration. Free download pricing is configured. App Review has not been submitted.

## Context-aware card detail — next candidate `20261015`

- Fixed backend validation that previously rejected horizontally adjacent OCR fragments belonging to one label. Pixel-space checks account for image aspect ratio and reject distant groups.
- Preserved OCR word boxes for deliberate word-level selection, while whole-label mode expands accidental partial-word selections to their complete parent label.
- Added five native slider steps: Key ideas, Whole labels (default), Concepts, Fine detail, Individual words. A bounded optional learning focus supplies subject context. Preferences persist; each queued image captures its own settings.
- Existing images can be regenerated after confirmation. Failed or empty regeneration preserves previously saved cards.
- Live GPT evaluation on the original OCR fixture: 17 intact whole labels even with deliberately fragmented word candidates; 26 word cards at level 5; 15 labels in broad mode. Repeated labels retain separate positions. This demonstrates improvement on the fixture, not universal accuracy.
- Twenty-six app tests and fifteen backend tests pass, with lint and both typechecks. Native build and upload of this updated candidate are in progress. Do not submit the older build as the final candidate.
