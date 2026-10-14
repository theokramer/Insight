import { test } from "node:test";
import assert from "node:assert/strict";
import { backendAddress } from "../src/backend-address.ts";

test("release upgrades ignore persisted development backend addresses", () => {
  assert.equal(
    backendAddress(
      false,
      "https://production.example/",
      "http://localhost:8787",
    ),
    "https://production.example",
  );
  assert.equal(
    backendAddress(
      false,
      "https://production.example",
      "https://untrusted.example",
    ),
    "https://production.example",
  );
});
test("release requests fail closed without a secure configured destination", () => {
  for (const address of [
    undefined,
    "http://localhost:8787",
    "https://user:pass@example.com",
    "https://example.com?token=private",
  ]) {
    assert.throws(() =>
      backendAddress(false, address, "https://persisted.example"),
    );
  }
});
test("development can use a local endpoint, but rejects malformed or credentialed URLs", () => {
  assert.equal(backendAddress(true, undefined), "http://localhost:8787");
  assert.equal(
    backendAddress(
      true,
      "https://production.example",
      "http://192.168.1.2:8787/",
    ),
    "http://192.168.1.2:8787",
  );
  for (const address of [
    "http://public.example",
    "https://user:pass@example.com",
    "https://example.com#secret",
  ]) {
    assert.throws(() => backendAddress(true, undefined, address));
  }
});
