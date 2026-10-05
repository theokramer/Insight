# Insight

A native iPhone and Android app for learning complicated diagrams through image occlusion. Import a chapter, let GPT propose label masks, adjust the results, and practice one hidden label at a time.

## What is built

- Warm cream and forest green interface, automatic dark mode, native navigation, haptic feedback, and large phone controls.
- Batch photo import, camera capture, images from Files, and native PDF rendering. Up to 50 images/pages per import; successful imports survive unreadable files.
- Local Apple Vision / Android ML Kit text detection, followed by GPT label selection and short explanations. Matching labels use measured OCR boxes rather than estimated positions.
- Move, resize, draw, remove, and rename masks; review the next proposed image with one action.
- Offline library and per-label spaced repetition, reveal-before-rating study sessions, pinch and double-tap zoom, and real review history.
- Cloudflare Worker keeps the OpenAI key on the server and verifies Insight subscriptions using the same proxy pattern as Meeting Notes.
- Custom Superwall paywalls are saved for iPhone and Android, with RevenueCat handling store purchases, restores, and entitlement verification. Plan selection and billing copy are verified in editor previews. Campaign activation, legal URLs, and store product configuration remain pending.

This is a complete replacement of the original UIKit project. The original iPhone bundle identifier is preserved (`de.tk.Insight`); Android uses `de.tk.insight`.

## Run locally

Requires Node 22+, Xcode for iPhone, and Java 17 plus Android SDK for Android. Use a native development build; Expo Go does not include the vision or Superwall modules.

```sh
npm ci
cp .env.example .env.local
npx expo run:ios
# or
npx expo run:android
```

The source uses Expo SDK 54, React Native 0.81, and Expo Router. SDK 54 was chosen to compile with this machine's installed Xcode 26.0. Generated native projects live in `ios/` and `android/` and are excluded from Git. Configure changes through `app.json`, config plugins, and the local `modules/insight-vision` module.

For this Mac's Android shell, use the already installed runtime:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/Users/theokramer/Library/Android/sdk
npx expo run:android
```

The supplied Android development APK needs Metro running: `npx expo start --dev-client --lan`, then connect the installed app to that development server.

`eas.json` includes native development, internal preview, and production build profiles. iOS 1.0.0 (20261004) is uploaded to the restored Schaubilder App Store Connect record, Apple ID 6503291588, and shows Ready to Submit in TestFlight. Store checkout setup and App Review submission remain pending; Android store submission is not yet performed.

## GPT backend

```sh
npm --prefix server ci
cp server/.dev.vars.example server/.dev.vars
# Set server-only secrets in that ignored file.
npm run backend:dev
```

The protected development Worker is deployed at `https://insight-preview.meeting-notes-tk.workers.dev`. Its OpenAI key and private preview token are encrypted Worker secrets. Development Settings accepts the preview token into the device's secure storage; the token is never a public build variable. Production builds ignore this token and require a verified subscription.

Production configuration is in `server/wrangler.jsonc`. Set `REVENUECAT_PROJECT_ID`, the actual RevenueCat entitlement ID, and the server-only `REVENUECAT_SECRET_KEY` before deploying production. The Worker verifies this project's active entitlement, bounds request size and model output, accepts only image input, rejects caller-selected models/tools, and applies a distributed rate limit. The app automatically pauses and resumes on rate-limit responses.

Imported images are stored locally at up to 3,200 pixels; images sent for analysis are resized to at most 2,000 pixels. Only explicitly analyzed images and detected text positions are sent through the Worker to OpenAI. Responses use `store: false`; OpenAI's applicable API retention still applies. There is no cloud library sync in this version. The original UIKit CoreData library is not automatically migrated; an existing-user migration needs to be added before replacing a previously installed legacy release.

## Subscription configuration

See [docs/subscriptions.md](docs/subscriptions.md) for the created project identifiers and remaining live setup. The approved plans are **USD 7.99 weekly** and **USD 34.99 yearly**, with no invented free trial. Prices on the live paywall must come from actual store products.

## Checks

```sh
npm run lint
npm run typecheck
npm test
npm run backend:test
npm --prefix server run typecheck
npx expo export --platform ios --platform android
```

See [docs/validation.md](docs/validation.md) for tested behavior and remaining device QA. Learning tests cover independent label scheduling and malformed geometry. Worker tests cover authorization, Insight-only entitlement checks, rate limiting, request restrictions, incomplete model output, and measured OCR alignment.
