import { test } from "node:test";
import assert from "node:assert/strict";
import { prepareText, type TextBox } from "../src/text-detection.ts";
const box = (label: string, x: number, y = 0.2, width = 0.06): TextBox => ({
  label,
  x,
  y,
  width,
  height: 0.01,
});
test("distant labels split, but multiword technical names stay together", () => {
  const words = [box("Myelin", 0.1), box("sheath", 0.165), box("Nucleus", 0.6)];
  const output = prepareText(
    [
      {
        label: "Myelin sheath Nucleus",
        x: 0.1,
        y: 0.2,
        width: 0.56,
        height: 0.01,
        words,
      },
    ],
    2000,
    2000,
  );
  assert.deepEqual(
    output.map((b) => b.label),
    ["Myelin sheath", "Nucleus"],
  );
  assert.ok(output[0].x + output[0].width < 0.25);
});
test("rotation duplicates disappear while repeated labels at different positions survive", () => {
  const output = prepareText(
    [
      { ...box("Axon", 0.1), confidence: 1 },
      { ...box("AXON", 0.1001), confidence: 0.8 },
      box("Axon", 0.7),
    ],
    2000,
    1500,
  );
  assert.equal(output.length, 2);
  assert.ok(output[0].x < 0.2);
  assert.ok(output[1].x > 0.6);
});
test("small labels get pixel padding, invalid geometry is removed, edge boxes stay inside image", () => {
  const output = prepareText(
    [box("Na+", 0.1), box("bad", NaN), box("edge", 0, 0, 0.02)],
    3200,
    2400,
  );
  assert.equal(output.length, 2);
  assert.ok(
    output.every(
      (b) => b.x >= 0 && b.y >= 0 && b.x + b.width <= 1 && b.y + b.height <= 1,
    ),
  );
  const sodium = output.find((b) => b.label === "Na+")!;
  assert.ok((0.1 - sodium.x) * 3200 < 5);
  assert.ok((0.2 - sodium.y) * 2400 < 5);
});
test("sideways distant words split along the vertical axis", () => {
  const output = prepareText(
    [
      {
        label: "Axon Nucleus",
        x: 0.1,
        y: 0.1,
        width: 0.02,
        height: 0.7,
        words: [
          { label: "Axon", x: 0.1, y: 0.1, width: 0.02, height: 0.1 },
          { label: "Nucleus", x: 0.1, y: 0.6, width: 0.02, height: 0.15 },
        ],
      },
    ],
    2000,
    1500,
  );
  assert.equal(output.length, 2);
});
