# Insight subscription setup

Superwall presents the paywall. RevenueCat performs purchases and restores and supplies the active Insight entitlement. The Cloudflare Worker checks that entitlement independently before calling OpenAI. This matches Meeting Notes' ownership of each layer.

## Created resources

- Superwall organization: AI Voice Notes, ID `13515`.
- Insight project: `42562`.
- iPhone app: `57183`, bundle `de.tk.Insight`.
- Android app: `57184`, package `de.tk.insight`.
- Insight entitlements: iPhone `60947`, Android `60948`; both `insight_pro`.
- iPhone weekly product: `680688`, identifier `de.tk.Insight.pro.weekly`, USD 7.99/week.
- iPhone yearly product: `680689`, identifier `de.tk.Insight.pro.yearly`, USD 34.99/year.
- Android weekly product: `680690`, identifier `insight_pro:weekly:sw-none`, USD 7.99/week. The Play product is `insight_pro`, base plan `weekly`, with no offer.
- Android yearly product: `680694`, identifier `insight_pro:yearly:sw-none`, USD 34.99/year, base plan `yearly`, with no offer.
- iPhone paywall: `275640`, **Insight Pro — See it. Know it.**
- Android paywall: `275644`, the same design with Play products.
- iPhone campaign: `110937`; `generate_occlusions` and `upgrade_tapped` placements attached.
- Android campaign: `110938`; both placements attached.
- Prepared paywall treatments: iPhone `653342`, Android `653343`. The iPhone treatment has 100% traffic and its holdout 0%; Android remains inactive with its original holdout.
- RevenueCat Insight project: `55ee54de` (separate from Risenote), created with weekly and yearly offering drafts.

## Paywall design completed

After browser sign-in, both paywalls were built and saved through the live Superwall editor. The design uses cream, forest green, a custom occluded neuron illustration, native single-choice plan cards, store-product Liquid prices, a strong purchase button, a close control, and restore. Interactive previews on both platforms verified that weekly/yearly selection changes the radio state, product index, and billing disclosure together. The compact layout fits the iPhone SE preview with legal controls visible. No existing Meeting Notes resource was changed.

Superwall's V2 duplicate endpoint returned HTTP 500 (`Failed to store snapshot`); the dashboard's own copy workflow successfully created the Android version. Both paywall snapshots are published. The iPhone treatment is active at 100%; Android remains inactive. The iPhone Privacy and Terms actions are now published; the Android actions still need wiring. Real purchases remain unverified.

## Current iPhone release configuration — October 14, 2026

- RevenueCat App Store app `app7b28d373d7` uses valid existing Apple purchase and App Store Connect credentials. Its public iOS SDK key is saved in the ignored build environment.
- Apple subscriptions `6819157820` (weekly) and `6819158930` (yearly), in group `22441435`, use USD 7.99/week and 34.99/year with localized prices. Both are level 1, have review screenshots, and report `READY_TO_SUBMIT`.
- RevenueCat products `prod3b61d23839` and `prodacf08b7ed2` grant `insight_pro` (REST ID `entl7a5dfe0ff9`) and are attached to the default offering's weekly/yearly packages. Simulated Test Store products no longer grant production Pro access.
- The iPhone paywall's Privacy and Terms actions use the published GitHub Pages URLs. Treatment `653342` receives 100%; holdout `653315` receives 0%.
- The existing `insight-preview.meeting-notes-tk.workers.dev` Worker now runs production RevenueCat verification with a read-only customer credential. It rejects unpaid requests and ignores the old private preview token.
- App Store privacy disclosures are published. Build 20261014 is uploaded, valid, attached to the manual-release draft, and available in the existing internal TestFlight group. The owner confirmed successful purchase and GPT label creation. Native restore with no subscription correctly reports no active access; a successful paid restore and expiration still need verification. Build 20261015 adds the requested granularity controls and must replace the current candidate before App Review submission.
- Android store setup and legal-action wiring remain pending; this release pass targets the existing iPhone listing.

The editable iPhone design snapshot is in `paywall-design.json`; `paywall-preview.jpg` shows the Android editor's standard phone rendering. Live editor links:

- https://superwall.com/editor/#/applications/57183/paywalls/275640/latest
- https://superwall.com/editor/#/applications/57184/paywalls/275644/latest

The app registers placements only for explicit GPT creation/retry or upgrade intent. Studying and manual masks remain free. A campaign holdout or failed presentation cannot grant paid GPT access: the feature callback refreshes RevenueCat access, and the backend verifies it again.

## October 4 iPhone paywall update

The iPhone paywall 275640 was edited and published through the Superwall dashboard. The editor relay could not be reached from this execution environment, so native dashboard controls were used. The existing Android paywall was not changed in this pass.

- New headline: “Turn pictures into lasting knowledge.”
- Clearer batch-creation and explanation benefits; benefit text 15px and prices 20px.
- New primary action: “Unlock Insight Pro,” 18px, retaining the existing purchase behavior.
- Root spacing distributes the available vertical space on taller phones, with compact minimum gaps. Safe-area-aware top and bottom padding protects controls near notches and home indicators.
- The complete iPhone SE preview fits plan cards, the purchase button, renewal copy, and footer labels. Weekly and yearly radio choices were both verified to update the corresponding billed amount and period. No store transaction was attempted.
- Publish confirmation reported the existing campaign allocation as 0%; campaign traffic was not activated. Store purchases still need launch configuration. The iPhone Privacy and Terms actions were subsequently published using GitHub Pages URLs; see legal-hosting.md.

`paywall-design.json` is the earlier structural snapshot. The current dashboard preview screenshot is saved beside the source deliverables as `Insight-paywall-improved.png`.

## October 14 native paywall verification

The current published iPhone paywall was verified in a fresh release installation with store prices USD 34.99/year and 7.99/week. The header uses safe-area CSS variables with a spacing fallback for older SDK webviews; the CTA stays on one line. Both subscription review screenshots now show the current native paywall. The App Store download price is free; Pro remains a paid subscription.
