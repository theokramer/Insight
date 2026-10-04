import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import Storage from "expo-sqlite/kv-store";
import * as FS from "expo-file-system/legacy";
import { currentImageUri } from "./image-location";
import { Deck, Diagram, Rating, ReviewLog, schedule } from "./model";
import { seedDecks, seedDiagrams } from "./seeds";
type State = {
  decks: Deck[];
  diagrams: Diagram[];
  reviews: ReviewLog[];
  backendUrl: string;
  hydrated: boolean;
  setHydrated: () => void;
  addDeck: (deck: Deck) => void;
  updateDeck: (id: string, title: string) => void;
  deleteDeck: (id: string) => void;
  addDiagrams: (images: Diagram[]) => void;
  updateDiagram: (id: string, changes: Partial<Diagram>) => void;
  removeDiagram: (id: string) => void;
  grade: (diagramId: string, maskId: string, rating: Rating) => void;
  setBackend: (url: string) => void;
};
export const useStore = create<State>()(
  persist(
    (set) => ({
      decks: seedDecks,
      diagrams: seedDiagrams,
      reviews: [],
      backendUrl:
        process.env.EXPO_PUBLIC_BACKEND_URL || "http://localhost:8787",
      hydrated: false,
      setHydrated: () =>
        set((s) => ({
          hydrated: true,
          diagrams: s.diagrams.map((d) => ({
            ...d,
            uri: currentImageUri(d.uri, FS.documentDirectory),
            status: d.status === "processing" ? "queued" : d.status,
          })),
        })),
      addDeck: (deck) => set((s) => ({ decks: [deck, ...s.decks] })),
      updateDeck: (id, title) =>
        set((s) => ({
          decks: s.decks.map((d) => (d.id === id ? { ...d, title } : d)),
        })),
      deleteDeck: (id) =>
        set((s) => ({
          decks: s.decks.filter((d) => d.id !== id),
          diagrams: s.diagrams.filter((d) => d.deckId !== id),
        })),
      addDiagrams: (images) =>
        set((s) => ({ diagrams: [...s.diagrams, ...images] })),
      updateDiagram: (id, changes) =>
        set((s) => ({
          diagrams: s.diagrams.map((d) =>
            d.id === id ? { ...d, ...changes } : d,
          ),
        })),
      removeDiagram: (id) =>
        set((s) => ({ diagrams: s.diagrams.filter((d) => d.id !== id) })),
      grade: (diagramId, maskId, rating) =>
        set((s) => ({
          diagrams: s.diagrams.map((d) =>
            d.id === diagramId
              ? {
                  ...d,
                  masks: d.masks.map((m) =>
                    m.id === maskId ? schedule(m, rating) : m,
                  ),
                }
              : d,
          ),
          reviews: [
            ...s.reviews.slice(-9999),
            { at: Date.now(), rating, maskId },
          ],
        })),
      setBackend: (backendUrl) => set({ backendUrl }),
    }),
    {
      name: "insight-library-v1",
      storage: createJSONStorage(() => Storage),
      partialize: ({ hydrated, ...state }) => state,
      onRehydrateStorage: () => (state) => state?.setHydrated(),
    },
  ),
);
export const dueMasks = (diagrams: Diagram[], deckId?: string) =>
  diagrams
    .filter((d) => d.status === "ready" && (!deckId || d.deckId === deckId))
    .flatMap((d) =>
      d.masks
        .filter((m) => m.due <= Date.now())
        .map((m) => ({ diagram: d, mask: m })),
    );
