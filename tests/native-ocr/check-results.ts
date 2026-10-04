import { readFileSync } from "node:fs";
import assert from "node:assert/strict";
import { prepareText, type TextBox } from "../../src/text-detection.ts";
const expected: TextBox[] = JSON.parse(
  readFileSync(
    new URL(
      "../../modules/insight-vision/android/src/androidTest/assets/expected.json",
      import.meta.url,
    ),
    "utf8",
  ),
);
const key = (value: string) =>
  value.normalize("NFKC").toLowerCase().replace(/\s/g, "");
function overlap(a: TextBox, b: TextBox) {
  const width = Math.max(
    0,
    Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x),
  );
  const height = Math.max(
    0,
    Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y),
  );
  const intersection = width * height;
  return (
    intersection / (a.width * a.height + b.width * b.height - intersection)
  );
}
const reports = process.argv.slice(2).map((path) => {
  const result = JSON.parse(readFileSync(path, "utf8"));
  const boxes: TextBox[] =
    result.masks ?? prepareText(result.detected, 2000, 1500);
  const scores = expected.map((label) =>
    Math.max(
      0,
      ...boxes
        .filter((box) => key(box.label) === key(label.label))
        .map((box) => overlap(label, box)),
    ),
  );
  const missing = expected
    .filter((_, index) => scores[index] < 0.4)
    .map((label) => label.label);
  assert.deepEqual(missing, [], `${path}: missing or misplaced labels`);
  if (result.masks)
    assert.equal(
      boxes.length,
      expected.length,
      "GPT must exclude headings and duplicate proposals",
    );
  return {
    path,
    matched: expected.length,
    expected: expected.length,
    minimumBoxOverlap: Math.min(...scores),
    ...(result.seconds ? { seconds: result.seconds } : {}),
  };
});
console.log(JSON.stringify(reports, null, 2));
