import { test } from "node:test";
import assert from "node:assert/strict";
import { makeMask, schedule, validBounds } from "../src/model.ts";
test("each label is scheduled independently and forgetting brings it back soon", () => {
  const a = makeMask("Axon", 0.1, 0.2, 0.2, 0.1),
    b = makeMask("Dendrite", 0.3, 0.3, 0.2, 0.1);
  const good = schedule(a, "good", 1000);
  assert.equal(good.due, 1000 + 86400000);
  assert.equal(b.due, 0);
  const again = schedule(good, "again", 2000);
  assert.equal(again.due, 62000);
  assert.equal(again.repetitions, 0);
  assert.equal(again.interval, 0);
});
test("successful recall gradually spaces reviews and difficulty stays bounded", () => {
  let m = makeMask("label", 0, 0, 0.1, 0.1);
  m = schedule(m, "good", 0);
  m = schedule(m, "good", 0);
  assert.equal(m.interval, 3);
  const good = schedule(m, "good", 0),
    easy = schedule(m, "easy", 0),
    hard = schedule(m, "hard", 0);
  assert.ok(easy.interval > good.interval);
  assert.ok(good.interval > hard.interval);
  for (let i = 0; i < 20; i++) m = schedule(m, "again", 0);
  assert.equal(m.ease, 1.3);
});
test("bad model coordinates cannot enter the editor", () => {
  assert.ok(validBounds({ x: 0.1, y: 0.2, width: 0.4, height: 0.1 }));
  assert.equal(validBounds({ x: 0.9, y: 0, width: 0.2, height: 0.1 }), false);
  assert.equal(validBounds({ x: NaN, y: 0, width: 0.2, height: 0.1 }), false);
  assert.equal(validBounds({ x: 0, y: 0, width: 0, height: 0.1 }), false);
});
