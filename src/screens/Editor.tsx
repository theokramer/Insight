import React, { useState, useEffect } from "react";
import {
  ScrollView,
  View,
  Pressable,
  TextInput,
  Alert,
  useWindowDimensions,
} from "react-native";
import { usePreventRemove } from "@react-navigation/native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
} from "react-native-reanimated";
import { scheduleOnRN } from "react-native-worklets";
import { useStore } from "../store";
import { useColors } from "../theme";
import { Diagram, Mask, makeMask } from "../model";
import { DiagramImage } from "../components/DiagramCanvas";
import {
  Button,
  Txt,
  Icon,
  IconButton,
  Eyebrow,
  common,
} from "../components/UI";
import { runQueue, deleteImage } from "../services";
import { useProAction } from "../paywall";
import { AnalysisControls } from "../components/AnalysisControls";
import { analysisOptions } from "../analysis-options";
function EditableMask({
  mask,
  selected,
  w,
  h,
  onSelect,
  onUpdate,
}: {
  mask: Mask;
  selected: boolean;
  w: number;
  h: number;
  onSelect: () => void;
  onUpdate: (changes: Partial<Mask>) => void;
}) {
  const tx = useSharedValue(0),
    ty = useSharedValue(0),
    sx = useSharedValue(1),
    sy = useSharedValue(1);
  useEffect(() => {
    tx.value = 0;
    ty.value = 0;
    sx.value = 1;
    sy.value = 1;
  }, [mask.x, mask.y, mask.width, mask.height, sx, sy, tx, ty]);
  const move = Gesture.Pan()
    .enabled(selected)
    .onUpdate((e) => {
      tx.value = Math.min(
        (1 - mask.x - mask.width) * w,
        Math.max(-mask.x * w, e.translationX),
      );
      ty.value = Math.min(
        (1 - mask.y - mask.height) * h,
        Math.max(-mask.y * h, e.translationY),
      );
    })
    .onEnd(() => {
      scheduleOnRN(onUpdate, {
        x: mask.x + tx.value / w,
        y: mask.y + ty.value / h,
      });
    });
  const resize = Gesture.Pan()
    .enabled(selected)
    .onUpdate((e) => {
      sx.value = Math.max(
        0.02 / mask.width,
        Math.min(
          (1 - mask.x) / mask.width,
          1 + e.translationX / (mask.width * w),
        ),
      );
      sy.value = Math.max(
        0.02 / mask.height,
        Math.min(
          (1 - mask.y) / mask.height,
          1 + e.translationY / (mask.height * h),
        ),
      );
    })
    .onEnd(() => {
      scheduleOnRN(onUpdate, {
        width: mask.width * sx.value,
        height: mask.height * sy.value,
      });
    });
  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: tx.value },
      { translateY: ty.value },
      { scaleX: sx.value },
      { scaleY: sy.value },
    ],
  }));
  return (
    <GestureDetector gesture={move}>
      <Animated.View
        style={[
          {
            position: "absolute",
            left: mask.x * w,
            top: mask.y * h,
            width: mask.width * w,
            height: mask.height * h,
            backgroundColor: selected ? "#17634D88" : "#17634DCC",
            borderWidth: selected ? 2 : 1,
            borderColor: selected ? "#F5F8E7" : "#91B599",
            borderRadius: 4,
            transformOrigin: "left top",
          },
          style,
        ]}
      >
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`Edit mask: ${mask.label}`}
          onPress={onSelect}
          style={{ flex: 1 }}
        />
        {selected && (
          <GestureDetector gesture={resize}>
            <View
              style={{
                position: "absolute",
                right: -11,
                bottom: -11,
                width: 28,
                height: 28,
                justifyContent: "center",
                alignItems: "center",
                backgroundColor: "#FFF",
                borderWidth: 2,
                borderColor: "#17634D",
                borderRadius: 14,
              }}
            >
              <Icon name="resize-outline" size={14} color="#17634D" />
            </View>
          </GestureDetector>
        )}
      </Animated.View>
    </GestureDetector>
  );
}
function DrawCanvas({
  diagram,
  masks,
  selected,
  setSelected,
  update,
  draw,
  onDraw,
}: {
  diagram: Diagram;
  masks: Mask[];
  selected: string;
  setSelected: (id: string) => void;
  update: (id: string, c: Partial<Mask>) => void;
  draw: boolean;
  onDraw: (mask: Mask) => void;
}) {
  const { width } = useWindowDimensions();
  const w = Math.min(width - 48, 700),
    h = (w * diagram.height) / diagram.width;
  const bx = useSharedValue(0),
    by = useSharedValue(0),
    bw = useSharedValue(0),
    bh = useSharedValue(0),
    visible = useSharedValue(0);
  const commit = (x: number, y: number, width: number, height: number) => {
    if (width > 0.015 && height > 0.015)
      onDraw(makeMask("Hidden label", x, y, width, height));
  };
  const gesture = Gesture.Pan()
    .enabled(draw)
    .minDistance(2)
    .onBegin((e) => {
      bx.value = e.x;
      by.value = e.y;
      visible.value = 1;
    })
    .onUpdate((e) => {
      bw.value = e.x - bx.value;
      bh.value = e.y - by.value;
    })
    .onEnd(() => {
      const x = Math.max(0, Math.min(bx.value, bx.value + bw.value)),
        y = Math.max(0, Math.min(by.value, by.value + bh.value));
      scheduleOnRN(
        commit,
        x / w,
        y / h,
        Math.min(Math.abs(bw.value), w - x) / w,
        Math.min(Math.abs(bh.value), h - y) / h,
      );
      visible.value = 0;
      bw.value = 0;
      bh.value = 0;
    })
    .onFinalize(() => {
      visible.value = 0;
    });
  const draft = useAnimatedStyle(() => ({
    opacity: visible.value,
    left: Math.min(bx.value, bx.value + bw.value),
    top: Math.min(by.value, by.value + bh.value),
    width: Math.abs(bw.value),
    height: Math.abs(bh.value),
  }));
  return (
    <GestureDetector gesture={gesture}>
      <View
        style={{
          width: w,
          height: h,
          alignSelf: "center",
          backgroundColor: "#F5F6EE",
          borderRadius: 20,
          overflow: "hidden",
        }}
      >
        <DiagramImage diagram={diagram} />
        {masks.map((m) => (
          <EditableMask
            key={m.id}
            mask={m}
            selected={!draw && selected === m.id}
            w={w}
            h={h}
            onSelect={() => setSelected(m.id)}
            onUpdate={(changes) => update(m.id, changes)}
          />
        ))}
        <Animated.View
          pointerEvents="none"
          style={[
            {
              position: "absolute",
              borderWidth: 2,
              borderColor: "#17634D",
              backgroundColor: "#17634D55",
            },
            draft,
          ]}
        />
      </View>
    </GestureDetector>
  );
}
export function EditorScreen({ route, navigation }: any) {
  const c = useColors();
  const proAction = useProAction();
  const preferences = useStore((s) => s.analysisPreferences);
  const original = useStore((s) =>
    s.diagrams.find((d) => d.id === route.params.diagramId),
  );
  const [masks, setMasks] = useState<Mask[]>(original?.masks || []),
    [selected, setSelected] = useState(original?.masks[0]?.id || ""),
    [draw, setDraw] = useState(false),
    [dirty, setDirty] = useState(false);
  const [title, setTitle] = useState(original?.title || "");
  const [saving, setSaving] = useState(false);
  const [options, setOptions] = useState(() =>
    analysisOptions(
      useStore.getState().diagrams.find((d) => d.id === route.params.diagramId)
        ?.analysisOptions || preferences,
    ),
  );
  useEffect(() => {
    if (original && !dirty) {
      setMasks(original.masks);
      setSelected(original.masks[0]?.id || "");
      setTitle(original.title);
    }
  }, [original, dirty]);
  usePreventRemove(dirty && !saving, ({ data }) =>
    Alert.alert("Save your changes?", "Your original masks are still saved.", [
      { text: "Keep editing", style: "cancel" },
      {
        text: "Discard",
        style: "destructive",
        onPress: () => navigation.dispatch(data.action),
      },
    ]),
  );
  if (!original)
    return (
      <View style={[common.page, { gap: 20 }]}>
        <Txt style={common.title}>This diagram is unavailable.</Txt>
        <Button title="Back to library" onPress={() => navigation.popToTop()} />
      </View>
    );
  const active = masks.find((m) => m.id === selected);
  const update = (id: string, changes: Partial<Mask>) => {
    setMasks((ms) => ms.map((m) => (m.id === id ? { ...m, ...changes } : m)));
    setDirty(true);
  };
  const next = useStore
    .getState()
    .diagrams.find(
      (d) =>
        d.status === "review" &&
        d.id !== original.id &&
        d.deckId === original.deckId,
    );
  const save = () => {
    if (masks.some((m) => !m.label.trim())) {
      Alert.alert("Add an answer", "Each mask needs a label.");
      return;
    }
    setSaving(true);
    useStore.getState().updateDiagram(original.id, {
      title: title.trim() || original.title,
      masks,
      status: "ready",
      error: undefined,
    });
    setDirty(false);
    setTimeout(
      () =>
        next
          ? navigation.replace("Editor", { diagramId: next.id })
          : navigation.goBack(),
      0,
    );
  };
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      keyboardShouldPersistTaps="handled"
      automaticallyAdjustKeyboardInsets
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[common.page, { gap: 18 }]}
    >
      <View style={[common.row, { justifyContent: "space-between" }]}>
        <Eyebrow>
          {original.status === "review"
            ? "GPT PROPOSAL · YOUR FINAL CALL"
            : "MASK EDITOR"}
        </Eyebrow>
        <Txt muted style={{ fontSize: 12 }}>
          {masks.length} labels
        </Txt>
      </View>
      <TextInput
        accessibilityLabel="Diagram title"
        multiline
        maxLength={120}
        value={title}
        onChangeText={(v) => {
          setTitle(v);
          setDirty(true);
        }}
        style={{
          fontSize: 26,
          lineHeight: 32,
          fontWeight: "600",
          letterSpacing: -0.8,
          color: c.ink,
        }}
      />
      {!!original.uri && (
        <View
          style={{
            padding: 16,
            borderRadius: 16,
            backgroundColor: c.soft,
            gap: 10,
          }}
        >
          <Txt style={{ fontSize: 14 }}>
            {original.error ||
              "Choose how much to hide. GPT uses the diagram’s context to propose complete learning units."}
          </Txt>
          <AnalysisControls
            value={options}
            onChange={setOptions}
            disabled={
              original.status === "processing" || original.status === "queued"
            }
          />
          <Button
            title={
              original.status === "processing" || original.status === "queued"
                ? "Finding labels…"
                : original.masks.length
                  ? "Regenerate masks"
                  : original.status === "failed"
                    ? "Retry GPT analysis"
                    : "Find labels with GPT"
            }
            secondary
            disabled={
              dirty ||
              original.status === "processing" ||
              original.status === "queued"
            }
            onPress={() => {
              const begin = () =>
                proAction("generate_occlusions", () => {
                  useStore
                    .getState()
                    .updateDiagram(original.id, {
                      status: "queued",
                      error: undefined,
                      analysisOptions: { ...options },
                      analysisRestoreStatus:
                        original.status === "ready" ||
                        original.status === "review"
                          ? original.status
                          : undefined,
                    });
                  void runQueue();
                });
              if (original.masks.length)
                Alert.alert(
                  "Regenerate masks?",
                  "If analysis succeeds, these masks and their review progress will be replaced by new proposals. Your image stays saved.",
                  [
                    { text: "Cancel", style: "cancel" },
                    { text: "Regenerate", onPress: begin },
                  ],
                );
              else begin();
            }}
          />
          {dirty && (
            <Txt muted style={{ fontSize: 12 }}>
              Save your manual changes before retrying GPT.
            </Txt>
          )}
          {__DEV__ && (
            <Button
              title="Connect GPT"
              secondary
              onPress={() => navigation.navigate("Settings")}
            />
          )}
        </View>
      )}
      <DrawCanvas
        diagram={original}
        masks={masks}
        selected={selected}
        setSelected={setSelected}
        update={update}
        draw={draw}
        onDraw={(m) => {
          setMasks((ms) => [...ms, m]);
          setSelected(m.id);
          setDraw(false);
          setDirty(true);
        }}
      />
      <View style={[common.row, { justifyContent: "space-between" }]}>
        <Button
          title={draw ? "Done drawing" : "Draw a mask"}
          secondary
          icon={draw ? "checkmark-outline" : "add-outline"}
          onPress={() => setDraw(!draw)}
          style={{ minHeight: 48 }}
        />
        <Txt muted style={{ fontSize: 12, flex: 1, textAlign: "right" }}>
          {draw ? "Drag across a label" : "Tap a mask to edit"}
        </Txt>
      </View>
      {masks.length > 0 && (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8 }}
        >
          {masks.map((mask, i) => (
            <Pressable
              key={mask.id}
              accessibilityRole="button"
              accessibilityLabel={`Select mask ${i + 1}: ${mask.label}`}
              accessibilityState={{ selected: selected === mask.id }}
              onPress={() => {
                setSelected(mask.id);
                setDraw(false);
              }}
              style={{
                minHeight: 44,
                paddingHorizontal: 15,
                borderRadius: 14,
                justifyContent: "center",
                backgroundColor: selected === mask.id ? c.accent : c.soft,
              }}
            >
              <Txt
                style={{
                  fontSize: 13,
                  color: selected === mask.id ? c.bg : c.ink,
                }}
              >
                {i + 1} · {mask.label}
              </Txt>
            </Pressable>
          ))}
        </ScrollView>
      )}
      {active && !draw && (
        <View
          style={{
            padding: 18,
            backgroundColor: c.surface,
            borderRadius: 20,
            borderWidth: 1,
            borderColor: c.line,
            gap: 12,
          }}
        >
          <View style={[common.row, { justifyContent: "space-between" }]}>
            <Eyebrow>THE HIDDEN ANSWER</Eyebrow>
            <IconButton
              name="trash-outline"
              label="Remove selected mask"
              onPress={() => {
                setMasks((ms) => ms.filter((m) => m.id !== selected));
                setSelected("");
                setDirty(true);
              }}
              color={c.danger}
            />
          </View>
          <TextInput
            key={`${active.id}-label`}
            accessibilityLabel="Mask answer"
            defaultValue={active.label}
            onChangeText={(label) => update(active.id, { label })}
            maxLength={180}
            style={[
              common.input,
              { borderColor: c.line, color: c.ink, backgroundColor: c.bg },
            ]}
          />
          <TextInput
            key={`${active.id}-explanation`}
            accessibilityLabel="Mask explanation"
            placeholder="Add a helpful explanation"
            placeholderTextColor={c.muted}
            defaultValue={active.explanation}
            onChangeText={(explanation) => update(active.id, { explanation })}
            multiline
            style={{
              minHeight: 70,
              color: c.ink,
              fontSize: 14,
              lineHeight: 21,
            }}
          />
          <Txt muted style={{ fontSize: 12 }}>
            Drag the mask to move it. Drag its corner to resize.
          </Txt>
        </View>
      )}
      {!masks.length && (
        <Txt muted style={{ textAlign: "center" }}>
          No labels found yet. Draw a mask over a label to create your first
          card.
        </Txt>
      )}
      <Button
        title={next ? "Save & review next" : `Save ${masks.length} labels`}
        disabled={
          !masks.length ||
          original.status === "processing" ||
          original.status === "queued"
        }
        icon="checkmark-outline"
        onPress={save}
      />
      <Pressable
        accessibilityRole="button"
        onPress={() =>
          Alert.alert(
            "Delete this diagram?",
            "Its masks and review progress will be removed.",
            [
              { text: "Cancel", style: "cancel" },
              {
                text: "Delete",
                style: "destructive",
                onPress: async () => {
                  setSaving(true);
                  setDirty(false);
                  await deleteImage(original);
                  navigation.goBack();
                },
              },
            ],
          )
        }
        style={{
          minHeight: 44,
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Txt style={{ color: c.danger, fontSize: 13 }}>Delete diagram</Txt>
      </Pressable>
    </ScrollView>
  );
}
