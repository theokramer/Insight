import React, { useState } from "react";
import {
  View,
  ScrollView,
  Pressable,
  Alert,
  ActivityIndicator,
} from "react-native";
import { useStore } from "../store";
import { useColors } from "../theme";
import { Button, Txt, Icon, Eyebrow, common, Section } from "../components/UI";
import { pickPhotos, pickFiles, runQueue } from "../services";
import { useProAction } from "../paywall";
import { DiagramImage } from "../components/DiagramCanvas";
import { AnalysisControls } from "../components/AnalysisControls";
import { useAnalysisPreferences } from "../use-analysis-preferences";
export function ImportScreen({ route, navigation }: any) {
  const c = useColors();
  const proAction = useProAction();
  const preferences = useAnalysisPreferences();
  const decks = useStore((s) => s.decks),
    diagrams = useStore((s) => s.diagrams);
  const [deckId, setDeck] = useState(route.params?.deckId || decks[0]?.id);
  const [busy, setBusy] = useState(false);
  const [batch, setBatch] = useState<string[]>(() =>
    diagrams.filter((d) => d.status !== "ready").map((d) => d.id),
  );
  // Unfinished images remain reachable after navigating away or restarting.
  const images = diagrams.filter(
    (d) =>
      d.deckId === deckId && (d.status !== "ready" || batch.includes(d.id)),
  );
  const ready = images.filter(
    (d) => d.status === "review" || d.status === "ready",
  ).length;
  const working = images.some(
    (d) => d.status === "queued" || d.status === "processing",
  );
  const pick = async (source: "photos" | "camera" | "files") => {
    if (!deckId) {
      navigation.navigate("NewDeck");
      return;
    }
    setBusy(true);
    try {
      const onImport = (d: { id: string }) => setBatch((b) => [...b, d.id]);
      const picked =
        source === "files"
          ? await pickFiles(deckId, onImport)
          : await pickPhotos(deckId, source === "camera", onImport);
      if (picked.errors.length)
        Alert.alert(
          "Some images couldn’t be imported",
          `${picked.diagrams.length} images saved.\n${picked.errors.slice(0, 3).join("\n")}`,
        );
    } catch (e) {
      Alert.alert(
        "Couldn’t import",
        e instanceof Error ? e.message : "Try again.",
      );
    } finally {
      setBusy(false);
    }
  };
  return (
    <ScrollView
      keyboardShouldPersistTaps="handled"
      automaticallyAdjustKeyboardInsets
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[common.page, { gap: 18 }]}
    >
      <Eyebrow>FROM PICTURE TO PRACTICE</Eyebrow>
      <Txt style={common.title}>Bring the whole chapter.</Txt>
      <Txt muted>
        Choose many images at once. GPT finds the labels; you make the final
        call.
      </Txt>
      <View
        style={{
          padding: 20,
          backgroundColor: c.soft,
          borderRadius: 24,
          gap: 15,
        }}
      >
        <View style={common.row}>
          <View
            style={{
              height: 46,
              width: 46,
              borderRadius: 14,
              backgroundColor: c.surface,
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Icon name="scan-outline" color={c.accent} />
          </View>
          <View style={{ flex: 1 }}>
            <Txt style={{ fontWeight: "600" }}>
              Your diagrams, intelligently masked
            </Txt>
            <Txt muted style={{ fontSize: 12 }}>
              Editable cards from your diagrams
            </Txt>
          </View>
        </View>
        <Txt muted style={{ fontSize: 13, lineHeight: 20 }}>
          Images stay on your device. Images you choose to analyze are sent
          through Insight to OpenAI. Proposed masks are reviewed before
          studying.
        </Txt>
      </View>
      <Section title="Add to collection" />
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ gap: 8 }}
      >
        {decks.map((d) => (
          <Pressable
            accessibilityRole="radio"
            accessibilityState={{ selected: d.id === deckId }}
            key={d.id}
            onPress={() => setDeck(d.id)}
            style={{
              paddingHorizontal: 15,
              paddingVertical: 12,
              borderRadius: 14,
              backgroundColor: d.id === deckId ? c.accent : c.surface,
              borderWidth: 1,
              borderColor: c.line,
            }}
          >
            <Txt
              style={{
                color: d.id === deckId ? c.bg : c.ink,
                fontSize: 13,
                fontWeight: "600",
              }}
            >
              {d.title}
            </Txt>
          </Pressable>
        ))}
        <Pressable
          onPress={() => navigation.navigate("NewDeck")}
          style={{ padding: 12 }}
          accessibilityLabel="New collection"
        >
          <Icon name="add" />
        </Pressable>
      </ScrollView>
      <Button
        title="Choose photos"
        icon="images-outline"
        loading={busy}
        onPress={() => pick("photos")}
      />
      <View style={common.row}>
        <Button
          title="Take a photo"
          secondary
          icon="camera-outline"
          disabled={busy}
          style={{ flex: 1, paddingHorizontal: 8 }}
          onPress={() => pick("camera")}
        />
        <Button
          title="Files & PDFs"
          secondary
          icon="document-outline"
          disabled={busy}
          style={{ flex: 1, paddingHorizontal: 8 }}
          onPress={() => pick("files")}
        />
      </View>
      <Txt muted style={{ fontSize: 12, textAlign: "center" }}>
        Up to 50 photos or PDF pages per import
      </Txt>
      {images.length > 0 && (
        <View style={{ gap: 12 }}>
          <Section
            title="Your batch"
            action={`${ready}/${images.length} analyzed`}
          />
          {images.some(
            (d) => d.status === "imported" || d.status === "failed",
          ) && (
            <View style={{ gap: 14 }}>
              <AnalysisControls
                value={preferences.options}
                onChange={preferences.change}
                disabled={working}
              />
              <Button
                title="Find labels with GPT"
                icon="scan-outline"
                onPress={() =>
                  proAction("generate_occlusions", () => {
                    preferences.commit();
                    for (const d of images.filter(
                      (d) => d.status === "imported" || d.status === "failed",
                    ))
                      useStore.getState().updateDiagram(d.id, {
                        status: "queued",
                        error: undefined,
                        analysisOptions: { ...preferences.options },
                      });
                    void runQueue();
                  })
                }
              />
            </View>
          )}
          {working && (
            <View style={common.row}>
              <ActivityIndicator color={c.accent} />
              <Txt muted style={{ fontSize: 13 }}>
                Finding the important details…
              </Txt>
            </View>
          )}
          {images.map((d) => (
            <Pressable
              key={d.id}
              onPress={() => navigation.navigate("Editor", { diagramId: d.id })}
              style={{
                padding: 12,
                backgroundColor: c.surface,
                borderRadius: 17,
                flexDirection: "row",
                gap: 12,
                alignItems: "center",
              }}
            >
              <View
                style={{
                  height: 58,
                  width: 58,
                  borderRadius: 10,
                  overflow: "hidden",
                }}
              >
                <DiagramImage diagram={d} />
              </View>
              <View style={{ flex: 1, gap: 3 }}>
                <Txt
                  numberOfLines={1}
                  style={{ fontSize: 14, fontWeight: "600" }}
                >
                  {d.title}
                </Txt>
                <Txt muted style={{ fontSize: 12 }}>
                  {d.status === "review"
                    ? `${d.masks.length} labels · Tap to review`
                    : d.status === "ready"
                      ? "Ready to study"
                      : d.status === "failed"
                        ? d.error
                        : d.status === "processing"
                          ? "Analyzing…"
                          : d.status === "imported"
                            ? "Ready to analyze · or draw masks manually"
                            : d.error || "Queued"}
                </Txt>
              </View>
              <Icon
                name={
                  d.status === "ready"
                    ? "checkmark-circle-outline"
                    : "chevron-forward"
                }
                color={c.accent}
              />
            </Pressable>
          ))}
          {ready > 0 && (
            <Button
              title={
                images.some((d) => d.status === "review")
                  ? "Review proposed masks"
                  : "Study this collection"
              }
              onPress={() => {
                const proposal = images.find((d) => d.status === "review");
                if (proposal)
                  navigation.navigate("Editor", { diagramId: proposal.id });
                else navigation.navigate("Study", { deckId });
              }}
            />
          )}
        </View>
      )}
      <Pressable
        accessibilityRole="button"
        onPress={() => navigation.navigate("Privacy")}
        style={{ minHeight: 44, justifyContent: "center" }}
      >
        <Txt muted style={{ fontSize: 13, textAlign: "center" }}>
          Privacy & your images →
        </Txt>
      </Pressable>
    </ScrollView>
  );
}
