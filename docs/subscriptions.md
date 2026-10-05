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
- Prepared paywall treatments: iPhone `653342`, Android `653343`. Both have 0% traffic; the original holdout remains 100% until launch setup is complete.
- RevenueCat Insight project: `55ee54de` (separate from Risenote), created with weekly and yearly offering drafts.

## Paywall design completed

After browser sign-in, both paywalls were built and saved through the live Superwall editor. The design uses cream, forest green, a custom occluded neuron illustration, native single-choice plan cards, store-product Liquid prices, a strong purchase button, a close control, and restore. Interactive previews on both platforms verified that weekly/yearly selection changes the radio state, product index, and billing disclosure together. The compact layout fits the iPhone SE preview with legal controls visible. No existing Meeting Notes resource was changed.

Superwall's V2 duplicate endpoint returned HTTP 500 (`Failed to store snapshot`); the dashboard's own copy workflow successfully created the Android version. Paywall snapshots are published for preview, but campaign treatments are intentionally inactive. Privacy and Terms labels still need the owner's actual published URLs before they can be wired. Real purchases were not attempted.

## Remaining launch configuration

1. Supply published Privacy Policy and Terms URLs and wire their actions in each editor.
2. Create and connect actual App Store / Google Play products. The restored Schaubilder record is Apple ID `6503291588`, bundle `de.tk.Insight`, renamed Insight – Image Flashcards. Build 1.0.0 (20261004) is uploaded. Superwall product metadata alone does not create store subscriptions.
3. Finish RevenueCat app configuration, attach matching products to the actual Insight entitlement, and set its platform public SDK keys in the build environment.
4. Configure the production Worker's own RevenueCat server secret and project/entitlement IDs.
5. Test purchase, cancellation, pending purchase, restore, expiration, and access rejection using sandbox store accounts.
6. Set each campaign treatment to 100% and confirm native presentation on `generate_occlusions` and `upgrade_tapped` before release.

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
