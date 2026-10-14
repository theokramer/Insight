export type Rating = "again" | "hard" | "good" | "easy";
export type Mask = {
  id: string;
  label: string;
  explanation: string;
  x: number;
  y: number;
  width: number;
  height: number;
  due: number;
  interval: number;
  ease: number;
  repetitions: number;
};
export type Diagram = {
  id: string;
  deckId: string;
  title: string;
  uri?: string;
  svg?: string;
  width: number;
  height: number;
  masks: Mask[];
  status: "imported" | "queued" | "processing" | "review" | "ready" | "failed";
  error?: string;
  analysisOptions?: import("./analysis-options").AnalysisOptions;
  analysisRestoreStatus?: "ready" | "review";
};
export type Deck = {
  id: string;
  title: string;
  subtitle: string;
  symbol: "leaf-outline" | "flash-outline" | "pulse-outline" | "layers-outline";
  created: number;
};
export type ReviewLog = { at: number; rating: Rating; maskId: string };
export const id = () =>
  `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
export function makeMask(
  label: string,
  x: number,
  y: number,
  width: number,
  height: number,
  explanation = "",
): Mask {
  return {
    id: id(),
    label,
    explanation,
    x,
    y,
    width,
    height,
    due: 0,
    interval: 0,
    ease: 2.5,
    repetitions: 0,
  };
}
export function schedule(mask: Mask, rating: Rating, now = Date.now()): Mask {
  const day = 86400000;
  if (rating === "again")
    return {
      ...mask,
      repetitions: 0,
      interval: 0,
      ease: Math.max(1.3, mask.ease - 0.2),
      due: now + 60000,
    };
  const interval =
    rating === "hard"
      ? Math.max(1, mask.interval * 1.2)
      : rating === "easy"
        ? Math.max(4, mask.interval * mask.ease * 1.3)
        : mask.repetitions === 0
          ? 1
          : mask.repetitions === 1
            ? 3
            : Math.max(1, mask.interval * mask.ease);
  return {
    ...mask,
    repetitions: mask.repetitions + 1,
    interval,
    ease: Math.max(
      1.3,
      mask.ease + (rating === "easy" ? 0.15 : rating === "hard" ? -0.15 : 0),
    ),
    due: now + interval * day,
  };
}
export function validBounds(m: Pick<Mask, "x" | "y" | "width" | "height">) {
  return (
    [m.x, m.y, m.width, m.height].every(Number.isFinite) &&
    m.x >= 0 &&
    m.y >= 0 &&
    m.width > 0 &&
    m.height > 0 &&
    m.x + m.width <= 1.001 &&
    m.y + m.height <= 1.001
  );
}
