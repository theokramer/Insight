export type LabelBox = {
  id?: string;
  parentId?: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
};

// Validate adjacency in image pixels: normalized x/y have different scales on a non-square image.
// GPT decides semantic membership; geometry only prevents a mask spanning unrelated/distant text.
export function compactLabel(
  boxes: LabelBox[],
  imageWidth = 1,
  imageHeight = 1,
) {
  if (!boxes.length || boxes.length > 16) return false;
  const scaled = boxes.map((b) => ({
    x: b.x * imageWidth,
    y: b.y * imageHeight,
    w: b.width * imageWidth,
    h: b.height * imageHeight,
  }));
  const connected = (
    a: (typeof scaled)[number],
    b: (typeof scaled)[number],
  ) => {
    const xOverlap = Math.max(
      0,
      Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x),
    );
    const yOverlap = Math.max(
      0,
      Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y),
    );
    const xGap = Math.max(0, a.x - b.x - b.w, b.x - a.x - a.w);
    const yGap = Math.max(0, a.y - b.y - b.h, b.y - a.y - a.h);
    const sameRow =
      yOverlap >= Math.min(a.h, b.h) * 0.5 && xGap <= Math.max(a.h, b.h) * 2.25;
    const nextLine =
      xOverlap >= Math.min(a.w, b.w) * 0.25 && yGap <= Math.max(a.h, b.h) * 0.9;
    const rotatedWords =
      a.h > a.w * 2 &&
      b.h > b.w * 2 &&
      xOverlap >= Math.min(a.w, b.w) * 0.5 &&
      yGap <= Math.max(a.w, b.w) * 2.25;
    return sameRow || nextLine || rotatedWords;
  };
  const visited = new Set([0]);
  const queue = [0];
  while (queue.length) {
    const index = queue.shift()!;
    scaled.forEach((box, next) => {
      if (!visited.has(next) && connected(scaled[index], box)) {
        visited.add(next);
        queue.push(next);
      }
    });
  }
  return visited.size === boxes.length;
}
