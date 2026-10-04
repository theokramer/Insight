# Validation

Verified on this machine:

- The updated native iPhone simulator compilation succeeds with PDFKit, Apple Vision, RevenueCat, Superwall, Expo Router, and the mask gestures linked. Expo's final window-activation helper fails because System Events is unavailable; the compiled app is installed successfully.
- iPhone and Android production JavaScript bundles export successfully.
- Expo Doctor passes all 18 compatibility checks.
- TypeScript checks pass for the app and Worker.
- Expo lint passes without warnings after compatibility pinning to ESLint 9.
- Seven app tests and ten backend tests pass, including label splitting, padding, corrected OCR text, multiline grouping, repeated labels, and duplicate prevention.
- The deployed protected Worker selected all 17 labels from the OCR regression fixture with real GPT, excluded the heading, and returned measured OCR geometry for every mask. Both native engines also pass upright and EXIF-rotation image tests. See [text detection verification](ocr-validation.md).
- Native Android compilation succeeds with installed Java 17 and SDK 36, including the local PDF/ML Kit module. The generated development APK targets arm64 devices.
- Both Superwall editor previews correctly switch yearly/weekly product indices, accessible radio selection, prices, and billing copy. The iPhone SE preview fits both choices, the purchase button, and legal labels without clipping. This verifies the editor design; native store checkout remains untested.

In progress / not yet claimed:

- The rebuilt iPhone app launches and shows its learning screens. Imports, PDF page handling, mask drag/resize, light/dark appearance, larger text, offline persistence, and complete study flows still need broader UI verification before release.
- Store products and purchases are not live. Superwall designs and campaign treatments are saved on both platforms; treatment traffic is 0% pending legal URLs, RevenueCat configuration, and sandbox purchase checks.
- Native device performance, camera capture on physical hardware, and store submission are not yet verified.
- Legacy UIKit CoreData migration is not implemented; do not ship this over an existing production installation without a migration plan.
