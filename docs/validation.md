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

In progress / not yet claimed:

- Simulator visual/gesture QA is waiting for the owner to unlock the Mac. Screens, imports, PDF page handling, mask drag/resize, light/dark appearance, larger text, offline persistence, and study completion must be exercised before release.
- Store products and purchases are not live. Superwall editor/campaign treatment setup is intentionally pending the owner's sign-in.
- Native device performance, camera capture on physical hardware, and store submission are not yet verified.
- Legacy UIKit CoreData migration is not implemented; do not ship this over an existing production installation without a migration plan.
