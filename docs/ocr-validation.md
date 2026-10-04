# Text detection verification

Verified October 3, 2026 on the rebuilt native app code.

The image fixture contains 17 study labels: small 18–24 px type, multiword terms, two separate occurrences of “Axon”, “Na+”, and sideways “Mitochondria”. A second JPEG rotates the stored pixels and uses EXIF orientation 6 to display the same diagram upright.

| Check | Result |
| --- | --- |
| Apple Vision on iPhone 17 simulator, iOS 26, upright PNG | 17/17 labels at the expected positions |
| Apple Vision on iPhone simulator, EXIF-rotated JPEG | 17/17 |
| Bundled ML Kit on Android 35 arm64 emulator, upright PNG | 17/17 |
| Bundled ML Kit on Android emulator, EXIF-rotated JPEG | 17/17 |
| Real GPT-4.1 through the deployed private Worker | 17/17 cards; heading excluded; every mask uses a measured OCR box |
| Full native app builds | iPhone simulator and Android development APK succeed |
| App / backend regression tests | 18 / 10 pass |
| TypeScript / Expo lint | Both TypeScript projects and Expo lint pass |

The independent check script matches each occurrence against its known label rectangle and requires an intersection-over-union of at least 0.40. The worst observed overlap after padding is 0.63 on iPhone and 0.65 on Android. This includes both occurrences of repeated text. Timings on the iPhone simulator were approximately 1.3 seconds for the PNG and 1.7 seconds for the EXIF JPEG; these are sample measurements, not physical-device performance guarantees. Results are saved in `ocr-report.json`.

## Improvements

- Preserve imports up to 3200 px and render PDFs up to 3000 px, retaining small text for local OCR. Upload a separate bounded 2000 px JPEG to GPT; both images share the same coordinate system.
- Apple Vision uses accurate recognition, a smaller minimum text size, language detection, and explicit EXIF normalization. Android measures against the oriented image dimensions.
- Both engines expose word geometry and confidence. Shared processing separates distant labels that were merged into a line, keeps ordinary multiword names together, removes duplicate observations, and adds 1.5–5 px padding instead of a fixed percentage of the entire image.
- GPT returns stable OCR candidate IDs. The Worker uses those measured boxes even when GPT corrects an OCR spelling error, supports compact multiline labels, and rejects duplicate cards, unknown IDs, and distant groupings.
- Native OCR failures now produce a retryable message instead of silently proceeding without measurements. Images remain saved.
- Each native engine makes one recognition pass. Extra rotation passes provided no recall benefit on the fixtures and were removed for faster batches.

OpenAI documents limitations with small text, rotation, and precise image localization. That supports using native OCR geometry and retaining editable review: [OpenAI image vision guide](https://developers.openai.com/api/docs/guides/images-vision). ML Kit provides line and element geometry and recommends sufficient character resolution: [ML Kit Android text recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android). Apple exposes the minimum text-height control: [Apple Vision text height](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/minimumtextheight).

## Repeat the checks

Run `npm test`, `npm run backend:test`, `npm run typecheck`, `npm run lint`, and `npm --prefix server run typecheck`.

The checked-in Android fixtures and expected rectangles live in `modules/insight-vision/android/src/androidTest/assets`. Build the test APK from the Expo-generated Android project:

```sh
./gradlew :insight-vision:assembleDebugAndroidTest -PinsightTestAbi=arm64-v8a -PreactNativeArchitectures=arm64-v8a
adb install -r ../modules/insight-vision/android/build/outputs/apk/androidTest/debug/insight-vision-debug-androidTest.apk
adb shell am instrument -w expo.modules.insightvision.test/expo.modules.insightvision.OCRRegression
```

The runner invokes the actual bundled recognizer and writes `files/ocr-diagram.png.json` and `files/ocr-rotated-exif.jpg.json` in its test app container. The isolated iPhone harness is `tests/native-ocr/iOSRegression.swift`; compile it with `modules/insight-vision/ios/TextDetection.swift`, and bundle both fixtures plus `expected.json`. It writes equivalent JSON reports in its Documents directory. `VisionRegression.swift` also generates the fixture and compares Apple Vision with the original settings on macOS.

Validate exported results with:

```sh
node --experimental-strip-types tests/native-ocr/check-results.ts /path/to/ios.json /path/to/ios-exif.json /path/to/android.json /path/to/android-exif.json /path/to/gpt-result.json
```

These are controlled diagram fixtures, not a benchmark of every textbook, script, or blurry photograph. The Android local recognizer remains the Latin model. Other scripts and poor-quality images need further representative testing; editable mask review remains part of the learning flow.

## App connection regression

The reported October 3 simulator failure occurred at the Insight Pro placement, before OCR or GPT. The development app had no preview token saved and its store purchase integration was not configured. The previous generic message incorrectly suggested a network failure. The app now directs an unconnected development build to Settings, checks authorized preview access before presenting a paywall, and lets verified subscribers analyze when paywall presentation is unavailable. Remote holdouts still require an active subscription. Presentation failures release the action lock and do not stack duplicate alerts for the same attempt.

A second client defect was found: RN 0.81 uses `abort-controller`, whose `AbortSignal` does not implement `timeout()`. The GPT request now creates an `AbortController`, starts a timer, and always clears it. A regression test runs with the actual native polyfill. Timeout, offline, invalid JSON, malformed result, authorization, and rate-limit responses have also been checked. HTTP statuses remain available to the queue for automatic rate-limit retries.

Unfinished imports remain visible in their collection after reopening the import screen. The diagram editor now exposes GPT analysis for an imported image, as well as retries for failed images. Secure keychain save failures are distinguished from invalid backend addresses.

Current checks: 18 app tests, 10 backend tests, both TypeScript projects, Expo lint, and iOS/Android Hermes bundle export pass. Earlier native OCR and live Worker fixture checks above remain valid; they do **not** constitute an end-to-end app GPT test. The final simulator test is pending the Mac being unlocked and approval to save the private preview token in the simulator. Real store purchases and restores remain unverified until store products and purchase-provider keys are connected.
