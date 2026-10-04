import { test } from "node:test";
import assert from "node:assert/strict";
import { handleRequest, sanitize, type Env } from "../src/app.ts";
const env: Env = {
  OPENAI_API_KEY: "server-only",
  PRIVATE_ACCESS_TOKEN: "private-test",
  ACCESS_MODE: "private",
  RATE_LIMITER: { limit: async () => ({ success: true }) },
};
const req = (
  body: object = { image: "data:image/png;base64,aGVsbG8=" },
  authorized = true,
) =>
  new Request("https://insight.test/v1/occlusions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(authorized ? { authorization: "Bearer private-test" } : {}),
    },
    body: JSON.stringify(body),
  });
test("selected labels use measured OCR boxes, including repeated labels", () => {
  const result = sanitize(
    {
      title: "Diagram",
      masks: [
        {
          label: " AXON ",
          explanation: "Carries impulses",
          x: 0.6,
          y: 0.6,
          width: 0.1,
          height: 0.1,
        },
      ],
    },
    [
      { label: "Axon", x: 0.1, y: 0.1, width: 0.15, height: 0.04 },
      { label: "Axon", x: 0.61, y: 0.62, width: 0.18, height: 0.05 },
    ],
  );
  assert.equal(result.masks[0].x, 0.61);
  assert.equal(result.masks[0].width, 0.18);
  assert.equal(result.masks[0].explanation, "Carries impulses");
});
test("unauthenticated requests never call OpenAI", async () => {
  let calls = 0;
  const res = await handleRequest(req({}, false), env, async () => {
    calls++;
    throw Error();
  });
  assert.equal(res.status, 401);
  assert.equal(calls, 0);
});
test("rate limiting fails closed and limits the shared private budget", async () => {
  assert.equal(
    (await handleRequest(req(), { ...env, RATE_LIMITER: undefined })).status,
    503,
  );
  assert.equal(
    (
      await handleRequest(req(), {
        ...env,
        RATE_LIMITER: {
          limit: async ({ key }) => {
            assert.equal(key, "private");
            return { success: false };
          },
        },
      })
    ).status,
    429,
  );
});
test("caller parameters cannot change model or inject tools", async () => {
  let called = false;
  const res = await handleRequest(
    req({
      image: "data:image/png;base64,aGVsbG8=",
      model: "expensive-model",
      tools: [{ type: "web_search" }],
      max_output_tokens: 999999,
    }),
    env,
    async (url, init) => {
      called = true;
      assert.equal(url, "https://api.openai.com/v1/responses");
      const body = JSON.parse(init!.body as string);
      assert.equal(body.model, "gpt-4.1");
      assert.equal(body.max_output_tokens, 8000);
      assert.equal(body.store, false);
      assert.equal(body.tools, undefined);
      assert.equal((init!.headers as any).authorization, "Bearer server-only");
      return new Response(
        JSON.stringify({
          status: "completed",
          output: [
            {
              content: [
                {
                  type: "output_text",
                  text: JSON.stringify({
                    title: "Neuron",
                    masks: [
                      {
                        label: "Axon",
                        explanation: "Carries impulses",
                        x: 0.1,
                        y: 0.2,
                        width: 0.2,
                        height: 0.1,
                      },
                    ],
                  }),
                },
              ],
            },
          ],
        }),
      );
    },
  );
  assert.ok(called);
  assert.equal(res.status, 200);
  assert.equal(((await res.json()) as any).masks.length, 1);
});
test("invalid images and truncated GPT outputs remain retryable", async () => {
  assert.equal(
    (await handleRequest(req({ image: "https://attacker.test" }), env)).status,
    400,
  );
  const res = await handleRequest(
    req(),
    env,
    async () => new Response(JSON.stringify({ status: "incomplete" })),
  );
  assert.equal(res.status, 502);
});
test("sanitizer drops out-of-image and non-finite masks", () => {
  const result = sanitize({
    title: "test",
    masks: [
      { label: "ok", explanation: "", x: 0, y: 0, width: 0.2, height: 0.1 },
      {
        label: "bad",
        explanation: "",
        x: 0.9,
        y: 0.9,
        width: 0.2,
        height: 0.2,
      },
      { label: "nan", explanation: "", x: NaN, y: 0, width: 0.1, height: 0.1 },
    ],
  });
  assert.equal(result.masks.length, 1);
});
test("Risenote-style subscriptions require a real active Insight entitlement", async () => {
  const revenueEnv: Env = {
    ...env,
    ACCESS_MODE: "revenuecat",
    REVENUECAT_SECRET_KEY: "rc-secret",
    REVENUECAT_PROJECT_ID: "insight-project",
    ENTITLEMENT_ID: "insight_pro,entlInsight",
  };
  const request = new Request("https://insight.test/v1/occlusions", {
    method: "POST",
    headers: { "x-app-user-id": "user123" },
    body: JSON.stringify({ image: "data:image/png;base64,aGVsbG8=" }),
  });
  const denied = await handleRequest(
    request,
    revenueEnv,
    async () =>
      new Response(
        JSON.stringify({ items: [{ entitlement_id: "risenote_pro" }] }),
      ),
  );
  assert.equal(denied.status, 401);
  const response = await handleRequest(
    new Request(request.url, {
      method: "POST",
      headers: { "x-app-user-id": "user123" },
      body: JSON.stringify({ image: "data:image/png;base64,aGVsbG8=" }),
    }),
    revenueEnv,
    async (url) => {
      if (String(url).includes("revenuecat.com"))
        return new Response(
          JSON.stringify({ items: [{ entitlement_id: "entlInsight" }] }),
        );
      return new Response(
        JSON.stringify({
          status: "completed",
          output: [
            {
              content: [
                {
                  type: "output_text",
                  text: JSON.stringify({ title: "Test", masks: [] }),
                },
              ],
            },
          ],
        }),
      );
    },
  );
  assert.equal(response.status, 200);
});
