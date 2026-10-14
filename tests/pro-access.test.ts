import { test } from "node:test";
import assert from "node:assert/strict";
import { performProAction, type AccessIssue } from "../src/pro-access.ts";

function harness() {
  const calls: string[] = [];
  const issues: AccessIssue[] = [];
  const deps = {
    development: true,
    previewToken: async (): Promise<string | null> => null,
    initialize: async () => {
      calls.push("initialize");
    },
    purchasesConfigured: () => false,
    subscribed: async () => false,
    paywallConfigured: () => false,
    present: async (_feature: () => void) => {
      calls.push("present");
    },
    report: (issue: AccessIssue) => {
      issues.push(issue);
    },
  };
  const action = () => {
    calls.push("analyze");
  };
  return { calls, issues, deps, action };
}

test("secure development preview starts GPT without a configured paywall or store", async () => {
  const h = harness();
  h.deps.previewToken = async () => "test-preview";
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.deepEqual(h.calls, ["analyze"]);
  assert.deepEqual(h.issues, []);
});

test("missing preview and store setup gives an actionable setup issue, not a broken paywall", async () => {
  const h = harness();
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.deepEqual(h.calls, ["initialize"]);
  assert.deepEqual(h.issues, ["setup"]);
});

test("release builds never read preview credentials", async () => {
  const h = harness();
  h.deps.development = false;
  h.deps.previewToken = async () => {
    throw new Error("Must never be read");
  };
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.deepEqual(h.issues, ["setup"]);
  assert.equal(h.calls.includes("analyze"), false);
});

test("verified subscribers can analyze while paywall presentation is unavailable", async () => {
  const h = harness();
  h.deps.purchasesConfigured = () => true;
  h.deps.subscribed = async () => true;
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.deepEqual(h.calls, ["initialize", "analyze"]);
});

test("remote holdout callbacks never grant unpaid GPT access", async () => {
  const h = harness();
  h.deps.purchasesConfigured = () => true;
  h.deps.paywallConfigured = () => true;
  h.deps.present = async (feature) => {
    feature();
    feature();
  };
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.deepEqual(h.issues, ["subscription"]);
  assert.equal(h.calls.includes("analyze"), false);
});

test("a successful purchase rechecks access and runs analysis once", async () => {
  const h = harness();
  let active = false;
  h.deps.purchasesConfigured = () => true;
  h.deps.paywallConfigured = () => true;
  h.deps.subscribed = async () => active;
  h.deps.present = async (feature) => {
    active = true;
    feature();
    feature();
  };
  await performProAction("generate_occlusions", h.action, h.deps);
  assert.equal(h.calls.filter((c) => c === "analyze").length, 1);
  assert.deepEqual(h.issues, []);
});

test("keychain, verification, action, and presentation failures resolve without unhandled rejections", async () => {
  for (const stage of [
    "preview",
    "verification",
    "action",
    "paywall",
  ] as const) {
    const h = harness();
    h.deps.purchasesConfigured = () => true;
    h.deps.paywallConfigured = () => true;
    const fail = async () => {
      throw new Error("Simulated failure");
    };
    if (stage === "preview") h.deps.previewToken = fail;
    if (stage === "verification") h.deps.subscribed = fail;
    if (stage === "action") {
      h.deps.previewToken = async () => "test-preview";
      h.action = () => {
        throw new Error("Queue failed");
      };
    }
    if (stage === "paywall") h.deps.present = fail;
    await performProAction("generate_occlusions", h.action, h.deps);
    assert.deepEqual(h.issues, [stage]);
  }
});
