import { test } from "node:test";
import assert from "node:assert/strict";
import { analysisOptions } from "../src/analysis-options.ts";

test("existing libraries default to whole-label analysis; settings are bounded", () => {
  assert.deepEqual(analysisOptions(), { granularity: 2, focus: "" });
  assert.equal(analysisOptions({ granularity: Infinity }).granularity, 2);
  assert.equal(analysisOptions({ granularity: 999 }).granularity, 5);
  assert.equal(analysisOptions({ granularity: -1 }).granularity, 1);
  assert.equal(analysisOptions({ granularity: 3.6 }).granularity, 4);
  assert.equal(analysisOptions({ focus: " anatomy " }).focus, "anatomy");
  assert.equal(analysisOptions({ focus: "x".repeat(500) }).focus.length, 240);
});
