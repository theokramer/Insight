export type AnalysisOptions = { granularity: number; focus: string };
export const DEFAULT_ANALYSIS: AnalysisOptions = { granularity: 2, focus: "" };
export const DETAIL_LEVELS = [
  {
    name: "Key ideas",
    description:
      "Fewer cards for the main ideas. Keep complete names and phrases together.",
  },
  {
    name: "Whole labels",
    description: "One complete label per card. Multiword names stay together.",
  },
  {
    name: "Concepts",
    description:
      "Split longer annotations into distinct concepts, keeping technical names intact.",
  },
  {
    name: "Fine detail",
    description:
      "Include smaller structures, terms, and supporting details as separate cards.",
  },
  {
    name: "Individual words",
    description:
      "Make separate cards for meaningful words and abbreviations. Skip filler words.",
  },
] as const;
export function analysisOptions(
  value?: Partial<AnalysisOptions> | null,
): AnalysisOptions {
  return {
    granularity:
      typeof value?.granularity === "number" &&
      Number.isFinite(value.granularity)
        ? Math.max(1, Math.min(5, Math.round(value.granularity)))
        : DEFAULT_ANALYSIS.granularity,
    focus:
      typeof value?.focus === "string" ? value.focus.trim().slice(0, 240) : "",
  };
}
