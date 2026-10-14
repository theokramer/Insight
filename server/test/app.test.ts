import { test } from "node:test";
import assert from "node:assert/strict";
import {
  handleRequest,
  sanitize,
  analysisPrompt,
  type Env,
} from "../src/app.ts";
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

test("candidate IDs anchor corrected OCR text even when GPT guesses invalid coordinates", () => {
  const candidate = {
    id: "ocr_0",
    label: "Myelin sheatb",
    x: 0.1,
    y: 0.2,
    width: 0.15,
    height: 0.02,
  };
  const result = sanitize(
    {
      title: "Neuron",
      masks: [
        {
          label: "Myelin sheath",
          explanation: "Insulates the axon",
          candidate_ids: ["ocr_0"],
          x: -1,
          y: 2,
          width: 4,
          height: 5,
        },
      ],
    },
    [candidate],
  );
  assert.equal(result.masks.length, 1);
  assert.equal(result.masks[0].label, "Myelin sheath");
  assert.equal(result.masks[0].x, 0.1);
  assert.equal(result.masks[0].width, 0.15);
});
test("adjacent lines can form one label, distant lines and unknown IDs cannot", () => {
  const candidates = [
    { id: "ocr_0", label: "Node of", x: 0.1, y: 0.2, width: 0.1, height: 0.02 },
    {
      id: "ocr_1",
      label: "Ranvier",
      x: 0.1,
      y: 0.23,
      width: 0.09,
      height: 0.02,
    },
    { id: "ocr_2", label: "Nucleus", x: 0.8, y: 0.7, width: 0.1, height: 0.02 },
  ];
  const mask = (ids: string[]) => ({
    label: "Node of Ranvier",
    explanation: "",
    candidate_ids: ids,
    x: 0,
    y: 0,
    width: 0.5,
    height: 0.5,
  });
  const result = sanitize(
    {
      title: "Neuron",
      masks: [
        mask(["ocr_0", "ocr_2"]),
        mask(["unknown"]),
        mask(["ocr_0", "ocr_1"]),
      ],
    },
    candidates,
  );
  assert.equal(result.masks.length, 1);
  assert.ok(Math.abs(result.masks[0].height - 0.05) < 1e-8);
});
test("the same OCR candidate cannot produce duplicate cards; repeated labels keep independent boxes", () => {
  const candidates = [
    { id: "ocr_0", label: "Axon", x: 0.1, y: 0.2, width: 0.1, height: 0.02 },
    { id: "ocr_1", label: "Axon", x: 0.7, y: 0.2, width: 0.1, height: 0.02 },
  ];
  const mask = (id: string) => ({
    label: "Axon",
    explanation: "",
    candidate_ids: [id],
    x: 0,
    y: 0,
    width: 0.5,
    height: 0.5,
  });
  const result = sanitize(
    { title: "Neuron", masks: [mask("ocr_0"), mask("ocr_0"), mask("ocr_1")] },
    candidates,
  );
  assert.deepEqual(
    result.masks.map((m) => m.x),
    [0.1, 0.7],
  );
});

const proposal = (label: string, ids: string[]) => ({
  label,
  explanation: "A learning concept",
  candidate_ids: ids,
  x: 0,
  y: 0,
  width: 1,
  height: 1,
});
test("side-by-side OCR fragments can form one complete technical name", () => {
  const candidates = [
    {
      id: "ocr_0",
      label: "Posterior",
      x: 0.1,
      y: 0.2,
      width: 0.09,
      height: 0.02,
    },
    {
      id: "ocr_1",
      label: "pituitary",
      x: 0.2,
      y: 0.2,
      width: 0.08,
      height: 0.02,
    },
    { id: "ocr_2", label: "gland", x: 0.29, y: 0.2, width: 0.06, height: 0.02 },
  ];
  const result = sanitize(
    {
      title: "Endocrine system",
      masks: [
        proposal("Posterior pituitary gland", ["ocr_0", "ocr_1", "ocr_2"]),
      ],
    },
    candidates,
    { granularity: 2, focus: "Endocrinology" },
    2000,
    1000,
  );
  assert.equal(result.masks.length, 1);
  assert.equal(result.masks[0].label, "Posterior pituitary gland");
  assert.ok(Math.abs(result.masks[0].width - 0.25) < 1e-8);
});
test("whole-label mode expands an accidental word selection; word mode uses tight word geometry", () => {
  const candidates = [
    {
      id: "ocr_0",
      label: "Sodium channel",
      x: 0.1,
      y: 0.2,
      width: 0.25,
      height: 0.02,
    },
    {
      id: "ocr_0_w0",
      parentId: "ocr_0",
      label: "Sodium",
      x: 0.1,
      y: 0.2,
      width: 0.1,
      height: 0.02,
    },
    {
      id: "ocr_0_w1",
      parentId: "ocr_0",
      label: "channel",
      x: 0.22,
      y: 0.2,
      width: 0.13,
      height: 0.02,
    },
  ];
  const data = {
    title: "Neuron",
    masks: [
      proposal("Sodium", ["ocr_0_w0"]),
      proposal("channel", ["ocr_0_w1"]),
    ],
  };
  const whole = sanitize(data, candidates);
  assert.equal(whole.masks.length, 1);
  assert.equal(whole.masks[0].label, "Sodium channel");
  assert.ok(Math.abs(whole.masks[0].width - 0.25) < 1e-8);
  const words = sanitize(data, candidates, { granularity: 5, focus: "" });
  assert.equal(words.masks.length, 2);
  assert.ok(Math.abs(words.masks[0].width - 0.1) < 1e-8);
});
test("pixel aspect ratio prevents grouping distant horizontal terms on a panoramic diagram", () => {
  const candidates = [
    { id: "ocr_0", label: "Axon", x: 0.1, y: 0.2, width: 0.04, height: 0.02 },
    {
      id: "ocr_1",
      label: "Nucleus",
      x: 0.18,
      y: 0.2,
      width: 0.06,
      height: 0.02,
    },
  ];
  const result = sanitize(
    { title: "Neuron", masks: [proposal("Axon Nucleus", ["ocr_0", "ocr_1"])] },
    candidates,
    { granularity: 2, focus: "" },
    3000,
    500,
  );
  assert.equal(result.masks.length, 0);
});
test("analysis request passes bounded context and word IDs while preserving server-controlled model", async () => {
  let upstream: any;
  const response = await handleRequest(
    req({
      image: "data:image/png;base64,aGVsbG8=",
      options: { granularity: 5, focus: "Cranial nerves" },
      candidates: [
        {
          label: "Optic nerve",
          x: 0.1,
          y: 0.2,
          width: 0.2,
          height: 0.03,
          words: [
            { label: "Optic", x: 0.1, y: 0.2, width: 0.08, height: 0.03 },
            { label: "nerve", x: 0.2, y: 0.2, width: 0.1, height: 0.03 },
          ],
        },
      ],
    }),
    env,
    async (_url, init) => {
      upstream = JSON.parse(init!.body as string);
      return new Response(
        JSON.stringify({
          status: "completed",
          output: [
            {
              content: [
                {
                  type: "output_text",
                  text: JSON.stringify({
                    title: "Nerves",
                    masks: [proposal("Optic", ["ocr_0_w0"])],
                  }),
                },
              ],
            },
          ],
        }),
      );
    },
  );
  assert.equal(response.status, 200);
  assert.match(upstream.instructions, /Detail level 5\/5/);
  assert.match(upstream.input[0].content[0].text, /Cranial nerves/);
  assert.match(upstream.input[0].content[0].text, /ocr_0_w1/);
  assert.equal(upstream.model, "gpt-4.1");
  assert.ok(
    Math.abs(((await response.json()) as any).masks[0].width - 0.08) < 1e-8,
  );
  assert.match(
    analysisPrompt({ granularity: 2, focus: "" }),
    /Posterior pituitary gland/,
  );
});
