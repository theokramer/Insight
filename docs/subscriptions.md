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
- iPhone campaign: `110937`; `generate_occlusions` and `upgrade_tapped` placements attached.
- Android campaign: `110938`; `generate_occlusions` placement attached.
- RevenueCat Insight project: `55ee54de` (separate from Risenote), created with weekly and yearly offering drafts.

## Pending owner sign-in and store configuration

The owner asked to finish other work first and resume Superwall after browser sign-in. The campaigns currently contain holdouts, so they do **not** present a paywall yet. Creating a blank paywall through Superwall's API failed with an internal runtime-document error, and no paywall was created. No existing Meeting Notes resource was changed.

After sign-in:

1. Build the Insight paywall in Superwall's editor, with yearly and weekly choices, store-supplied prices, clear billing periods, restore, close, terms, and privacy. Set feature gating to **gated**.
2. Create the Android yearly product (base plan `yearly`) and attach `upgrade_tapped` to the Android campaign.
3. Attach the completed paywall to a treatment audience on each platform. Confirm presentation on `generate_occlusions` and `upgrade_tapped`.
4. Create and connect actual App Store / Google Play products. The connected Apple team currently has no App Store Connect record for `de.tk.Insight`; Superwall product metadata alone does not create store subscriptions.
5. Finish RevenueCat app configuration, attach matching products to the actual Insight entitlement, and set its platform public SDK keys in the build environment.
6. Supply published legal URLs and configure the production Worker's own RevenueCat server secret and project/entitlement IDs.
7. Test purchase, cancellation, pending purchase, restore, expiration, and access rejection using sandbox store accounts.

The app registers placements only for explicit GPT creation/retry or upgrade intent. Studying and manual masks remain free. A campaign holdout or failed presentation cannot grant paid GPT access: the feature callback refreshes RevenueCat access, and the backend verifies it again.
