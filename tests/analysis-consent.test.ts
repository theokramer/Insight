import test from "node:test";
import assert from "node:assert/strict";
import { authorizeImageSharing } from "../src/analysis-consent.ts";
test("canceling image sharing leaves permission disabled", async () => {
  let saved = false;
  assert.equal(
    await authorizeImageSharing({
      allowed: () => false,
      ask: async () => false,
      save: () => {
        saved = true;
      },
    }),
    false,
  );
  assert.equal(saved, false);
});
test("approved sharing is remembered and withdrawing it asks again", async () => {
  let allowed = false,
    asked = 0;
  const options = {
    allowed: () => allowed,
    ask: async () => {
      asked++;
      return true;
    },
    save: () => {
      allowed = true;
    },
  };
  assert.equal(await authorizeImageSharing(options), true);
  assert.equal(await authorizeImageSharing(options), true);
  assert.equal(asked, 1);
  allowed = false;
  assert.equal(await authorizeImageSharing(options), true);
  assert.equal(asked, 2);
});
