import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const env = process.env;
const app = JSON.parse(
  readFileSync(new URL("../app.json", import.meta.url)),
).expo;
assert.equal(
  app.ios.bundleIdentifier,
  "de.tk.Insight",
  "Use the existing Insight App Store record.",
);
assert.match(
  app.ios.buildNumber,
  /^\d+$/,
  "Set an increasing iOS build number.",
);
assert.match(
  env.EXPO_PUBLIC_REVENUECAT_IOS_KEY || "",
  /^appl_[A-Za-z0-9]+$/,
  "A real RevenueCat App Store public key is required.",
);
assert.match(
  env.EXPO_PUBLIC_SUPERWALL_IOS_KEY || "",
  /^pk_[A-Za-z0-9_-]+$/,
  "The iPhone Superwall public key is required.",
);
for (const name of [
  "EXPO_PUBLIC_BACKEND_URL",
  "EXPO_PUBLIC_PRIVACY_URL",
  "EXPO_PUBLIC_TERMS_URL",
]) {
  const url = new URL(env[name] || "");
  assert.equal(url.protocol, "https:", `${name} must use HTTPS.`);
  assert.ok(
    !url.username && !url.password && !url.search && !url.hash,
    `${name} must not contain credentials or tokens.`,
  );
  assert.ok(
    !["localhost", "127.0.0.1"].includes(url.hostname),
    `${name} must use the deployed service.`,
  );
}
for (const [name, value] of Object.entries(env)) {
  if (name.startsWith("EXPO_PUBLIC_")) {
    assert.ok(
      !/^(sk[-_]|test_)/.test(value || ""),
      `${name} contains a secret or Test Store credential.`,
    );
  }
}
console.log(
  "iPhone release configuration passed. Native checkout, restore, GPT access, and App Store submission still require verification.",
);
