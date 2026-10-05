import test from "node:test";
import assert from "node:assert/strict";
import { handleRequest } from "../src/app.ts";
test("public legal pages work without AI credentials and leave analysis protected", async () => {
  const env = {
    OPENAI_API_KEY: "",
    PRIVATE_ACCESS_TOKEN: "private-test-token",
    ACCESS_MODE: "private" as const,
  };
  const neverFetch: typeof fetch = async () => {
    throw new Error("Legal pages must not call external services");
  };
  for (const path of ["/privacy", "/terms", "/support"]) {
    const response = await handleRequest(
      new Request(`https://insight.test${path}`),
      env,
      neverFetch,
    );
    assert.equal(response.status, 200);
    assert.match(response.headers.get("content-type") || "", /text\/html/);
    const html = await response.text();
    assert.match(html, /theo\.kramer\.bus@gmail\.com/);
    assert.equal(html.includes("private-test-token"), false);
    const head = await handleRequest(
      new Request(`https://insight.test${path}`, { method: "HEAD" }),
      env,
      neverFetch,
    );
    assert.equal(await head.text(), "");
  }
  const denied = await handleRequest(
    new Request("https://insight.test/v1/occlusions", { method: "POST" }),
    env,
    neverFetch,
  );
  assert.equal(denied.status, 401);
});
