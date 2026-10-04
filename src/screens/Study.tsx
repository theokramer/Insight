import React, { useState, useEffect, useRef, useCallback } from "react";
import { View, ScrollView, Pressable } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import { useStore, dueMasks } from "../store";
import { useColors } from "../theme";
import { MaskedDiagram, ZoomCanvas } from "../components/DiagramCanvas";
import {
  Button,
  Txt,
  Icon,
  IconButton,
  Eyebrow,
  common,
} from "../components/UI";
import { Rating, schedule } from "../model";
export function StudyScreen({ route, navigation }: any) {
  const c = useColors(),
    insets = useSafeAreaInsets();
  const [queue] = useState(() =>
    dueMasks(useStore.getState().diagrams, route.params?.deckId).slice(0, 20),
  );
  const [index, setIndex] = useState(0),
    [revealed, setRevealed] = useState(false);
  const lock = useRef(false);
  const [remembered, setRemembered] = useState(0);
  const item = queue[index];
  const complete = useCallback(
    () => navigation.replace("Complete", { count: queue.length, remembered }),
    [navigation, queue.length, remembered],
  );
  useEffect(() => {
    if (!item) complete();
  }, [item, complete]);
  if (!item) return <View style={{ flex: 1, backgroundColor: c.bg }} />;
  const grade = (rating: Rating) => {
    if (lock.current || !revealed) return;
    lock.current = true;
    Haptics.selectionAsync();
    useStore.getState().grade(item.diagram.id, item.mask.id, rating);
    const count = remembered + (rating === "again" ? 0 : 1);
    setRemembered(count);
    if (index + 1 === queue.length) {
      navigation.replace("Complete", {
        count: queue.length,
        remembered: count,
      });
    } else {
      setRevealed(false);
      setIndex(index + 1);
      setTimeout(() => (lock.current = false), 150);
    }
  };
  const interval = (rating: Rating) => {
    const next = schedule(item.mask, rating);
    return rating === "again"
      ? "1 min"
      : `${Math.round(next.interval)} ${Math.round(next.interval) === 1 ? "day" : "days"}`;
  };
  return (
    <View
      style={{
        flex: 1,
        backgroundColor: c.bg,
        paddingTop: insets.top + 10,
        paddingBottom: insets.bottom + 12,
      }}
    >
      <View style={[common.row, { paddingHorizontal: 20, gap: 16 }]}>
        <IconButton
          name="close"
          label="End study session"
          onPress={() => navigation.goBack()}
        />
        <View
          accessibilityRole="progressbar"
          accessibilityValue={{ min: 0, max: queue.length, now: index }}
          style={{
            flex: 1,
            height: 5,
            backgroundColor: c.line,
            borderRadius: 3,
          }}
        >
          <View
            style={{
              height: 5,
              width: `${(index / queue.length) * 100}%`,
              backgroundColor: c.accent,
              borderRadius: 3,
            }}
          />
        </View>
        <Txt muted style={{ fontSize: 13, fontVariant: ["tabular-nums"] }}>
          {index + 1} / {queue.length}
        </Txt>
      </View>
      <ScrollView
        contentContainerStyle={{
          paddingHorizontal: 24,
          paddingTop: 27,
          paddingBottom: 25,
          gap: 18,
        }}
      >
        <Eyebrow>
          {useStore
            .getState()
            .decks.find((d) => d.id === item.diagram.deckId)
            ?.title.toUpperCase()}
        </Eyebrow>
        <Txt
          style={{
            fontSize: 29,
            lineHeight: 35,
            fontWeight: "600",
            letterSpacing: -1,
          }}
        >
          {revealed ? "There it is." : "What’s behind the mask?"}
        </Txt>
        <Txt muted style={{ fontSize: 14 }}>
          {item.diagram.title}
        </Txt>
        <View key={`${item.mask.id}-canvas`} style={{ marginTop: 10 }}>
          <ZoomCanvas>
            <MaskedDiagram
              diagram={item.diagram}
              activeMask={item.mask}
              revealed={revealed}
            />
          </ZoomCanvas>
        </View>
        <View style={[common.row, { justifyContent: "center", gap: 6 }]}>
          <Icon name="expand-outline" size={14} color={c.muted} />
          <Txt muted style={{ fontSize: 11 }}>
            Pinch to explore · Double-tap to zoom
          </Txt>
        </View>
        {revealed ? (
          <View
            style={{
              backgroundColor: c.soft,
              borderRadius: 21,
              padding: 20,
              gap: 7,
            }}
          >
            <Eyebrow>THE ANSWER</Eyebrow>
            <Txt
              selectable
              style={{ fontSize: 24, fontWeight: "600", letterSpacing: -0.6 }}
            >
              {item.mask.label}
            </Txt>
            {!!item.mask.explanation && (
              <Txt selectable muted style={{ fontSize: 14, lineHeight: 22 }}>
                {item.mask.explanation}
              </Txt>
            )}
          </View>
        ) : (
          <Txt
            muted
            style={{ textAlign: "center", fontSize: 14, paddingVertical: 15 }}
          >
            Take a breath. Try to recall it first.
          </Txt>
        )}
      </ScrollView>
      <View style={{ paddingHorizontal: 24, gap: 12 }}>
        {revealed ? (
          <>
            <Txt muted style={{ textAlign: "center", fontSize: 12 }}>
              How well did you remember?
            </Txt>
            <View style={{ flexDirection: "row", gap: 7 }}>
              {(["again", "hard", "good", "easy"] as Rating[]).map((r) => (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={`${r}, review in ${interval(r)}`}
                  key={r}
                  onPress={() => grade(r)}
                  style={({ pressed }) => ({
                    flex: 1,
                    minHeight: 70,
                    borderRadius: 17,
                    backgroundColor: r === "good" ? c.accent : c.soft,
                    alignItems: "center",
                    justifyContent: "center",
                    gap: 3,
                    opacity: pressed ? 0.7 : 1,
                  })}
                >
                  <Txt
                    style={{
                      fontSize: 14,
                      fontWeight: "600",
                      color: r === "good" ? c.bg : c.ink,
                    }}
                  >
                    {r[0].toUpperCase() + r.slice(1)}
                  </Txt>
                  <Txt
                    style={{
                      fontSize: 10,
                      color: r === "good" ? c.bg : c.muted,
                      lineHeight: 16,
                    }}
                  >
                    {interval(r)}
                  </Txt>
                </Pressable>
              ))}
            </View>
          </>
        ) : (
          <Button
            title="Reveal answer"
            icon="eye-outline"
            onPress={() => {
              setRevealed(true);
              Haptics.selectionAsync();
            }}
          />
        )}
      </View>
    </View>
  );
}
export function CompleteScreen({ route, navigation }: any) {
  const c = useColors(),
    insets = useSafeAreaInsets();
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={{
        flexGrow: 1,
        justifyContent: "center",
        padding: 32,
        paddingTop: insets.top + 32,
        gap: 22,
      }}
    >
      <View
        style={{
          alignSelf: "center",
          width: 106,
          height: 106,
          borderRadius: 53,
          backgroundColor: c.soft,
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Icon name="checkmark" size={48} color={c.accent} />
      </View>
      <Eyebrow>A LITTLE CLEARER THAN BEFORE</Eyebrow>
      <Txt style={[common.title, { fontSize: 39, lineHeight: 46 }]}>
        That’s how{"\n"}knowledge grows.
      </Txt>
      <Txt muted>
        You reviewed {route.params.count} labels and recalled{" "}
        {route.params.remembered}. Your next reviews are scheduled.
      </Txt>
      <View
        style={{
          padding: 20,
          borderWidth: 1,
          borderColor: c.line,
          borderRadius: 22,
          gap: 7,
        }}
      >
        <Txt style={{ fontWeight: "600" }}>Leave a little space.</Txt>
        <Txt muted style={{ fontSize: 14 }}>
          Coming back later helps this picture become something you really know.
        </Txt>
      </View>
      <Button title="Back to today" onPress={() => navigation.popToTop()} />
    </ScrollView>
  );
}
