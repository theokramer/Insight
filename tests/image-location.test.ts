import { test } from "node:test";
import assert from "node:assert/strict";
import { currentImageUri } from "../src/image-location.ts";

test("saved images follow the current app container after iOS rebuilds", () => {
  const old = "file:///old-container/Documents/diagrams/mut6psey-cc4axh8n.jpg";
  const directory = "file:///current-container/Documents/";
  const actual = currentImageUri(old, directory);
  assert.equal(actual, `${directory}diagrams/mut6psey-cc4axh8n.jpg`);
  assert.equal(currentImageUri(actual, directory), actual);
});

test("external sources, missing images, and paths outside the managed image folder remain unchanged", () => {
  const directory = "file:///current/Documents/";
  for (const uri of [
    undefined,
    "https://example.com/diagrams/abc.jpg",
    "file:///picker/photo.jpg",
    "file:///old/diagrams/../other.jpg",
  ]) {
    assert.equal(currentImageUri(uri, directory), uri);
  }
  assert.equal(
    currentImageUri("file:///old/diagrams/abc.jpg", null),
    "file:///old/diagrams/abc.jpg",
  );
});
