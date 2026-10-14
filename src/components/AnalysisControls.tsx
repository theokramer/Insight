import React from "react";
import { View, TextInput } from "react-native";
import Slider from "@react-native-community/slider";
import * as Haptics from "expo-haptics";
import { useColors } from "../theme";
import {
  AnalysisOptions,
  analysisOptions,
  DETAIL_LEVELS,
} from "../analysis-options";
import { Txt, common } from "./UI";

export function AnalysisControls({
  value,
  onChange,
  disabled = false,
}: {
  value: AnalysisOptions;
  onChange: (value: AnalysisOptions) => void;
  disabled?: boolean;
}) {
  const c = useColors();
  const normalized = analysisOptions(value);
  const level = normalized.granularity;
  const detail = DETAIL_LEVELS[level - 1];
  return (
    <View
      style={{
        backgroundColor: c.soft,
        borderRadius: 20,
        borderCurve: "continuous",
        padding: 18,
        gap: 12,
      }}
    >
      <View
        style={[
          common.row,
          { justifyContent: "space-between", flexWrap: "wrap" },
        ]}
      >
        <Txt style={{ fontSize: 17, fontWeight: "600" }}>Card detail</Txt>
        <Txt style={{ fontSize: 13, color: c.accent, fontWeight: "600" }}>
          {detail.name}
        </Txt>
      </View>
      <Slider
        accessibilityLabel="Card detail"
        accessibilityValue={{ min: 1, max: 5, now: level, text: detail.name }}
        minimumValue={1}
        maximumValue={5}
        step={1}
        value={normalized.granularity}
        disabled={disabled}
        minimumTrackTintColor={c.accent}
        maximumTrackTintColor={c.line}
        thumbTintColor={c.accent}
        style={{ width: "100%", height: 44 }}
        onValueChange={(v) => {
          onChange({ ...normalized, granularity: Math.round(v) });
        }}
        onSlidingComplete={(v) => {
          const granularity = Math.round(v);
          onChange({ ...normalized, granularity });
          void Haptics.selectionAsync();
        }}
      />
      <View style={[common.row, { justifyContent: "space-between" }]}>
        <Txt muted style={{ fontSize: 12 }}>
          Broad ideas
        </Txt>
        <Txt muted style={{ fontSize: 12 }}>
          Individual words
        </Txt>
      </View>
      <Txt muted style={{ fontSize: 13, lineHeight: 20, minHeight: 40 }}>
        {detail.description}
      </Txt>
      <Txt style={{ fontSize: 14, fontWeight: "600" }}>
        What are you learning?{" "}
        <Txt muted style={{ fontSize: 12 }}>
          (optional)
        </Txt>
      </Txt>
      <TextInput
        accessibilityLabel="Learning focus"
        defaultValue={normalized.focus}
        editable={!disabled}
        placeholder="e.g. Cranial nerves · focus on their functions"
        placeholderTextColor={c.muted}
        maxLength={240}
        multiline
        onChangeText={(focus) => onChange({ ...analysisOptions(value), focus })}
        style={[
          common.input,
          {
            color: c.ink,
            backgroundColor: c.surface,
            borderColor: c.line,
            minHeight: 72,
            textAlignVertical: "top",
            fontSize: 14,
          },
        ]}
      />
      <Txt muted style={{ fontSize: 12, lineHeight: 18 }}>
        Applies to the next analysis. Your existing cards stay as they are.
      </Txt>
    </View>
  );
}
