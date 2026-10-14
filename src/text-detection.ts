export type TextBox = {
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
  words?: Omit<TextBox, "words">[];
};
export type RawText = TextBox & { confidence?: number; words?: TextBox[] };
const valid = (b: TextBox) =>
  typeof b.label === "string" &&
  b.label.trim().length > 0 &&
  [b.x, b.y, b.width, b.height].every(Number.isFinite) &&
  b.x >= 0 &&
  b.y >= 0 &&
  b.width > 0 &&
  b.height > 0 &&
  b.x + b.width <= 1.001 &&
  b.y + b.height <= 1.001;
const key = (s: string) => s.normalize("NFKC").toLowerCase().replace(/\s/g, "");
function union(boxes: TextBox[]): TextBox {
  const x = Math.min(...boxes.map((b) => b.x)),
    y = Math.min(...boxes.map((b) => b.y));
  return {
    label: boxes.map((b) => b.label).join(" "),
    x,
    y,
    width: Math.max(...boxes.map((b) => b.x + b.width)) - x,
    height: Math.max(...boxes.map((b) => b.y + b.height)) - y,
  };
}
function overlap(a: TextBox, b: TextBox) {
  const area =
    Math.max(0, Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x)) *
    Math.max(0, Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y));
  return area / Math.min(a.width * a.height, b.width * b.height);
}

// Split distant labels that OCR merged into one line. Keep ordinary multiword names together.
export function prepareText(
  raw: RawText[],
  width: number,
  height: number,
): TextBox[] {
  const boxes: TextBox[] = [];
  for (const line of [...raw].sort(
    (a, b) => (b.confidence ?? 1) - (a.confidence ?? 1),
  )) {
    if (!valid(line)) continue;
    const words = line.words?.filter(valid) ?? [];
    const vertical = line.height * height > line.width * width;
    const groups: TextBox[][] = [[]];
    for (const word of words) {
      const group = groups[groups.length - 1];
      const previous = group[group.length - 1];
      if (previous) {
        const gap = vertical
          ? Math.max(
              word.y - (previous.y + previous.height),
              previous.y - (word.y + word.height),
            ) * height
          : Math.max(
              word.x - (previous.x + previous.width),
              previous.x - (word.x + word.width),
            ) * width;
        const glyphHeight = vertical
          ? Math.min(word.width, previous.width) * width
          : Math.min(word.height, previous.height) * height;
        if (gap > Math.max(8, glyphHeight * 1.5)) groups.push([]);
      }
      groups[groups.length - 1].push(word);
    }
    const parts =
      groups.length > 1
        ? groups.filter((g) => g.length).map((g) => ({ ...union(g), words: g }))
        : [{ ...line, words }];
    for (const b of parts) {
      if (
        boxes.some(
          (existing) =>
            key(existing.label) === key(b.label) && overlap(existing, b) > 0.65,
        )
      )
        continue;
      boxes.push({
        label: b.label.trim(),
        x: b.x,
        y: b.y,
        width: b.width,
        height: b.height,
        ...(b.words?.length
          ? {
              words: b.words.map(({ label, x, y, width, height }) => ({
                label,
                x,
                y,
                width,
                height,
              })),
            }
          : {}),
      });
    }
  }
  return boxes
    .map((b) => {
      // Pixel-based padding protects small labels without swallowing adjacent labels.
      const pixels = Math.max(
        1.5,
        Math.min(5, Math.min(b.width * width, b.height * height) * 0.15),
      );
      const px = pixels / width,
        py = pixels / height;
      const x = Math.max(0, b.x - px),
        y = Math.max(0, b.y - py);
      return {
        ...b,
        x,
        y,
        width: Math.min(1, b.x + b.width + px) - x,
        height: Math.min(1, b.y + b.height + py) - y,
      };
    })
    .sort((a, b) => a.y - b.y || a.x - b.x)
    .slice(0, 300);
}
