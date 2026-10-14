# Public legal and support URLs

Published October 4, 2026 using the existing signed-in GitHub account; no Cloudflare dashboard login was needed.

- Privacy: https://theokramer.github.io/Insight/privacy.html
- Terms: https://theokramer.github.io/Insight/terms.html
- Support: https://theokramer.github.io/Insight/support.html

GitHub Pages uses the `insight-legal-pages` branch at repository root. The initial public-pages commit is `70c98b09c99ffb1392779b307f79370addd15123`. The app's main branch was not changed by this publication. HTTPS is enforced.

App Store Connect now has the public privacy-policy URL and support URL saved for the existing app record 6503291588. This does not submit or release the app.

The iPhone Superwall paywall 275640 has published Open URL actions for Privacy and Terms, using its in-app browser. Campaign allocation remains 0%; this does not activate purchases. Android paywall 275644 has not been changed by this publishing step.

The environment example and local development environment now use these URLs. Uploaded iOS build 20261004 predates that environment change; the remotely published paywall links can update independently, but app-level environment changes require a subsequent build.

The prepared Cloudflare Worker legal routes remain available in source but have not been redeployed. A separate Sites project was registered as a fallback but is private and unpublished because its Git upload could not connect. GitHub Pages is the active public host. No images, app secrets, or private credentials were uploaded as part of the legal-page upload.

## October 14 status

The iPhone campaign is active at 100%, and current build 20261015 includes the published legal URLs. The existing Cloudflare Worker also serves its legal routes and now uses production subscription verification. The GitHub Pages privacy page was updated in commit `6d595d609245f5255f34919c9130f0ef017b0010` to disclose optional learning-focus text and card-detail settings. GitHub Pages remains the public legal host.
