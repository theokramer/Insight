import { useCallback, useEffect, useRef, useState } from "react";
import { analysisOptions, type AnalysisOptions } from "./analysis-options";
import { useStore } from "./store";

// Keep typing local rather than serializing a large library for each keystroke.
export function useAnalysisPreferences() {
  const saved = useStore((s) => s.analysisPreferences);
  const [draft, setDraft] = useState(saved);
  const pending = useRef<AnalysisOptions | undefined>(undefined);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const commit = useCallback(() => {
    clearTimeout(timer.current);
    if (!pending.current) return;
    const value = pending.current;
    pending.current = undefined;
    useStore.getState().setAnalysisPreferences(value);
  }, []);
  useEffect(() => {
    if (!pending.current) setDraft(saved);
  }, [saved]);
  useEffect(() => () => commit(), [commit]);
  const change = useCallback(
    (value: AnalysisOptions) => {
      const next = analysisOptions(value);
      setDraft(next);
      pending.current = next;
      clearTimeout(timer.current);
      timer.current = setTimeout(commit, 350);
    },
    [commit],
  );
  return { options: draft, change, commit };
}
