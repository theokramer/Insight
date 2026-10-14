import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { requestAnalysis, AnalysisError } from "../src/analysis-request.ts";

test("GPT requests work with the actual React Native AbortController polyfill", async () => {
  const require = createRequire(import.meta.url);
  const native = require("abort-controller");
  assert.equal(native.AbortSignal.timeout, undefined);
  const original = globalThis.AbortController;
  globalThis.AbortController = native.AbortController;
  try {
    const fetcher: typeof fetch = async (url, init) => {
      assert.equal(url, "https://example.com/v1/occlusions");
      assert.equal(init?.method, "POST");
      assert.equal(
        (init?.headers as Record<string, string>).authorization,
        "Bearer test-preview",
      );
      assert.ok(init?.signal instanceof native.AbortSignal);
      return Response.json({ title: "Neuron", masks: [] });
    };
    const result = await requestAnalysis(
      "https://example.com",
      { authorization: "Bearer test-preview" },
      { candidates: [] },
      fetcher,
    );
    assert.equal(result.title, "Neuron");
  } finally {
    globalThis.AbortController = original;
  }
});

test("timed out requests abort and remain retryable", async () => {
  const fetcher: typeof fetch = async (_url, init) =>
    new Promise((_resolve, reject) => {
      init?.signal?.addEventListener("abort", () =>
        reject(new Error("Aborted")),
      );
    });
  await assert.rejects(
    requestAnalysis("https://example.com", {}, {}, fetcher, 5),
    /GPT took too long/,
  );
});

test("backend authorization and rate limit failures preserve their status for the queue", async () => {
  for (const status of [401, 429, 503]) {
    const fetcher: typeof fetch = async () =>
      Response.json({ error: "Retry later" }, { status });
    await assert.rejects(
      requestAnalysis("https://example.com", {}, {}, fetcher),
      (error: unknown) => {
        assert.ok(error instanceof AnalysisError);
        assert.equal(error.status, status);
        return true;
      },
    );
  }
});

test("offline, HTML error pages, and malformed results give useful retry messages", async () => {
  const offline: typeof fetch = async () => {
    throw new TypeError("Network request failed");
  };
  await assert.rejects(
    requestAnalysis("https://example.com", {}, {}, offline),
    /Check your connection and retry/,
  );
  const html: typeof fetch = async () =>
    new Response("Bad gateway", { status: 502 });
  await assert.rejects(
    requestAnalysis("https://example.com", {}, {}, html),
    /unreadable response/,
  );
  const malformed: typeof fetch = async () => Response.json({ masks: null });
  await assert.rejects(
    requestAnalysis("https://example.com", {}, {}, malformed),
    /invalid result/,
  );
});
