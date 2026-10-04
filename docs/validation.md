# Validation

Verified on this machine:

- Native iPhone simulator compilation succeeds with PDFKit, Apple Vision, RevenueCat, Superwall, Expo Router, and the mask gestures linked. Expo's final window-activation helper fails because System Events is unavailable; the compiled app is installed successfully.
- iPhone and Android production JavaScript bundles export successfully.
- Expo Doctor passes all 18 compatibility checks.
- TypeScript checks pass for the app and Worker.
- Expo lint passes without warnings after compatibility pinning to ESLint 9.
- Three learning tests and seven backend tests pass.
- The deployed protected Worker successfully analyzed a six-label neuron test image with real GPT, returning the six expected visible labels. A subsequent update aligns selected labels to matching native OCR boxes.
- Native Android compilation succeeds with installed Java 17 and SDK 36, including the local PDF/ML Kit module. The generated development APK targets arm64 devices.
- Both Superwall editor previews correctly switch yearly/weekly product indices, accessible radio selection, prices, and billing copy. The iPhone SE preview fits both choices, the purchase button, and legal labels without clipping. This verifies the editor design; native store checkout remains untested.

In progress / not yet claimed:

- Simulator visual/gesture QA is waiting for the owner to unlock the Mac. Screens, imports, PDF page handling, mask drag/resize, light/dark appearance, larger text, offline persistence, and study completion must be exercised before release.
- Store products and purchases are not live. Superwall designs and campaign treatments are saved on both platforms; treatment traffic is 0% pending legal URLs, RevenueCat configuration, and sandbox purchase checks.
- Native device performance, camera capture on physical hardware, and store submission are not yet verified.
- Legacy UIKit CoreData migration is not implemented; do not ship this over an existing production installation without a migration plan.
